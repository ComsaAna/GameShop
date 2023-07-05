defmodule BackendStuffApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # database_config = Application.get_env(:check_domain, :db_config)
    # {:ok, _} = Mongo.start_link(database_config)

    children = [
      {
        Plug.Cowboy,
        scheme: :http,
        plug: BackendStuffApi.Router,
        options: [port: Application.get_env(:backend_stuff_api, :port)]
      },
      {
        Mongo,
        [
          name: :mongo,
          url: "mongodb://mongo:27017",
          database: "backend_stuff_api_db",
          # username: "root",
          # password: "example",
          pool_size: 10,
          timeout: 600_000
        ]
      }
      # Starts a worker by calling: BackendStuffApi.Worker.start_link(arg)
      # {BackendStuffApi.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BackendStuffApi.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
