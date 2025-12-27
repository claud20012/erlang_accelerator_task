-module(eatq_db).

%% Use this module to build SQL queries and call eatq_db_connection to execute them
%% Feel free to add functions and modify this module

-export([
    save_task/1,
    get_matrix_data/1
]).

%% API

save_task(_Task) ->
    error.

get_matrix_data(Id) ->
    %% initiate a query to fetch matrix data by Id and send it to eatq_db_connection 
    %% SQL = "SELECT matrix_id, row_index, col_index, value FROM matrix_cell WHERE matrix_id = $1",
    SQL = "SELECT matrix_id, row_index, col_index, value FROM matrix_cell",
    Params = [Id],

    eatq_db_connection:query(SQL).
