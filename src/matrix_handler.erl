-module(matrix_handler).
-behaviour(cowboy_rest).  

%% Cowboy REST callbacks
-export([init/2, allowed_methods/2, content_types_provided/2, content_types_accepted/2]).

-export([
    get_matrix_data/2,
    post_matrix_data/2
]).

init(Req, State) ->
    {cowboy_rest, Req, State}.

%% 1. Define which HTTP methods are allowed
allowed_methods(Req, State) ->
    {[<<"GET">>, <<"POST">>, <<"OPTIONS">>], Req, State}.

%% 2. For GET requests: map content-type to a function
content_types_provided(Req, State) ->
    {[
        {<<"application/json">>, get_matrix_data},
        {<<"text/plain">>, get_matrix_data},
        {<<"*/*">>, get_matrix_data}
    ], Req, State}.

%% 3. For POST requests: map content-type to a function
content_types_accepted(Req, State) ->
    {[
        {<<"application/json">>, post_matrix_data},
        {<<"application/x-www-form-urlencoded">>, post_matrix_data}
    ], Req, State}.

%% GET implementation
get_matrix_data(Req0, State) ->
    %% Extract the :id from the URL
    RawId = cowboy_req:binding(id, Req0),
    Id = case RawId of
        undefined -> <<>>;
        B when is_binary(B) -> binary_to_integer(B);
        Other -> list_to_binary(io_lib:format("~p", [Other]))
    end,

    io:format("~p: Getting matrix data for ID: ~n~n", [Id]),

    MatrixData = eatq_db:get_matrix_data(Id),

    case MatrixData of
            {ok, _Columns, Rows} ->
            %% Transform tuples into Maps
            MatrixMap = lists:map(fun({MatrixId, Row, Col, Val}) ->
                #{
                    <<"matrix_id">> => MatrixId,
                    <<"row_index">> => Row,
                    <<"col_index">> => Col,
                    <<"value">>     => Val
                }
            end, Rows),

            Envelope = #{ <<"matrix_data">> => MatrixMap },

            %% Encode the list of maps
            Body = jsx:encode(Envelope),
            {Body, Req0, State};

        {error, _Reason} ->
            {stop, Req0, State}
    end.

%% POST implementation
post_matrix_data(Req0, State) ->
    %% Read the body (up to 8MB by default)
    %% read the following
    {ok, Body, Req1} = cowboy_req:read_body(Req0),

    %% Try to decode JSON body into maps (jsx option return_maps makes objects into maps)
    %% Decode JSON safely
    Decoded =
        try jsx:decode(Body, [return_maps]) of
            Json -> {ok, Json}
        catch
            _:_ -> {error, invalid_json}
        end,

    case Decoded of
        {error, invalid_json} ->
            %% Invalid JSON -> respond 400
            Req2 = cowboy_req:reply(400,
                    #{<<"content-type">> => <<"text/plain">>},
                    <<"invalid json">>,
                Req1),
            {stop, Req2, State};

        {ok, JsonMap} when is_map(JsonMap) ->
            %% Expected shape:
            %% {"matrix_id": <int>, "data": [[..],[..],..]}
            MatrixId = maps:get(<<"matrix_id">>, JsonMap, undefined),
            Data = maps:get(<<"data">>, JsonMap, undefined),

            case {MatrixId, Data} of
                {undefined, _} ->
                    Req2 = cowboy_req:reply(400, #{<<"content-type">> => <<"text/plain">>}, <<"missing matrix_id">>, Req1),
                    {stop, Req2, State};

                {_, undefined} ->
                    Req2 = cowboy_req:reply(400, #{<<"content-type">> => <<"text/plain">>}, <<"missing data">>, Req1),
                    {stop, Req2, State};

                {_Id, Rows} when is_list(Rows) ->
                    %% Basic validation of rows: ensure each row is a list of numbers
                    Valid = lists:all(fun(R) -> is_list(R) andalso lists:all(fun(E) -> is_integer(E) orelse is_float(E) end, R) end, Rows),
                    case Valid of
                        true ->
                            %% Transform into a flat list of {MatrixId, RowIndex, ColIndex, Value} tuples
                            Pairs = lists:zip(Rows, lists:seq(0, length(Rows) - 1)),
                            Flat = lists:foldl(fun({Row, RIdx}, Acc) ->
                                        ColPairs = lists:zip(Row, lists:seq(0, length(Row) - 1)),
                                        RowTuples = [ {MatrixId, RIdx, CIdx, Val} || {Val, CIdx} <- ColPairs ],
                                        Acc ++ RowTuples
                                    end, [], Pairs),

                            %% At this point you can persist Flat into the DB using eatq_db_connection or a helper in eatq_db.
                            io:format("matrix_handler: received matrix ~p with ~p cells~n", [MatrixId, length(Flat)]),
                            io:format("cells: ~p~n", [Flat]),

                            %% Respond success. Returning 'true' tells cowboy_rest the POST succeeded.
                            {true, Req1, State};

                        false ->
                            Req2 = cowboy_req:reply(400, #{<<"content-type">> => <<"text/plain">>}, <<"invalid data rows">>, Req1),
                            {stop, Req2, State}
                    end
            end;

        _Other ->
            Req2 = cowboy_req:reply(400, #{<<"content-type">> => <<"text/plain">>}, <<"invalid body">>, Req1),
            {stop, Req2, State}
    end.