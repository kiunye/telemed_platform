defmodule TelemedAdminWeb.AuthController do
  @moduledoc """
  Controller for setting admin session after LiveView login.
  """
  use TelemedAdminWeb, :controller

  def set_session(conn, %{"token" => token, "user_id" => user_id}) do
    conn
    |> put_session(:user_id, user_id)
    |> put_session(:access_token, token)
    |> redirect(to: "/dashboard")
  end
end
