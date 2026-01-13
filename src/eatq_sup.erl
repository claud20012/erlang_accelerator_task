-module(eatq_sup).
-behaviour(supervisor).

-export([
    start_link/0
]).

-export([
    init/1
]).

%% API

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% supervisor callbacks

init([]) ->
    %% Suggested child list and order: DB connection -> Worker Pool -> Scheduler
    %% For now, don't worry if cowboy starts before other components.
    eatq_db_connection:start_link(),
    Dispatch = eatq_http_handler:start_routes(),
    {ok, _Pid} = cowboy:start_clear(http_listener,
                        [{port, 8095}],
                        #{env => #{dispatch => Dispatch}}),
    % ...existing code...
    SupFlags = #{
        strategy => one_for_all,
        intensity => 0,
        period => 1
    },
    ChildSpecs = [],
    {ok, {SupFlags, ChildSpecs}}.

%% internal functions
