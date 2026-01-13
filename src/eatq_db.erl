-module(eatq_db).

%% Use this module to build SQL queries and call eatq_db_connection to execute them
%% Feel free to add functions and modify this module

-export([
    save_task/1,
    get_matrix_data/1,
    save_matrix/2
]).

%% API

save_task(_Task) ->
    error.

get_matrix_data(Id) ->
    %% initiate a query to fetch matrix data by Id and send it to eatq_db_connection 
    SQL = "SELECT matrix_id, row_index, col_index, value FROM matrix_cell WHERE matrix_id = $1",
    Params = [Id],

    eatq_db_connection:query(SQL, Params).


%% Persist matrix cells into the database.
%% Cells is expected to be a list of tuples: {MatrixId, RowIndex, ColIndex, Value}
save_matrix(_MatrixId, []) ->
    {ok, 0};
save_matrix(MatrixId, Cells) when is_list(Cells) ->
    SQL = "INSERT INTO matrix_cell (matrix_id, row_index, col_index, value) VALUES ($1, $2, $3, $4)",
    save_matrix_loop(MatrixId, Cells, SQL, 0).

save_matrix_loop(_MatrixId, [], _SQL, Acc) ->
    {ok, Acc};
save_matrix_loop(MatrixId, [{_M, R, C, V} | T], SQL, Acc) ->
    case eatq_db_connection:query(SQL, [MatrixId, R, C, V]) of
        {ok, _Res} ->
            save_matrix_loop(MatrixId, T, SQL, Acc + 1);
        {error, Reason} ->
            {error, Reason};
        Other ->
            {error, Other}
    end.
