defmodule TelemedCore.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TelemedCore.Repo
    ]

    opts = [strategy: :one_for_one, name: TelemedCore.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
