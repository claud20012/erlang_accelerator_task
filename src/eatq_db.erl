-module(eatq_db).

%% Use this module to build SQL queries and call eatq_db_connection to execute them
%% Feel free to add functions and modify this module

-export([
    save_task/1,
    get_tasks/0
]).

%% API

save_task(_Task) ->
    error.

get_tasks() ->
    [].
