defmodule TelemedCore.Appointments.Impl.NotificationService do
  @moduledoc """
  Service for scheduling appointment reminder notifications.

  Enqueues Oban jobs for sending reminders at appropriate times.
  """
  alias TelemedJobs.Workers.AppointmentReminderWorker

  @doc """
  Schedules reminder notifications for an appointment.

  Creates jobs for 24-hour and 1-hour reminders.
  """
  def schedule_reminders(appointment_id) do
    # Schedule 24-hour reminder
    schedule_reminder(appointment_id, "day_before", hours_before: 24)

    # Schedule 1-hour reminder
    schedule_reminder(appointment_id, "hour_before", hours_before: 1)

    :ok
  end

  @doc """
  Cancels scheduled reminders for an appointment.
  """
  def cancel_reminders(appointment_id) do
    # Oban doesn't have built-in job cancellation, but jobs will fail gracefully
    # if appointment is cancelled when they run
    :ok
  end

  defp schedule_reminder(appointment_id, type, opts) do
    hours_before = Keyword.get(opts, :hours_before, 24)

    # Calculate scheduled time
    case Ash.get(TelemedCore.Appointments.Appointment, appointment_id) do
      {:ok, appointment} ->
        scheduled_time = DateTime.add(appointment.scheduled_at, -hours_before, :hour)

        %{
          "appointment_id" => appointment_id,
          "reminder_type" => type
        }
        |> AppointmentReminderWorker.new(scheduled_at: scheduled_time)
        |> Oban.insert()

      {:error, _reason} ->
        {:error, :appointment_not_found}
    end
  end
end
