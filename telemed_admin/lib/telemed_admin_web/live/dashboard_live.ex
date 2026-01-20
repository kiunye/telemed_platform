defmodule TelemedAdminWeb.DashboardLive do
  @moduledoc """
  Main dashboard for admin and doctor portals.
  """
  use TelemedAdminWeb, :live_view

  on_mount TelemedAdminWeb.LiveHooks

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Dashboard")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-neutral-50">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <h1 class="text-3xl font-semibold text-neutral-900 mb-6">Dashboard</h1>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-neutral-700 mb-2">Users</h3>
            <p class="text-3xl font-bold text-primary-500">-</p>
          </div>
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-neutral-700 mb-2">Appointments</h3>
            <p class="text-3xl font-bold text-primary-500">-</p>
          </div>
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-neutral-700 mb-2">Active Sessions</h3>
            <p class="text-3xl font-bold text-primary-500">-</p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
