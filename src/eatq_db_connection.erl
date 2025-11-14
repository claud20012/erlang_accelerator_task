-module(eatq_db_connection).
-behaviour(gen_server).

%% Connect to DB via epgsql
%% Use this module to store the epgsql connection context and send requests to PostgreSQL

-export([
    start_link/0,
    query/2,
    query/1
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

query(_Sql, _Params) ->
    ok.

query(_Sql) ->
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
