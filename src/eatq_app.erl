-module(eatq_app).
-behaviour(application).

-export([start/2, stop/1]).

%% application callbacks

start(_StartType, _StartArgs) ->
    %% Start cowboy (listener + router) here
    eatq_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
