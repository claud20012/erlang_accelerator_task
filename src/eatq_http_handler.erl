-module(eatq_http_handler).
-behaviour(cowboy_handler).

%% Use this module to define the HTTP API handlers

-export([
    init/2
]).

init(Req, State) ->
    {ok, Req, State}.
