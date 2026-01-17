defmodule TelemedAdminWeb.PageController do
  use TelemedAdminWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
