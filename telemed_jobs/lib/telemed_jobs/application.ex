defmodule TelemedJobs.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Oban, oban_config()}
    ]

    opts = [strategy: :one_for_one, name: TelemedJobs.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp oban_config do
    [
      repo: TelemedCore.Repo,
      queues: [notifications: 10, integrations: 5, webhooks: 5],
      plugins: [
        {Oban.Plugins.Pruner, max_age: 3600}
      ]
    ]
  end
end
