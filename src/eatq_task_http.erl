-module(eatq_task_http).
-behaviour(eatq_task).

%% Use this module to call the endpoints defined in tasks.
%% You can use either httpc or hackney.
%% However, the suggested approach is to use hackney, as it is easier to use.

-export([
    execute/1
]).

%% API

execute(_TaskPayload) ->
    ok.
