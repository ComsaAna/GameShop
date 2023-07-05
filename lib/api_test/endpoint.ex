defmodule Api.Endpoint do
  use Plug.Router

  alias Api.Views.GameView
  alias Api.Models.Game
  alias Api.Views.UserView
  alias Api.Models.User
  alias Api.Views.UserGameView
  alias Api.Models.UserGame
  alias Api.Plugs.JsonTestPlug

  @api_port Application.get_env(:api_test, :api_port)
  @api_host Application.get_env(:api_test, :api_host)
  @api_scheme Application.get_env(:api_test, :api_scheme)
  @skip_token_verification %{jwt_skip: true}

  plug :match
  plug :dispatch
  plug JsonTestPlug
  plug Api.Plugs.AuthPlug
  plug :encode_response

  defp encode_response(conn, _) do
    conn
    |>send_resp(conn.status, conn.assigns |> Map.get(:jsonapi, %{}) |> Poison.encode!)
  end

  get "/", private: %{view: GameView}  do
    params = Map.get(conn.params, "filter", %{})

    {_, games} =  Game.find(params)

    conn
    |> put_status(200)
    |> assign(:jsonapi, games)
  end

  get "/public", private: @skip_token_verification do
    conn
    |> put_status(200)
    |> assign(:jsonapi, %{"message" => "'this' is a public EP"})
  end

  get "/private" do
    conn
    |> put_status(200)
    |> assign(:jsonapi, %{"message" => "'this' is a private EP"})
  end

  delete "/:id" do
    {parsedId, ""} = Integer.parse(id)

    case Game.delete(parsedId) do
      :error ->
         conn
         |> put_status(404)
         |> assign(:jsonapi, %{"error" => "Game not found"})
      :ok ->
        conn
        |> put_status(200)
        |> assign(:jsonapi, %{message: "#{id} was deleted"})
    end
  end

  delete "/user/:id" do
    {parsedId, ""} = Integer.parse(id)

    case User.delete(parsedId) do
      :error ->
         conn
         |> put_status(404)
         |> assign(:jsonapi, %{"error" => "User not found"})
      :ok ->
        conn
        |> put_status(200)
        |> assign(:jsonapi, %{message: "#{id} was deleted"})
    end
  end

  delete "/usergame/:id" do
    {parsedId, ""} = Integer.parse(id)

    case UserGame.delete(parsedId) do
      :error ->
         conn
         |> put_status(404)
         |> assign(:jsonapi, %{"error" => "User-Game not found"})
      :ok ->
        conn
        |> put_status(200)
        |> assign(:jsonapi, %{message: "#{id} was deleted"})
    end
  end

  get "/:id", private: %{view: GameView}  do
    {parsedId, ""} = Integer.parse(id)

    case Game.get(parsedId) do
      {:ok, game} ->
        #without the test plug just call the serializer manually
        #(plug :encode_response must be in this care removed)
        #resp = JSONAPI.Serializer.serialize(BandView, band, conn)
        # conn
        #|> put_resp_content_type("application/json")
        #|> send_resp(200, Poison.encode!(resp))

        conn
        |> put_status(200)
        |> assign(:jsonapi, game)

      :error ->
        conn
        |> put_status(404)
        |> assign(:jsonapi, %{"error" => "Game not found"})
    end
  end

  get "/user/:id", private: %{view: UserView}  do
    {parsedId, ""} = Integer.parse(id)

    case User.get(parsedId) do
      {:ok, user} ->

        conn
        |> put_status(200)
        |> assign(:jsonapi, user)

      :error ->
        conn
        |> put_status(404)
        |> assign(:jsonapi, %{"error" => "User not found"})
    end
  end

  get "/usergame/:id", private: %{view: UserGameView}  do
    {parsedId, ""} = Integer.parse(id)

    case UserGame.get(parsedId) do
      {:ok, user_game} ->

        conn
        |> put_status(200)
        |> assign(:jsonapi, user_game)

      :error ->
        conn
        |> put_status(404)
        |> assign(:jsonapi, %{"error" => "User-Game not found"})
    end
  end

  patch "/:id", private: %{view: GameView} do
    #not tested
    {parsedId, ""} = Integer.parse(id)

    {name, year} = {
      Map.get(conn.params, "name", nil),
      Map.get(conn.params, "year", nil)
    }

    Game.delete(parsedId)

    case %Game{name: name, year: year, id: parsedId} |> Game.save do
      {:ok, createdEntry} ->
        conn
        |> put_status(200)
        |> assign(:jsonapi, createdEntry)
      :error ->
        conn
         |> put_status(500)
         |> assign(:jsonapi, %{"error" => "An unexpected error happened"})
    end
  end

  post "/", private: %{view: GameView} do
    {name, year, id} = {
      Map.get(conn.params, "name", nil),
      Map.get(conn.params, "year", nil),
      Map.get(conn.params, "id", nil)
    }

    cond do
      is_nil(name) ->
        conn
        |> put_status(400)
        |> assign(:jsonapi, %{error: "name must be present!"})

      is_nil(year) ->
        conn
        |> put_status(400)
        |> assign(:jsonapi, %{error: "year must be present!"})

      is_nil(id) ->
        conn
        |> put_status(400)
        |> assign(:jsonapi, %{error: "id must be present!"})

      true ->
      case %Game{name: name, year: year, id: id} |> Game.save do
        {:ok, createdEntry} ->
          uri = "#{@api_scheme}://#{@api_host}:#{@api_port}#{conn.request_path}/"
          #not optimal

          conn
          |> put_resp_header("location", "#{uri}#{id}")
          |> put_status(201)
          |> assign(:jsonapi, createdEntry)
        :error ->
          conn
           |> put_status(500)
           |> assign(:jsonapi, %{"error" => "An unexpected error happened"})
      end
    end
  end

  post "/user", private: %{view: UserView} do
    {email, password, id} = {
      Map.get(conn.params, "email", nil),
      Map.get(conn.params, "password", nil),
      Map.get(conn.params, "id", nil)
    }

    cond do
      is_nil(email) ->
        conn
        |> put_status(400)
        |> assign(:jsonapi, %{error: "email must be present!"})

      is_nil(password) ->
        conn
        |> put_status(400)
        |> assign(:jsonapi, %{error: "password must be present!"})

      is_nil(id) ->
        conn
        |> put_status(400)
        |> assign(:jsonapi, %{error: "id must be present!"})

      true ->
      case %User{email: email, password: password, id: id} |> User.save do
        {:ok, createdEntry} ->
          uri = "#{@api_scheme}://#{@api_host}:#{@api_port}#{conn.request_path}/"
          #not optimal

          conn
          |> put_resp_header("location", "#{uri}#{id}")
          |> put_status(201)
          |> assign(:jsonapi, createdEntry)
        :error ->
          conn
           |> put_status(500)
           |> assign(:jsonapi, %{"error" => "An unexpected error happened"})
      end
    end
  end

  post "/user/game", private: %{view: UserGameView} do
    {id, user_id, game_id} = {
      Map.get(conn.params, "id", nil),
      Map.get(conn.params, "user_id", nil),
      Map.get(conn.params, "game_id", nil)
    }

    cond do
      is_nil(id) ->
        conn
        |> put_status(400)
        |> assign(:jsonapi, %{error: "id must be present!"})

      is_nil(user_id) ->
        conn
        |> put_status(400)
        |> assign(:jsonapi, %{error: "user_id must be present!"})

      is_nil(game_id) ->
        conn
        |> put_status(400)
        |> assign(:jsonapi, %{error: "game_id must be present!"})

      true ->
      case %UserGame{id: id, user_id: user_id, game_id: game_id} |> UserGame.save do
        {:ok, createdEntry} ->
          uri = "#{@api_scheme}://#{@api_host}:#{@api_port}#{conn.request_path}/"
          #not optimal

          conn
          |> put_resp_header("location", "#{uri}#{id}")
          |> put_status(201)
          |> assign(:jsonapi, createdEntry)
        :error ->
          conn
           |> put_status(500)
           |> assign(:jsonapi, %{"error" => "An unexpected error happened"})
      end
    end
  end
end
