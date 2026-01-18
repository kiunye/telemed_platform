defmodule TelemedCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :telemed_core,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {TelemedCore.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Ash Framework for domain modeling
      {:ash, "~> 3.13.1"},
      {:ash_postgres, "~> 2.0"},
      {:ash_json_api, "~> 1.0", optional: true},
      {:ash_phoenix, "~> 1.0", optional: true},

      # Database
      {:ecto_sql, "~> 3.12"},
      {:postgrex, "~> 0.18"},

      # Utilities
      {:jason, "~> 1.4"},
      {:uuid, "~> 2.0"},
      {:bcrypt_elixir, "~> 3.0"},
      {:joken, "~> 2.6"},

      # Encryption (for PHI)
      {:cloak_ecto, "~> 1.2"},

      # Telemetry
      {:telemetry, "~> 1.2"}
    ]
  end
end
