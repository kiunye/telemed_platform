defmodule TelemedAdminWeb.AuditLive do
  @moduledoc """
  Audit logs viewer for compliance and debugging.
  """
  use TelemedAdminWeb, :live_view

  on_mount TelemedAdminWeb.LiveHooks

  alias TelemedCore.Audit.AuditLog

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Audit Logs")
     |> assign(:logs, [])
     |> assign(:loading, true)
     |> load_logs()}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    {:noreply, socket |> assign(:loading, true) |> load_logs()}
  end

  defp load_logs(socket) do
    case Ash.read(AuditLog) do
      {:ok, logs} ->
        assign(socket, logs: logs, loading: false)

      {:error, _reason} ->
        assign(socket, logs: [], loading: false)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-8">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-3xl font-semibold text-neutral-900">Audit Logs</h1>
        <button
          phx-click="refresh"
          class="px-4 py-2 bg-primary-500 text-white rounded-md hover:bg-primary-700"
        >
          Refresh
        </button>
      </div>

      <div :if={@loading} class="text-center py-8">
        <p class="text-neutral-500">Loading...</p>
      </div>

      <div :if={not @loading} class="bg-white shadow rounded-lg overflow-hidden">
        <table class="min-w-full divide-y divide-neutral-200">
          <thead class="bg-neutral-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-neutral-500 uppercase tracking-wider">
                Timestamp
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-neutral-500 uppercase tracking-wider">
                Action
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-neutral-500 uppercase tracking-wider">
                Actor
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-neutral-500 uppercase tracking-wider">
                Resource
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-neutral-500 uppercase tracking-wider">
                IP Address
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-neutral-200">
            <tr :for={log <- @logs}>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-neutral-500">
                <%= Calendar.strftime(log.inserted_at, "%Y-%m-%d %H:%M:%S") %>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-neutral-900">
                <%= log.action %>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-neutral-500">
                <%= log.actor_id || "System" %>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-neutral-500">
                <%= if log.resource_type, do: "#{log.resource_type} (#{log.resource_id})", else: "-" %>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-neutral-500">
                <%= log.ip_address || "-" %>
              </td>
            </tr>
            <tr :if={@logs == []}>
              <td colspan="5" class="px-6 py-4 text-center text-sm text-neutral-500">
                No audit logs found
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
