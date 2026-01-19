defmodule TelemedCore.Appointments.AppointmentEvent do
  @moduledoc """
  Append-only event log for appointment state changes and actions.

  Provides immutable audit trail for appointment lifecycle.
  """
  use Ash.Resource,
    domain: TelemedCore.Appointments,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "appointment_events"
    repo TelemedCore.Repo
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :event_type, :atom do
      allow_nil? false
      constraints [
        one_of: [
          :created,
          :confirmed,
          :started,
          :completed,
          :cancelled,
          :rescheduled,
          :notes_updated
        ]
      ]
    end

    attribute :previous_status, :atom
    attribute :new_status, :atom

    attribute :metadata, :map
    # Additional context (reason, notes, etc.)

    timestamps()
  end

  relationships do
    belongs_to :appointment, TelemedCore.Appointments.Appointment do
      attribute_writable? true
      allow_nil? false
    end

    belongs_to :actor, TelemedCore.Accounts.User do
      attribute_writable? true
      allow_nil? true
      # nil for system events
    end
  end

  actions do
    defaults [:read]

    create :log_event do
      accept [:appointment_id, :event_type, :previous_status, :new_status, :metadata, :actor_id]
    end
  end

  policies do
    # Patients can read events for their appointments
    policy always() do
      authorize_if expr(appointment.patient_id == ^actor(:id))
    end

    # Doctors can read events for their appointments
    policy always() do
      authorize_if expr(appointment.doctor_id == ^actor(:id))
    end

    # Admins can read all events
    policy always() do
      authorize_if expr(actor.role == "admin")
    end
  end
end
