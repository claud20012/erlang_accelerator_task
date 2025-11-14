-module(eatq_worker).
-behaviour(gen_server).

%% Use this module to execute a task

-export([
    start_link/0,
    execute/1
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
    ok.

execute(_Task) ->
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
