-module(eatq_http_handler).
-behaviour(cowboy_handler).

%% Use this module to define the HTTP API handlers

-export([
    init/2,
    add_test_endpoint/0
]).

init(Req, State) ->
    Req = cowboy_req:reply(200,
        #{<<"content-type">> => <<"text/plain">>},
        <<"Hello Erlang!">>,
    Req),
    {ok, Req, State}.

add_test_endpoint() ->
    cowboy_router:compile([
        {'_', [
            {"/test", eatq_http_handler, []}
        ]}
    ]).
