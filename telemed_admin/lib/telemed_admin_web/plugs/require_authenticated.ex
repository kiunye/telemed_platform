defmodule TelemedAdminWeb.Plugs.RequireAuthenticated do
  @moduledoc """
  Plug to require authentication for LiveView routes.

  Checks for user in session and redirects to login if not authenticated.
  """
  import Plug.Conn
  import Phoenix.Controller
  alias TelemedCore.Accounts.User

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :user_id) do
      nil ->
        conn
        |> put_flash(:error, "You must be logged in to access this page")
        |> redirect(to: ~p"/login")
        |> halt()

      user_id ->
        # Load user and assign to conn
        case Ash.get(User, user_id) do
          {:ok, user} ->
            if user.role in [:admin, :doctor] do
              assign(conn, :current_user, user)
            else
              conn
              |> put_flash(:error, "Access denied")
              |> redirect(to: ~p"/login")
              |> halt()
            end

          {:error, _} ->
            conn
            |> put_flash(:error, "User not found")
            |> redirect(to: ~p"/login")
            |> halt()
        end
    end
  end
end
