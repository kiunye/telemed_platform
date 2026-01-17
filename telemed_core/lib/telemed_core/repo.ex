defmodule TelemedCore.Repo do
  use Ecto.Repo,
    otp_app: :telemed_core,
    adapter: Ecto.Adapters.Postgres
end
