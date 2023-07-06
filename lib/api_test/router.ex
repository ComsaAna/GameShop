defmodule BackendStuffApi.Router do
  use Plug.Router

  alias BackendStuffApi.Api.Service.Publisher

  @routing_keys Application.get_env(:api_test, :routing_keys)

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  )
  plug(:dispatch)
  plug :encode_response

  defp encode_response(conn, _) do
    conn
    |>send_resp(conn.status, conn.assigns |> Map.get(:jsonapi, %{}) |> Poison.encode!)
  end

  get("/", do: send_resp(conn, 200, "OK"))

  get("/aliens_name", do: send_resp(conn, 200, "Blork Erlang"))

  get "/knockknock" do
    # Starts an unpooled connection
    case Mongo.start_link(url: "mongodb://localhost:27017/backend_stuff_api_db") do
      {:ok, _} -> send_resp(conn, 200, "Who's there?")
      {:error, _} -> send_resp(conn, 500, "Something went wrong")
    end
  end



  post "/login" do
    {email, password} = {
      Map.get(conn.params, "email", nil),
      Map.get(conn.params, "password", nil)
    }

    {:ok, service} = BackendStuffApi.Api.Service.Auth.start_link

    case :ets.lookup(:users, email) do
      [{_,user}] ->

        case BackendStuffApi.Api.Service.Auth.verify_hash(service, {password, user.password}) do
          true ->
            token = BackendStuffApi.Api.Service.Auth.issue_token(service, %{:id => email})

           #publishing login event
           Publisher.publish(
             @routing_keys |> Map.get("user_login"),
             %{:id => email})
             # user |> Map.take([:id,:name]))


            conn
                |> put_status(200)
                |> assign(:jsonapi, %{:token => token})
                |> assign(:auth_service, service)

          false ->
            conn
            |> put_status(404)
            |> assign(:jsonapi, %{"message" => "no access!!"})
            |> assign(:auth_service, service)

        end
      _ ->
      conn
      |> put_status(404)
      |> assign(:jsonapi, %{"message" => "no access"})
      |> assign(:auth_service, service)

    # case email == "something@me.com" and password == "admin"  do
    #    true ->
    #     {:ok, service} = Api.Service.Auth.start_link
    #
    #     token = Api.Service.Auth.issue_token(service, %{:id => email})
    #
    #     conn
    #         |> put_status(200)
    #         |> assign(:jsonapi, %{:token => token})
    #   false ->
    #     conn
    #     |> put_status(404)
    #     |> assign(:jsonapi, %{"message" => "no access"})

    end
  end

  # post "/sign-up", private: @skip_token_verification do
  #   {email, password} = {
  #     Map.get(conn.params, "email", nil),
  #     Map.get(conn.params, "password", nil)
  #   }

  #   cond do
  #     is_nil(email) ->
  #       conn
  #       |> put_status(400)
  #       |> assign(:jsonapi, %{"error" => "email field must be provided"})
  #     is_nil(password) ->
  #       conn
  #       |> put_status(400)
  #       |> assign(:jsonapi, %{"error" => "password field must be provided"})
  #     true ->
  #       {:ok, service} = BackendStuffApi.Api.Service.Auth.start_link
  #       user = BackendStuffApi.Api.User{
  #         email: email,
  #         password: BackendStuffApi.Api.Service.Auth.generate_hash(service, password)
  #       }
  #       :ets.insert(:users, {user.email, user})
  #       conn
  #       |> put_status(201)
  #       |> assign(:jsonapi, %{"message" => "User registered"})
  #       |> assign(:user_id, user.email)
  #       |> assign(:auth_service, service)
  #   end
  # end

  post "/logout/:email" do
    {:ok, service} = BackendStuffApi.Api.Service.Auth.start_link
    case BackendStuffApi.Api.Service.Auth.delete_token(service, %{:id => email}) do
      :ok ->
        conn
        |> put_status(200)
        |> assign(:jsonapi, %{"message" => "Logout successfull"})
        |> assign(:auth_service, service)
      :error ->
        conn
        |> put_status(400)
        |> assign(:jsonapi, %{"message" => "Logout unsuccessfull"})
        |> assign(:auth_service, service)
    end
  end

#  forward("/games", to: BackendStuffApi.Api.Endpoint)

#   match _ do
#     conn
#     #|> put_status(404)
#     #|> assign(:jsonapi, %{"message" => "not found"})
#     |> send_resp(404, Poison.encode!(%{message: "Not Found"}))
#   end
end
