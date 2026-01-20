defmodule TelemedApiWeb.AppointmentsController do
  @moduledoc """
  Appointments controller for booking, rescheduling, and managing appointments.
  """
  use TelemedApiWeb, :controller

  require Ash.Query

  alias TelemedCore.Appointments
  alias TelemedCore.Appointments.{Appointment, AvailabilitySlot}
  alias TelemedCore.Appointments.Impl.BookingService

  @doc """
  Search available slots for a doctor.
  GET /api/v1/appointments/availability
  """
  def search_availability(conn, params) do
    doctor_id = params["doctor_id"]
    start_date = parse_date(params["start_date"])
    end_date = parse_date(params["end_date"])

    query =
      Ash.Query.for_read(AvailabilitySlot, :read)
      |> Ash.Query.filter(doctor_id == ^doctor_id)
      |> Ash.Query.filter(is_available == true)

    query =
      if start_date do
        Ash.Query.filter(query, start_time >= ^start_date)
      else
        query
      end

    query =
      if end_date do
        Ash.Query.filter(query, end_time <= ^end_date)
      else
        query
      end

    case Ash.read(query) do
      {:ok, slots} ->
        conn
        |> put_status(:ok)
        |> json(%{
          data: Enum.map(slots, &format_availability_slot/1)
        })

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: to_string(reason)})
    end
  end

  @doc """
  Book an appointment.
  POST /api/v1/appointments
  """
  def create(conn, params) do
    current_user = conn.assigns.current_user

    attrs = %{
      patient_id: current_user.id,
      doctor_id: params["doctor_id"],
      scheduled_at: parse_datetime(params["scheduled_at"]),
      duration_minutes: String.to_integer(params["duration_minutes"] || "30"),
      timezone: params["timezone"] || "UTC",
      reason: params["reason"],
      availability_slot_id: params["availability_slot_id"]
    }

    case BookingService.book_appointment(attrs, current_user.id) do
      {:ok, %{create_appointment: appointment}} ->
        conn
        |> put_status(:created)
        |> json(%{
          data: format_appointment(appointment)
        })

      {:error, :check_slot_available, reason, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Slot unavailable: #{inspect(reason)}"})

      {:error, :check_doctor_available, :doctor_unavailable, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Doctor is not available at that time"})

      {:error, _step, reason, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: to_string(reason)})
    end
  end

  @doc """
  List appointments for current user.
  GET /api/v1/appointments
  """
  def index(conn, params) do
    current_user = conn.assigns.current_user

    query =
      Ash.Query.for_read(Appointment, :read)
      |> Ash.Query.filter(patient_id == ^current_user.id)

    query =
      if params["status"] do
        Ash.Query.filter(query, status == ^String.to_existing_atom(params["status"]))
      else
        query
      end

    case Ash.read(query) do
      {:ok, appointments} ->
        conn
        |> put_status(:ok)
        |> json(%{
          data: Enum.map(appointments, &format_appointment/1)
        })

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: to_string(reason)})
    end
  end

  @doc """
  Get a specific appointment.
  GET /api/v1/appointments/:id
  """
  def show(conn, %{"id" => id}) do
    case Ash.get(Appointment, id) do
      {:ok, appointment} ->
        conn
        |> put_status(:ok)
        |> json(%{
          data: format_appointment(appointment)
        })

      {:error, _reason} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Appointment not found"})
    end
  end

  @doc """
  Reschedule an appointment.
  PATCH /api/v1/appointments/:id/reschedule
  """
  def reschedule(conn, %{"id" => id} = params) do
    current_user = conn.assigns.current_user

    new_scheduled_at = parse_datetime(params["scheduled_at"])
    timezone = params["timezone"] || "UTC"

    case BookingService.reschedule_appointment(id, new_scheduled_at, timezone, current_user.id) do
      {:ok, %{reschedule: {_previous_status, appointment}}} ->
        conn
        |> put_status(:ok)
        |> json(%{
          data: format_appointment(appointment)
        })

      {:error, :load_appointment, {:error, _reason}, _} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Appointment not found"})

      {:error, :check_doctor_available, :doctor_unavailable, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Doctor is not available at that time"})

      {:error, _step, reason, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: to_string(reason)})
    end
  end

  @doc """
  Cancel an appointment.
  POST /api/v1/appointments/:id/cancel
  """
  def cancel(conn, %{"id" => id}) do
    current_user = conn.assigns.current_user

    case BookingService.cancel_appointment(id, current_user.id) do
      {:ok, %{cancel: {_previous_status, appointment}}} ->
        conn
        |> put_status(:ok)
        |> json(%{
          data: format_appointment(appointment)
        })

      {:error, :load_appointment, {:error, _reason}, _} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Appointment not found"})

      {:error, _step, reason, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: to_string(reason)})
    end
  end

  # Helper functions

  defp format_appointment(appointment) do
    %{
      id: appointment.id,
      status: appointment.status,
      scheduled_at: appointment.scheduled_at,
      duration_minutes: appointment.duration_minutes,
      timezone: appointment.timezone,
      reason: appointment.reason,
      notes: appointment.notes,
      patient_id: appointment.patient_id,
      doctor_id: appointment.doctor_id,
      availability_slot_id: appointment.availability_slot_id
    }
  end

  defp format_availability_slot(slot) do
    %{
      id: slot.id,
      start_time: slot.start_time,
      end_time: slot.end_time,
      timezone: slot.timezone,
      is_recurring: slot.is_recurring,
      recurrence_pattern: slot.recurrence_pattern
    }
  end

  defp parse_datetime(nil), do: nil

  defp parse_datetime(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _offset} -> datetime
      {:error, _} -> nil
    end
  end

  defp parse_date(nil), do: nil

  defp parse_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> DateTime.new!(date, ~T[00:00:00], "UTC")
      {:error, _} -> nil
    end
  end
end
