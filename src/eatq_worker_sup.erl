-module(eatq_worker_sup).
-behaviour(supervisor).

-export([
    start_link/0
]).

-export([
    init/1
]).

%% API

start_link() ->
    supervisor:start_link().

%% supervisor callbacks

init([]) ->
    %% Suggested child list and order: Poolboy Worker Manager
    %% The manager should use eatq_worker as worker
    ok.
