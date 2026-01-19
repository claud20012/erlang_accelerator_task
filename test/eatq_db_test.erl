-module(eatq_db_test).
-include_lib("eunit/include/eunit.hrl").

%% Integration test: ensure get_matrix_data/1 returns at least one row for matrix id 1
matrixdata_single_element_test() ->
    %% Ensure the DB connection gen_server is started (ignore if already running)
    case whereis(eatq_db_connection) of
        undefined ->
            _ = (try eatq_db_connection:start_link() of R -> R catch _:_ -> ok end),
            ok;
        _ -> ok
    end,

    case eatq_db:get_matrix_data(1) of
        {ok, _Columns, Rows} when is_list(Rows) ->
            ?assert(0 < length(Rows));
        {error, Reason} ->
            io:format("DB query failed: ~p~n", [Reason]),
            ?assert(false);
        Other ->
            io:format("Unexpected result from get_matrix_data/1: ~p~n", [Other]),
            ?assert(false)
    end.