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

            %% Encode the list of maps
            Body = jsx:encode(MatrixMap),
            {Body, Req0, State};

        {error, _Reason} ->
            {stop, Req0, State}
    end.

%% POST implementation
post_matrix_data(Req0, State) ->
    %% Read the body (up to 8MB by default)
    {ok, _Body, Req1} = cowboy_req:read_body(Req0),
    
    %% In a real app, you'd process the Body here.
    %% Returning 'true' tells Cowboy the resource was created/updated successfully (204 No Content or 200 OK)
    {true, Req1, State}.