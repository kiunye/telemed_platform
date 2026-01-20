defmodule TelemedAdminWeb.AvailabilityLive do
  @moduledoc """
  LiveView for doctors to manage their availability slots.
  """
  use TelemedAdminWeb, :live_view

  alias TelemedCore.Appointments.AvailabilitySlot
  require Ash.Query

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns[:current_user]

    {:ok,
     socket
     |> assign(:page_title, "Manage Availability")
     |> assign(:slots, [])
     |> assign(:loading, true)
     |> assign(:show_form, false)
     |> assign(:form_data, %{})
     |> assign(:errors, [])
     |> load_slots(current_user.id)}
  end

  @impl true
  def handle_event("show_form", _params, socket) do
    {:noreply, assign(socket, show_form: true)}
  end

  def handle_event("hide_form", _params, socket) do
    {:noreply, assign(socket, show_form: false, form_data: %{}, errors: [])}
  end

  def handle_event("create_slot", params, socket) do
    current_user = socket.assigns[:current_user]

    attrs = %{
      doctor_id: current_user.id,
      start_time: parse_datetime(params["start_time"]),
      end_time: parse_datetime(params["end_time"]),
      timezone: params["timezone"] || "UTC",
      is_recurring: params["is_recurring"] == "true",
      recurrence_pattern: params["recurrence_pattern"]
    }

    case AvailabilitySlot.create_slot(attrs, actor: current_user) do
      {:ok, _slot} ->
        {:noreply,
         socket
         |> put_flash(:info, "Availability slot created successfully")
         |> assign(:show_form, false)
         |> assign(:form_data, %{})
         |> assign(:errors, [])
         |> load_slots(current_user.id)}

      {:error, changeset} ->
        errors = format_changeset_errors(changeset)
        {:noreply, assign(socket, errors: errors)}
    end
  end

  def handle_event("delete_slot", %{"id" => id}, socket) do
    current_user = socket.assigns[:current_user]

    case Ash.get(AvailabilitySlot, id, actor: current_user) do
      {:ok, slot} ->
        case AvailabilitySlot.destroy(slot, actor: current_user) do
          :ok ->
            {:noreply,
             socket
             |> put_flash(:info, "Slot deleted successfully")
             |> load_slots(current_user.id)}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, "Failed to delete slot")}
        end

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Slot not found")}
    end
  end

  defp load_slots(socket, doctor_id) do
    query =
      Ash.Query.for_read(AvailabilitySlot, :read, actor: %{id: doctor_id, role: :doctor})
      |> Ash.Query.filter(doctor_id == ^doctor_id)
      |> Ash.Query.sort(inserted_at: :desc)

    case Ash.read(query) do
      {:ok, slots} ->
        assign(socket, slots: slots, loading: false)

      {:error, _reason} ->
        assign(socket, slots: [], loading: false)
    end
  end

  defp parse_datetime(nil), do: nil

  defp parse_datetime(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _offset} -> datetime
      {:error, _} -> nil
    end
  end

  defp format_changeset_errors(changeset) do
    changeset
    |> Ash.Changeset.errors()
    |> Enum.map(fn error -> %{field: error.field, message: error.message} end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-8">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-3xl font-semibold text-neutral-900">Manage Availability</h1>
        <button
          phx-click="show_form"
          class="px-4 py-2 bg-primary-500 text-white rounded-md hover:bg-primary-700"
        >
          Add Availability Slot
        </button>
      </div>

      <div :if={@show_form} class="bg-white rounded-lg shadow p-6 mb-6">
        <h2 class="text-xl font-semibold mb-4">New Availability Slot</h2>
        <form phx-submit="create_slot" class="space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-neutral-700 mb-1">Start Time</label>
              <input
                type="datetime-local"
                name="start_time"
                required
                class="w-full px-3 py-2 border border-neutral-300 rounded-md focus:outline-none focus:ring-primary-500 focus:border-primary-500"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-neutral-700 mb-1">End Time</label>
              <input
                type="datetime-local"
                name="end_time"
                required
                class="w-full px-3 py-2 border border-neutral-300 rounded-md focus:outline-none focus:ring-primary-500 focus:border-primary-500"
              />
            </div>
          </div>
          <div>
            <label class="block text-sm font-medium text-neutral-700 mb-1">Timezone</label>
            <select
              name="timezone"
              class="w-full px-3 py-2 border border-neutral-300 rounded-md focus:outline-none focus:ring-primary-500 focus:border-primary-500"
            >
              <option value="UTC">UTC</option>
              <option value="America/New_York">Eastern Time</option>
              <option value="America/Chicago">Central Time</option>
              <option value="America/Denver">Mountain Time</option>
              <option value="America/Los_Angeles">Pacific Time</option>
            </select>
          </div>
          <div class="flex items-center">
            <input
              type="checkbox"
              name="is_recurring"
              id="is_recurring"
              class="mr-2"
            />
            <label for="is_recurring" class="text-sm text-neutral-700">Recurring slot</label>
          </div>
          <div :if={@errors != []} class="bg-error-50 p-4 rounded-md">
            <ul class="list-disc list-inside text-sm text-error-800">
              <li :for={error <- @errors}><%= error.field %>: <%= error.message %></li>
            </ul>
          </div>
          <div class="flex gap-2">
            <button
              type="submit"
              class="px-4 py-2 bg-primary-500 text-white rounded-md hover:bg-primary-700"
            >
              Create Slot
            </button>
            <button
              type="button"
              phx-click="hide_form"
              class="px-4 py-2 bg-neutral-200 text-neutral-700 rounded-md hover:bg-neutral-300"
            >
              Cancel
            </button>
          </div>
        </form>
      </div>

      <div :if={@loading} class="text-center py-8">
        <p class="text-neutral-500">Loading...</p>
      </div>

      <div :if={not @loading} class="bg-white rounded-lg shadow overflow-hidden">
        <table class="min-w-full divide-y divide-neutral-200">
          <thead class="bg-neutral-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-neutral-500 uppercase tracking-wider">
                Start Time
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-neutral-500 uppercase tracking-wider">
                End Time
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-neutral-500 uppercase tracking-wider">
                Timezone
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-neutral-500 uppercase tracking-wider">
                Recurring
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-neutral-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-neutral-200">
            <tr :for={slot <- @slots}>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-neutral-900">
                <%= Calendar.strftime(slot.start_time, "%Y-%m-%d %H:%M") %>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-neutral-900">
                <%= Calendar.strftime(slot.end_time, "%Y-%m-%d %H:%M") %>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-neutral-500">
                <%= slot.timezone %>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-neutral-500">
                <%= if slot.is_recurring, do: "Yes", else: "No" %>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                <button
                  phx-click="delete_slot"
                  phx-value-id={slot.id}
                  class="text-error-600 hover:text-error-800"
                >
                  Delete
                </button>
              </td>
            </tr>
            <tr :if={@slots == []}>
              <td colspan="5" class="px-6 py-4 text-center text-sm text-neutral-500">
                No availability slots. Click "Add Availability Slot" to create one.
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
