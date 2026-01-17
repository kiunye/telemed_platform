defmodule TelemedJobs.MixProject do
  use Mix.Project

  def project do
    [
      app: :telemed_jobs,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Path dependencies (Dave Thomas structure)
      {:telemed_core, path: "../telemed_core"},

      # Background jobs
      {:oban, "~> 2.17"},

      # Utilities
      {:jason, "~> 1.4"}
    ]
  end
end
