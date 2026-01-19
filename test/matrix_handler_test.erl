-module(matrix_handler_test).
-include_lib("eunit/include/eunit.hrl").

%% Unit test: ensure calculation the highest diagonal product works correctly
calculate_diagonal_product_test() ->
    CellMap = #{
        {1,1} => 2.5,
        {1,2} => 3.0,
        {2,1} => 4.1,
        {2,2} => 5.0
    },
    Result = matrix_handler:calculate_diagonal_product(CellMap, 2, 1, 1),
    case Result of
        undefined ->
            io:format("Unexpected undefined result from calculate_diagonal_product/4~n"),
            ?assert(false);
        P when is_number(P) ->
            io:format("Diagonal product result: ~p~n", [P]),
            ?assert(is_number(P)),
            ?assertEqual(12.5, P)
    end.

