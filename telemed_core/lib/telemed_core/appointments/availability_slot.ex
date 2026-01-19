defmodule TelemedCore.Appointments.AvailabilitySlot do
  @moduledoc """
  Availability slot representing when a doctor is available for appointments.

  Slots are timezone-aware and can be recurring or one-time.
  """
  use Ash.Resource,
    domain: TelemedCore.Appointments,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "availability_slots"
    repo TelemedCore.Repo
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :start_time, :utc_datetime do
      allow_nil? false
    end

    attribute :end_time, :utc_datetime do
      allow_nil? false
    end

    attribute :timezone, :string do
      allow_nil? false
      default "UTC"
    end

    attribute :is_recurring, :boolean, default: false
    attribute :recurrence_pattern, :string
    # Examples: "daily", "weekly", "weekdays", JSON for complex patterns

    attribute :is_available, :boolean, default: true
    # Can be temporarily disabled without deleting

    timestamps()
  end

  relationships do
    belongs_to :doctor, TelemedCore.Accounts.User do
      attribute_writable? true
      allow_nil? false
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create_slot do
      accept [:doctor_id, :start_time, :end_time, :timezone, :is_recurring, :recurrence_pattern]
      validate fn changeset, _context ->
        start_time = Ash.Changeset.get_attribute(changeset, :start_time)
        end_time = Ash.Changeset.get_attribute(changeset, :end_time)

        if DateTime.compare(start_time, end_time) != :lt do
          Ash.Changeset.add_error(
            changeset,
            field: :end_time,
            message: "must be after start time"
          )
        else
          changeset
        end
      end
    end

    update :update_slot do
      accept [:start_time, :end_time, :timezone, :is_recurring, :recurrence_pattern, :is_available]
    end
  end

  policies do
    # Doctors can manage their own availability
    policy always() do
      authorize_if expr(doctor_id == ^actor(:id))
    end

    # Admins can manage all availability
    policy always() do
      authorize_if expr(actor.role == "admin")
    end

    # Patients can read available slots (for booking)
    policy always() do
      authorize_if expr(is_available == true and actor.role == "patient")
    end
  end
end
