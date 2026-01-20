defmodule TelemedAdminWeb.LiveHooks do
  @moduledoc """
  LiveView hooks for common functionality like loading current user.
  """
  import Phoenix.Component

  def on_mount(_atom, _params, session, socket) do
    current_user = case Map.get(session, :user_id) || Map.get(session, "user_id") do
      nil -> nil
      user_id ->
        case Ash.get(TelemedCore.Accounts.User, user_id) do
          {:ok, user} -> user
          {:error, _} -> nil
        end
    end

    {:cont, assign(socket, current_user: current_user)}
  end
end
