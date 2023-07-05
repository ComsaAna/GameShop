defmodule Api.Router do
  use Plug.Router

  alias Api.Service.Publisher

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

  post "/login" do
    {email, password} = {
      Map.get(conn.params, "email", nil),
      Map.get(conn.params, "password", nil)
    }

    {:ok, service} = Api.Service.Auth.start_link

    case :ets.lookup(:users, email) do
      [{_,user}] ->

        case Api.Service.Auth.verify_hash(service, {password, user.password}) do
          true ->
            token = Api.Service.Auth.issue_token(service, %{:id => email})

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

  post "/sign-up", private: @skip_token_verification do
    {email, password} = {
      Map.get(conn.params, "email", nil),
      Map.get(conn.params, "password", nil)
    }

    cond do
      is_nil(email) ->
        conn
        |> put_status(400)
        |> assign(:jsonapi, %{"error" => "email field must be provided"})
      is_nil(password) ->
        conn
        |> put_status(400)
        |> assign(:jsonapi, %{"error" => "password field must be provided"})
      true ->
        {:ok, service} = Api.Service.Auth.start_link
        user = %Api.User{
          email: email,
          password: Api.Service.Auth.generate_hash(service, password)
        }
        :ets.insert(:users, {user.email, user})
        conn
        |> put_status(201)
        |> assign(:jsonapi, %{"message" => "User registered"})
        |> assign(:user_id, user.email)
        |> assign(:auth_service, service)
    end
  end

  post "/logout/:email" do
    {:ok, service} = Api.Service.Auth.start_link
    case Api.Service.Auth.delete_token(service, %{:id => email}) do
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

 forward("/games", to: Api.Endpoint)

  match _ do
    conn
    #|> put_status(404)
    #|> assign(:jsonapi, %{"message" => "not found"})
    |> send_resp(404, Poison.encode!(%{message: "Not Found"}))
  end
end
