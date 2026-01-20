defmodule TelemedCore.Appointments.Impl.BookingService do
  @moduledoc """
  Service for booking appointments with conflict detection and prevention.

  Uses transactions and optimistic locking to prevent double-booking.
  """
  import Ash.Expr
  require Ash.Query
  alias TelemedCore.Appointments.{Appointment, AvailabilitySlot, AppointmentEvent}
  alias Ecto.Multi

  @doc """
  Books an appointment with conflict detection.
  """
  def book_appointment(attrs, actor_id) do
    Multi.new()
    |> Multi.run(:check_slot_available, fn _repo, _changes ->
      check_slot_available(attrs[:availability_slot_id], attrs[:scheduled_at])
    end)
    |> Multi.run(:check_doctor_available, fn _repo, _changes ->
      check_doctor_available(attrs[:doctor_id], attrs[:scheduled_at], attrs[:duration_minutes])
    end)
    |> Multi.run(:create_appointment, fn _repo, _changes ->
      Appointment.book(attrs)
    end)
    |> Multi.run(:log_event, fn _repo, %{create_appointment: appointment} ->
      log_appointment_event(appointment, :created, nil, :scheduled, actor_id)
    end)
    |> Multi.run(:schedule_reminders, fn _repo, %{create_appointment: appointment} ->
      TelemedCore.Appointments.Impl.NotificationService.schedule_reminders(appointment.id)
      {:ok, :scheduled}
    end)
    |> TelemedCore.Repo.transaction()
  end

  @doc """
  Reschedules an appointment with conflict detection.
  """
  def reschedule_appointment(appointment_id, new_scheduled_at, timezone, actor_id) do
    Multi.new()
    |> Multi.run(:load_appointment, fn _repo, _changes ->
      case Ash.get(Appointment, appointment_id) do
        {:ok, appointment} -> {:ok, appointment}
        error -> error
      end
    end)
    |> Multi.run(:check_doctor_available, fn _repo, %{load_appointment: appointment} ->
      check_doctor_available(
        appointment.doctor_id,
        new_scheduled_at,
        appointment.duration_minutes
      )
    end)
    |> Multi.run(:reschedule, fn _repo, %{load_appointment: appointment} ->
      previous_status = appointment.status

      appointment
      |> Ash.Changeset.for_update(:reschedule, %{
        scheduled_at: new_scheduled_at,
        timezone: timezone
      })
      |> Ash.update()
      |> case do
        {:ok, updated} ->
          {:ok, {previous_status, updated}}

        error ->
          error
      end
    end)
    |> Multi.run(:log_event, fn _repo, %{reschedule: {previous_status, appointment}} ->
      log_appointment_event(appointment, :rescheduled, previous_status, appointment.status, actor_id)
    end)
    |> TelemedCore.Repo.transaction()
  end

  @doc """
  Cancels an appointment.
  """
  def cancel_appointment(appointment_id, actor_id) do
    Multi.new()
    |> Multi.run(:load_appointment, fn _repo, _changes ->
      case Ash.get(Appointment, appointment_id) do
        {:ok, appointment} -> {:ok, appointment}
        error -> error
      end
    end)
    |> Multi.run(:cancel, fn _repo, %{load_appointment: appointment} ->
      previous_status = appointment.status
      appointment
      |> Ash.Changeset.for_update(:cancel, %{})
      |> Ash.update()
      |> case do
        {:ok, updated} -> {:ok, {previous_status, updated}}
        error -> error
      end
    end)
    |> Multi.run(:log_event, fn _repo, %{cancel: {previous_status, appointment}} ->
      log_appointment_event(appointment, :cancelled, previous_status, :cancelled, actor_id)
    end)
    |> TelemedCore.Repo.transaction()
  end

  # Private helper functions

  defp check_slot_available(nil, _scheduled_at), do: {:ok, :no_slot}

  defp check_slot_available(slot_id, scheduled_at) do
    case Ash.get(AvailabilitySlot, slot_id) do
      {:ok, slot} ->
        if slot.is_available and
             DateTime.compare(slot.start_time, scheduled_at) != :gt and
             DateTime.compare(slot.end_time, scheduled_at) != :lt do
          # Check if slot is already booked
          case Ash.read_one(
                 Ash.Query.for_read(Appointment, :read)
                 |> Ash.Query.filter(expr(availability_slot_id == ^slot_id))
                 |> Ash.Query.filter(expr(status != :cancelled))
                 |> Ash.Query.filter(expr(status != :completed))
                 |> Ash.Query.filter(expr(status != :no_show))
               ) do
            {:ok, nil} -> {:ok, :available}
            {:ok, _existing} -> {:error, :slot_already_booked}
            error -> error
          end
        else
          {:error, :slot_not_available}
        end

      {:error, _} = error ->
        error
    end
  end

  defp check_doctor_available(doctor_id, scheduled_at, duration_minutes) do
    end_time = DateTime.add(scheduled_at, duration_minutes, :minute)

    # Check for overlapping appointments
    case Ash.read(
           Ash.Query.for_read(Appointment, :read)
           |> Ash.Query.filter(expr(doctor_id == ^doctor_id))
           |> Ash.Query.filter(expr(status != :cancelled))
           |> Ash.Query.filter(expr(status != :completed))
           |> Ash.Query.filter(expr(status != :no_show))
           |> Ash.Query.filter(
             expr(scheduled_at >= ^scheduled_at and scheduled_at < ^end_time)
           )
         ) do
      {:ok, []} ->
        {:ok, :available}

      {:ok, _overlapping} ->
        {:error, :doctor_unavailable}

      error ->
        error
    end
  end

  defp log_appointment_event(appointment, event_type, previous_status, new_status, actor_id) do
    AppointmentEvent
    |> Ash.Changeset.for_create(:log_event, %{
      appointment_id: appointment.id,
      event_type: event_type,
      previous_status: previous_status,
      new_status: new_status,
      actor_id: actor_id
    })
    |> Ash.create()
  end
end
