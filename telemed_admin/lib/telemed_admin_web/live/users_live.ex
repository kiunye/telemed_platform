defmodule TelemedAdminWeb.UsersLive do
  @moduledoc """
  Users management page (stub for now).
  """
  use TelemedAdminWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Users")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-8">
      <h1 class="text-3xl font-semibold text-neutral-900 mb-6">Users</h1>
      <p class="text-neutral-700">User management coming soon...</p>
    </div>
    """
  end
end
