-module(eatq_task).

-export([
    execute/1
]).

%% behaviour callbacks

-callback execute(TaskPayload :: #{}) -> ok | {error, term()}.

%% API

-spec execute(Task :: #{}) -> ok | {error, term()}.
execute(Task) ->
    TaskType = maps:get(<<"type">>, Task),
    Module = select_module(TaskType),
    TaskPayload = maps:get(<<"payload">>, Task),
    Module:execute(TaskPayload).

%% internal

select_module(<<"http">>) ->
    eatq_task_http.
