defmodule TelemedApiWeb.Plugs.Authenticate do
  @moduledoc """
  Plug to authenticate requests using JWT access tokens.

  Verifies the Authorization header and loads the current user.
  """
  import Plug.Conn
  import Phoenix.Controller
  alias TelemedCore.Accounts.Impl.AuthService

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        case AuthService.verify_access_token(token) do
          {:ok, user} ->
            conn
            |> assign(:current_user, user)
            |> assign(:authenticated, true)

          {:error, _reason} ->
            conn
            |> put_status(:unauthorized)
            |> json(%{error: "Invalid or expired token"})
            |> halt()
        end

      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Missing authorization header"})
        |> halt()
    end
  end
end
