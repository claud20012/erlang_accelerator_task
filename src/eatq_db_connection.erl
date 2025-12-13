-module(eatq_db_connection).
-behaviour(gen_server).
%% -include_lib("epgsql/include/epgsql.hrl").

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

%% --- Defines ---
-define(SERVER, ?MODULE).
-define(DEFAULT_HOST, "localhost").
-define(DEFAULT_PORT, 5432).
-define(DB_USER, "iulian.marcu"). 
-define(DB_NAME, "erlproject"). 
%% The connection context stored in the state.
-record(state, {
    conn_pid :: pid() | undefined
}).
%% API

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

query(Sql, Params) ->
    gen_server:call(?SERVER, {query, Sql, Params}, infinity).

query(Sql) ->
    gen_server:call(?SERVER, {query, Sql}, infinity).

%% gen_server callbacks

init([]) ->
    
    % 1. Define Connection Options
    ConnectOpts = #{
        host => ?DEFAULT_HOST,
        port => ?DEFAULT_PORT,
        username => ?DB_USER,
        database => ?DB_NAME,
        timeout => 5000 
    },
    
    io:format("~p: Attempting initial database connection...~n", [?MODULE]),

    % 2. Attempt Connection
    case epgsql:connect(ConnectOpts) of
        {ok, ConnPid} ->
            io:format("~p: Connection established. PID: ~p~n", [?MODULE, ConnPid]),
            {ok, #state{conn_pid = ConnPid}};
        {error, Reason} ->
            io:format(standard_error, "~p: Failed to connect to DB: ~p~n", [?MODULE, Reason]),
            % If connection fails, the server should typically crash or try again later.
            % Here we crash for simplicity, letting a supervisor handle restart.
            {stop, {db_connection_failed, Reason}}
    end.

handle_continue(_Req, State) ->
    {noreply, State}.

%% @private
%% handle_call: Synchronous request for database query.
handle_call({query, Sql, Params}, _From, State = #state{conn_pid = ConnPid}) ->
    % Use epgsql:prepared_query for synchronous execution
    Result = epgsql:prepared_query(ConnPid, Sql, Params),
    
    % io:format("~p: Param query. Result: ~n", [Result]),
    % The result of squery is propagated back to the caller
    {reply, Result, State};

handle_call({query, Sql}, _From, State = #state{conn_pid = ConnPid}) ->
    
    % io:format("~p: Simple query: ~n~n", [Sql]),

    % Simple query version (no parameters)
    Result = epgsql:squery(ConnPid, Sql),

    % io:format("~p: Simple query. Result: ~n", [Result]),
    {reply, Result, State};

handle_call(_Req, _From, State) ->
    {reply, {error, bad_request}, State}.

handle_cast(_Req, State) ->
    {noreply, State}.

handle_info(_Req, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.
