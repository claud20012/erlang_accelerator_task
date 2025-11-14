-module(eatq_scheduler).
-behaviour(gen_server).

%% How it should work? Each task have the triggered_at field.
%% When the triggered_at is equal to the current time
%% the task should be given to a worker for execution.
%%
%% I suggest using ETS here to learn more about it.
%% For example, you can use `ordered_set` instead of `set` to iterate over records in order
%%
%% Don't forget to update status of task in DB.

-export([
    start_link/0,
    enqueue/1
]).

-export([
    init/1,
    handle_continue/2,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2
]).

%% API

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% Use trigger_at to order tasks
enqueue(_Task) ->
    ok.

%% gen_server callbacks

init([]) ->
    {ok, #{}}.

handle_continue(_Req, State) ->
    {noreply, State}.

handle_call(_Req, _From, State) ->
    {reply, ok, State}.

handle_cast(_Req, State) ->
    {noreply, State}.

handle_info(_Req, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.
