-module(eatq_db_connection_test).
-include_lib("stdlib/include/assert.hrl").
-behaviour(eunit).

%% Simple unit tests for the current stubbed API.
query_no_params_test() ->
    ?assertEqual(ok, eatq_db_connection:query("SELECT 1")).

query_with_params_test() ->
    ?assertEqual(ok, eatq_db_connection:query("SELECT $1", [1])).