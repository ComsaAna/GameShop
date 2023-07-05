defmodule Api.Models.Game do
  @db_name Application.get_env(:api_test, :db_db)
  @db_table "game"

  #Step 1. install mongo
  #Step 2. create db (use bands)
  #Step 3. run and test band api
  #Step 4. implement User Management Api

  #Api pentru User Management:
  #/users/register POST
  #/users/login POST => %{"message": :ok}
  #/users PATCH (UPDATE username)
  #
  # User(id, username, email, password)
  use Api.Models.Base
  #INFO: mongo also has an internal ID
  #ignored in this exercise
  defstruct [
    :id,
    :name,
    :year,
    :updated_at,
    :created_at
  ]
end
