defmodule Api.Service.Auth do
  use GenServer
  use Timex


  @app_secret_key Application.get_env(:api_test, :app_secret_key)
  @jwt_validity Application.get_env(:api_test, :jwt_validity)
  @issuer :api

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

   def verify_hash(server, {password, hash}) do
    GenServer.call(server, {:verify_hash, {password, hash}})
  end

   def generate_hash(server, password) do
    GenServer.call(server, {:generate_hash, password})
  end

  def issue_token(server, user) when is_map(user) do
     GenServer.call(server, {:issue_token, user})
  end

  def validate_token(server, token) do
     GenServer.call(server, {:validate_token, token})
  end

  def delete_token(server, claims) do
     GenServer.call(server, {:delete_token, claims})
  end

  def handle_call({:generate_hash, password}, _from, state) do
    {:reply, Pbkdf2.hash_pwd_salt(password), state}
  end

  def handle_call({:verify_hash, {password, hash}}, _from, state) do
    {:reply, Pbkdf2.verify_pass(password, hash), state}
  end

  def handle_call({:issue_token, claims}, _from, state) when is_map(claims) do
    signer = Joken.Signer.create("HS256", :base64.encode(@app_secret_key))

    {:ok, jwt, _} = claims |> Map.merge(%{
      iat: Timex.to_unix(Timex.now),
      exp: Timex.to_unix(Timex.shift(Timex.now, seconds: @jwt_validity))
    })
    |> Api.Token.generate_and_sign (signer)

    :ets.insert(:tokens, {claims.id, jwt})

    {:reply, jwt, state}
  end

  def handle_call({:validate_token, token}, _from, state) do
    signer = Joken.Signer.create("HS256", :base64.encode(@app_secret_key))

    case Api.Token.verify_and_validate(token, signer) do
      {:error, _} -> {:reply, "Invalid Token!", state}
      {:ok, claims} ->
        claims = Api.Helpers.MapHelper.string_keys_to_atoms(claims)
        case :ets.lookup(:tokens, claims.id) do
          [{_,_}] -> {:reply, {:ok, claims}, state}
          _ -> {:reply, "Invalid Token!", state}
        end
    end
  end

  def handle_call({:delete_token, claims}, _from, state) do
    case :ets.lookup(:tokens, claims.id) do
      [{_,_}] ->
        :ets.delete(:tokens, claims.id)
        {:reply, :ok, state}
      _ -> {:reply, :error, state}
    end
  end

end
