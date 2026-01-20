defmodule TelemedAdminWeb.CalendarLive do
  @moduledoc """
  LiveView for viewing appointments in calendar format.
  """
  use TelemedAdminWeb, :live_view

  alias TelemedCore.Appointments.Appointment
  require Ash.Query

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns[:current_user]
    today = Date.utc_today()

    {:ok,
     socket
     |> assign(:page_title, "Appointment Calendar")
     |> assign(:appointments, [])
     |> assign(:loading, true)
     |> assign(:selected_date, today)
     |> load_appointments(current_user.id, today)}
  end

  @impl true
  def handle_event("select_date", %{"date" => date_string}, socket) do
    current_user = socket.assigns[:current_user]
    {:ok, date} = Date.from_iso8601(date_string)

    {:noreply,
     socket
     |> assign(:selected_date, date)
     |> assign(:loading, true)
     |> load_appointments(current_user.id, date)}
  end

  defp load_appointments(socket, doctor_id, date) do
    start_of_day = DateTime.new!(date, ~T[00:00:00], "UTC")
    end_of_day = DateTime.new!(date, ~T[23:59:59], "UTC")

    query =
      Ash.Query.for_read(Appointment, :read, actor: %{id: doctor_id, role: :doctor})
      |> Ash.Query.filter(
        doctor_id == ^doctor_id and scheduled_at >= ^start_of_day and scheduled_at <= ^end_of_day
      )
      |> Ash.Query.sort(scheduled_at: :asc)

    case Ash.read(query) do
      {:ok, appointments} ->
        assign(socket, appointments: appointments, loading: false)

      {:error, _reason} ->
        assign(socket, appointments: [], loading: false)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-8">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-3xl font-semibold text-neutral-900">Appointment Calendar</h1>
        <input
          type="date"
          value={Date.to_iso8601(@selected_date)}
          phx-change="select_date"
          phx-debounce="300"
          class="px-3 py-2 border border-neutral-300 rounded-md focus:outline-none focus:ring-primary-500 focus:border-primary-500"
        />
      </div>

      <div :if={@loading} class="text-center py-8">
        <p class="text-neutral-500">Loading...</p>
      </div>

      <div :if={not @loading} class="bg-white rounded-lg shadow">
        <div class="p-6">
          <h2 class="text-xl font-semibold mb-4">
            Appointments for <%= Calendar.strftime(@selected_date, "%B %d, %Y") %>
          </h2>

          <div :if={@appointments == []} class="text-center py-8 text-neutral-500">
            No appointments scheduled for this date.
          </div>

          <div :if={@appointments != []} class="space-y-4">
            <div
              :for={appointment <- @appointments}
              class="border border-neutral-200 rounded-lg p-4 hover:bg-neutral-50"
            >
              <div class="flex justify-between items-start">
                <div>
                  <div class="flex items-center gap-2 mb-2">
                    <span class="text-lg font-semibold text-neutral-900">
                      <%= Calendar.strftime(appointment.scheduled_at, "%H:%M") %>
                    </span>
                    <span
                      class={"px-2 py-1 text-xs font-medium rounded-full " <>
                             status_color(appointment.status)}
                    >
                      <%= String.capitalize(to_string(appointment.status)) %>
                    </span>
                  </div>
                  <p class="text-sm text-neutral-600">
                    Duration: <%= appointment.duration_minutes %> minutes
                  </p>
                  <p :if={appointment.reason} class="text-sm text-neutral-700 mt-1">
                    Reason: <%= appointment.reason %>
                  </p>
                </div>
                <div class="text-right">
                  <p class="text-sm text-neutral-500">Patient ID</p>
                  <p class="text-sm font-medium text-neutral-900"><%= appointment.patient_id %></p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp status_color(:scheduled), do: "bg-blue-100 text-blue-800"
  defp status_color(:confirmed), do: "bg-green-100 text-green-800"
  defp status_color(:in_progress), do: "bg-yellow-100 text-yellow-800"
  defp status_color(:completed), do: "bg-neutral-100 text-neutral-800"
  defp status_color(:cancelled), do: "bg-red-100 text-red-800"
  defp status_color(_), do: "bg-neutral-100 text-neutral-800"
end
