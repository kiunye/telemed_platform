defmodule TelemedCore.Accounts.DoctorProfile do
  @moduledoc """
  Doctor profile with specialty, license, and practice information.
  """
  use Ash.Resource,
    domain: TelemedCore.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "doctor_profiles"
    repo TelemedCore.Repo
  end

  attributes do
    uuid_v7_primary_key :id, prefix: "doc"

    attribute :specialty, :string
    attribute :license_number, :string
    attribute :license_state, :string
    attribute :bio, :string
    attribute :years_of_experience, :integer

    attribute :verified, :boolean, default: false

    timestamps()
  end

  relationships do
    belongs_to :user, TelemedCore.Accounts.User do
      attribute_writable? true
      allow_nil? false
      unique? true
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create_profile do
      accept [:user_id, :specialty, :license_number, :license_state, :bio, :years_of_experience]
      change fn changeset, _context ->
        Ash.Changeset.force_change_attribute(changeset, :verified, false)
      end
    end

    update :update_profile do
      accept [:specialty, :license_number, :license_state, :bio, :years_of_experience]
    end

    update :verify do
      accept []
      change fn changeset, _context ->
        Ash.Changeset.force_change_attribute(changeset, :verified, true)
      end
    end
  end

  policies do
    # Doctors can read their own profile
    policy always() do
      authorize_if expr(user_id == ^actor(:id))
    end

    # Anyone can read verified doctor profiles (for booking)
    policy always() do
      authorize_if expr(verified == true)
    end

    # Admins can read all profiles
    policy always() do
      authorize_if expr(actor.role == :admin)
    end
  end
end
