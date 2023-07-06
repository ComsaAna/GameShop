defmodule BackendStuffApi.Api.Plugs.AuthPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    case conn.private |> Map.get(:jwt_skip, false) do
      true ->
        conn
      false->
        {:ok, service} = Api.Service.Auth.start_link
        case get_req_header(conn, "authorization") do
          ["Bearer "<>token] ->
            case Api.Service.Auth.validate_token(service,token) do
              {:ok, _} -> conn
              _ -> conn |> send_resp(401, "No access") |> halt
            end
        _ -> conn |> send_resp(401, "No access") |> halt
        end
    end
  end
end
