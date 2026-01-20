defmodule TelemedJobs.Workers.AppointmentReminderWorker do
  @moduledoc """
  Oban worker for sending appointment reminders.

  Sends reminders 24 hours and 1 hour before appointments.
  """
  use Oban.Worker,
    queue: :notifications,
    max_attempts: 3,
    tags: ["appointment", "reminder"]

  require Logger

  alias TelemedCore.Appointments.Appointment
  alias TelemedCore.Accounts.User
  alias TelemedJobs.Providers.StubProvider

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"appointment_id" => appointment_id, "reminder_type" => reminder_type}}) do
    type =
      case reminder_type do
        "day_before" -> :day_before
        "hour_before" -> :hour_before
        _ -> :unknown
      end

    case Ash.get(Appointment, appointment_id) do
      {:ok, appointment} ->
        send_reminder(appointment, type)

      {:error, _reason} ->
        {:error, :appointment_not_found}
    end
  end

  defp send_reminder(appointment, type) do
    with {:ok, patient} <- Ash.get(User, appointment.patient_id),
         {:ok, doctor} <- Ash.get(User, appointment.doctor_id) do
      message = build_reminder_message(appointment, doctor, type)

      case StubProvider.send_sms(patient.phone || "", message, []) do
        {:ok, delivery_id} ->
          Logger.info("Reminder sent", appointment_id: appointment.id, delivery_id: delivery_id)
          :ok

        {:error, reason} ->
          Logger.error("Failed to send reminder", appointment_id: appointment.id, reason: reason)
          {:error, reason}
      end
    else
      error ->
        Logger.error("Failed to load user for reminder", error: error)
        error
    end
  end

  defp build_reminder_message(appointment, doctor, :day_before) do
    scheduled_time = Calendar.strftime(appointment.scheduled_at, "%B %d at %I:%M %p")
    "Reminder: You have an appointment with Dr. #{doctor.first_name} #{doctor.last_name} tomorrow at #{scheduled_time}. Reply CANCEL to cancel."
  end

  defp build_reminder_message(appointment, doctor, :hour_before) do
    scheduled_time = Calendar.strftime(appointment.scheduled_at, "%I:%M %p")
    "Reminder: Your appointment with Dr. #{doctor.first_name} #{doctor.last_name} is in 1 hour at #{scheduled_time}."
  end

  defp build_reminder_message(_appointment, _doctor, _type) do
    "Reminder: You have an upcoming appointment."
  end
end
