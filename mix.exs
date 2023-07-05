defmodule JWT_TEST_UPDATED.MixProject do
  use Mix.Project

  def project do
    [
      app: :backend_stuff_api,
      version: "0.1.0",
      elixir: "~> 1.14.4",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:plug_cowboy, :logger, :mongodb, :ecto],
      extra_applications: [:logger],
      mod: {JWT_TEST_UPDATED.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.0"},
      {:jason, "~> 1.4"},
      {:mongodb, "~> 1.0.0"},
      # {:mongodb_driver, "~> 1.0.0"},
      # {:amqp, "~> 3.3"},
      {:ecto, "~> 3.7"},
      {:uuid, "~> 1.1.8"},
      {:comeonin, "~> 2.6"},
      {:guardian, "~> 2.0"},
      {:mongodb_ecto, "~> 1.0.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
