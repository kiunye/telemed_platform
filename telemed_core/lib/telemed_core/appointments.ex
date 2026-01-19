defmodule TelemedCore.Appointments do
  @moduledoc """
  Appointments domain for scheduling and managing healthcare appointments.

  This domain handles:
  - Doctor availability slots (timezone-aware)
  - Appointment booking and state management
  - Appointment history and events
  - Conflict detection and prevention
  """
  use Ash.Domain,
    extensions: [Ash.Policy.Authorizer]

  resources do
    resource TelemedCore.Appointments.AvailabilitySlot
    resource TelemedCore.Appointments.Appointment
    resource TelemedCore.Appointments.AppointmentEvent
  end
end
