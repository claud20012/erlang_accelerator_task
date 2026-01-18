-module(matrix_handler).
-behaviour(cowboy_rest).  

%% Cowboy REST callbacks
-export([init/2, allowed_methods/2, content_types_provided/2, content_types_accepted/2]).

-export([
    get_matrix_data/2,
    post_matrix_data/2,
    get_greatest_product/2
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
    %% If a diagonal-length binding exists, delegate to the calculate handler
        case cowboy_req:binding('diagonal-length', Req0) of
        undefined -> ok;
        _ ->
            %% Delegate to specific calculator
            get_greatest_product(Req0, State)
    end,

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


%% Calculate the greatest product of N adjacent numbers in any direction
get_greatest_product(Req0, State) ->
    %% extract id and diagonal-length
    RawId = cowboy_req:binding(id, Req0),
    Id = case RawId of
        undefined -> <<>>;
        B when is_binary(B) -> (catch binary_to_integer(B));
        OtherId -> list_to_binary(io_lib:format("~p", [OtherId]))
    end,

    %% parse diagonal-length (must be integer)
    DiagonalLength =
        case cowboy_req:binding('diagonal-length', Req0) of
            undefined ->
                Req2 = cowboy_req:reply(400, #{<<"content-type">> => <<"text/plain">>}, <<"missing diagonal-length">>, Req0),
                {stop, Req2, State};
            Bin when is_binary(Bin) ->
                case (catch binary_to_integer(Bin)) of
                    {'EXIT', _} ->
                        Req2 = cowboy_req:reply(400, #{<<"content-type">> => <<"text/plain">>}, <<"invalid diagonal-length">>, Req0),
                        {stop, Req2, State};
                    Int when is_integer(Int), Int > 0 -> Int;
                    _ ->
                        Req2 = cowboy_req:reply(400, #{<<"content-type">> => <<"text/plain">>}, <<"invalid diagonal-length">>, Req0),
                        {stop, Req2, State}
                end;
            _ ->
                Req2 = cowboy_req:reply(400, #{<<"content-type">> => <<"text/plain">>}, <<"invalid diagonal-length">>, Req0),
                {stop, Req2, State}
        end,

    %% If we returned early with {stop,...} propagate it
    case DiagonalLength of
        {stop, _} = Stop -> Stop;
        N when is_integer(N) ->
            %% fetch matrix rows
            case eatq_db:get_matrix_data(Id) of
                {ok, _Cols, Rows} when is_list(Rows), Rows =/= [] ->
                    %% Build a lookup map {R,C} => Value
                    CellMap = maps:from_list([ {{R,C}, V} || {_, R, C, V} <- Rows ]),
                    Rs = [ R || {_, R, _, _} <- Rows ],
                    Cs = [ C || {_, _, C, _} <- Rows ],
                    MaxR = lists:max(Rs),
                    MaxC = lists:max(Cs),

                    Dirs = [{0,1}, {1,0}, {1,1}, {1,-1}],

                    %% scan all starting positions within observed bounds
                    ScanStarts = [{R,C} || R <- lists:seq(0, MaxR), C <- lists:seq(0, MaxC)],

                    Best = lists:foldl(fun({R,C}, Acc) ->
                                lists:foldl(fun({DR,DC}, Acc2) ->
                                    PosList = [ {R + K*DR, C + K*DC} || K <- lists:seq(0, N-1) ],
                                    Values = [ maps:get(P, CellMap, undefined) || P <- PosList ],
                                    case lists:any(fun(X) -> X =:= undefined end, Values) of
                                        true -> Acc2;
                                        false ->
                                            Prod = lists:foldl(fun(X,A) -> X * A end, 1, Values),
                                            case Acc2 of
                                                {none} -> {prod, Prod, {R,C}, {DR,DC}, Values};
                                                {prod, BestP, _SPos, _SDir, _SVals} when Prod > BestP -> {prod, Prod, {R,C}, {DR,DC}, Values};
                                                _ -> Acc2
                                            end
                                    end
                                end, Acc, Dirs)
                            end, {none}, ScanStarts),

                    Result = case Best of
                        {prod, P, {SR,SC}, {DR,DC}, Vals} ->
                            #{ <<"matrix_id">> => Id, <<"length">> => N, <<"greatest_product">> => P,
                               <<"start">> => #{<<"row">> => SR, <<"col">> => SC}, <<"direction">> => [DR, DC], <<"values">> => Vals };
                        _ -> #{ <<"matrix_id">> => Id, <<"length">> => N, <<"greatest_product">> => null }
                    end,

                    Body = jsx:encode(Result),
                    {Body, Req0, State};

                {ok, _Cols, []} ->
                    _Req2 = cowboy_req:reply(404, #{<<"content-type">> => <<"text/plain">>}, <<"matrix not found">>, Req0),
                    {stop, _Req2, State};

                {error, _} ->
                    {stop, Req0, State}
            end;
        _ ->
            _Req2 = cowboy_req:reply(400, #{<<"content-type">> => <<"text/plain">>}, <<"invalid diagonal-length">>, Req0),
            {stop, _Req2, State}
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

                            %% Persist Flat into the DB using helper in eatq_db.
                            io:format("matrix_handler: received matrix ~p with ~p cells~n", [MatrixId, length(Flat)]),
                            io:format("cells: ~p~n", [Flat]),

                            case eatq_db:save_matrix(MatrixId, Flat) of
                                {ok, Count} ->
                                    io:format("matrix_handler: saved ~p cells~n", [Count]),
                                    %% Respond success. Returning 'true' tells cowboy_rest the POST succeeded.
                                    {true, Req1, State};

                                {error, Reason} ->
                                    io:format("matrix_handler: db error: ~p~n", [Reason]),
                                    Req2 = cowboy_req:reply(500, #{<<"content-type">> => <<"text/plain">>}, <<"db error">>, Req1),
                                    {stop, Req2, State}
                            end;

                        false ->
                            Req2 = cowboy_req:reply(400, #{<<"content-type">> => <<"text/plain">>}, <<"invalid data rows">>, Req1),
                            {stop, Req2, State}
                    end
            end;

        _Other ->
            Req2 = cowboy_req:reply(400, #{<<"content-type">> => <<"text/plain">>}, <<"invalid body">>, Req1),
            {stop, Req2, State}
    end.