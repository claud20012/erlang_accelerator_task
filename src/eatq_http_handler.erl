-module(eatq_http_handler).
-behaviour(cowboy_handler).

%% Use this module to define the HTTP API handlers

-export([
    init/2,
    start_routes/0
]).

init(Req, State) ->
    Req = cowboy_req:reply(200,
        #{<<"content-type">> => <<"text/plain">>},
        <<"Hello Erlang!">>,
    Req),
    {ok, Req, State}.

start_routes() ->
    cowboy_router:compile([
        {'_', [
            {"/test", eatq_http_handler, []},
            {"/matrix/product/:id/:diagonal-length", matrix_handler, []},
            {"/matrix/:id", matrix_handler, []},
            {"/matrix", matrix_handler, []}
        ]}
    ]).
