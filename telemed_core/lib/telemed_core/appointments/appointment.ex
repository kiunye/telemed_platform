defmodule TelemedCore.Appointments.Appointment do
  @moduledoc """
  Appointment resource with state machine for lifecycle management.

  States: :scheduled -> :confirmed -> :in_progress -> :completed | :cancelled
  """
  use Ash.Resource,
    domain: TelemedCore.Appointments,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "appointments"
    repo TelemedCore.Repo
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :status, :atom do
      allow_nil? false
      constraints [one_of: [:scheduled, :confirmed, :in_progress, :completed, :cancelled, :no_show]]
      default :scheduled
    end

    attribute :scheduled_at, :utc_datetime do
      allow_nil? false
    end

    attribute :duration_minutes, :integer do
      allow_nil? false
      default 30
    end

    attribute :timezone, :string do
      allow_nil? false
      default "UTC"
    end

    attribute :reason, :string
    # Patient's reason for visit

    attribute :notes, :string
    # Doctor's notes (added during/after appointment)

    attribute :version, :integer, default: 1
    # For optimistic locking

    timestamps()
  end

  relationships do
    belongs_to :patient, TelemedCore.Accounts.User do
      attribute_writable? true
      allow_nil? false
    end

    belongs_to :doctor, TelemedCore.Accounts.User do
      attribute_writable? true
      allow_nil? false
    end

    belongs_to :availability_slot, TelemedCore.Appointments.AvailabilitySlot do
      attribute_writable? true
      allow_nil? true
    end

    has_many :events, TelemedCore.Appointments.AppointmentEvent
  end

  actions do
    defaults [:read, :destroy]

    create :book do
      accept [:patient_id, :doctor_id, :scheduled_at, :duration_minutes, :timezone, :reason, :availability_slot_id]

      change fn changeset, _context ->
        Ash.Changeset.force_change_attribute(changeset, :status, :scheduled)
      end
    end

    update :confirm do
      accept []
      require_atomic? false
      validate fn changeset, _context ->
        current_status = Ash.Changeset.get_attribute(changeset, :status)

        if current_status == :scheduled do
          changeset
          |> Ash.Changeset.force_change_attribute(:status, :confirmed)
        else
          Ash.Changeset.add_error(
            changeset,
            field: :status,
            message: "can only confirm scheduled appointments"
          )
        end
      end
      change optimistic_lock(:version)
    end

    update :start do
      accept []
      require_atomic? false
      validate fn changeset, _context ->
        current_status = Ash.Changeset.get_attribute(changeset, :status)

        if current_status in [:scheduled, :confirmed] do
          changeset
          |> Ash.Changeset.force_change_attribute(:status, :in_progress)
        else
          Ash.Changeset.add_error(
            changeset,
            field: :status,
            message: "can only start scheduled or confirmed appointments"
          )
        end
      end
      change optimistic_lock(:version)
    end

    update :complete do
      accept [:notes]
      require_atomic? false
      validate fn changeset, _context ->
        current_status = Ash.Changeset.get_attribute(changeset, :status)

        if current_status == :in_progress do
          changeset
          |> Ash.Changeset.force_change_attribute(:status, :completed)
        else
          Ash.Changeset.add_error(
            changeset,
            field: :status,
            message: "can only complete in-progress appointments"
          )
        end
      end
      change optimistic_lock(:version)
    end

    update :cancel do
      accept []
      require_atomic? false
      validate fn changeset, _context ->
        current_status = Ash.Changeset.get_attribute(changeset, :status)

        if current_status not in [:completed, :cancelled] do
          changeset
          |> Ash.Changeset.force_change_attribute(:status, :cancelled)
        else
          Ash.Changeset.add_error(
            changeset,
            field: :status,
            message: "cannot cancel completed or already cancelled appointments"
          )
        end
      end
      change optimistic_lock(:version)
    end

    update :reschedule do
      accept [:scheduled_at, :timezone]
      change optimistic_lock(:version)
    end
  end

  policies do
    # Patients can read their own appointments
    policy always() do
      authorize_if expr(patient_id == ^actor(:id))
    end

    # Doctors can read their own appointments
    policy always() do
      authorize_if expr(doctor_id == ^actor(:id))
    end

    # Admins can read all appointments
    policy always() do
      authorize_if expr(actor.role == "admin")
    end
  end
end
