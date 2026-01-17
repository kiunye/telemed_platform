defmodule TelemedCore.Accounts.User do
  @moduledoc """
  User resource representing patients, doctors, and administrators.

  Users have a role (patient, doctor, admin) and associated profiles.
  """
  use Ash.Resource,
    domain: TelemedCore.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "users"
    repo TelemedCore.Repo
  end

  attributes do
    uuid_v7_primary_key :id, prefix: "usr"

    attribute :email, :string do
      allow_nil? false
      constraints [format: ~r/^[^\s]+@[^\s]+$/]
    end

    attribute :role, :atom do
      allow_nil? false
      constraints [one_of: [:patient, :doctor, :admin]]
      default :patient
    end

    attribute :first_name, :string
    attribute :last_name, :string
    attribute :phone, :string

    attribute :email_verified, :boolean, default: false
    attribute :phone_verified, :boolean, default: false

    attribute :version, :integer, default: 1

    timestamps()
  end

  relationships do
    has_one :credential, TelemedCore.Accounts.Credential
    has_one :doctor_profile, TelemedCore.Accounts.DoctorProfile
    has_one :patient_profile, TelemedCore.Accounts.PatientProfile
    has_many :sessions, TelemedCore.Accounts.Session
  end

  actions do
    defaults [:read, :destroy]

    create :register do
      accept [:email, :first_name, :last_name, :phone, :role]
      change fn changeset, _context ->
        Ash.Changeset.force_change_attribute(changeset, :email_verified, false)
      end
    end

    update :update_profile do
      accept [:first_name, :last_name, :phone]
      change optimistic_lock(:version)
    end

    update :verify_email do
      accept []
      change fn changeset, _context ->
        Ash.Changeset.force_change_attribute(changeset, :email_verified, true)
      end
      change optimistic_lock(:version)
    end
  end

  policies do
    # Users can read their own profile
    policy always() do
      authorize_if expr(id == ^actor(:id))
    end

    # Admins can read all users
    policy always() do
      authorize_if expr(actor.role == :admin)
    end

    # Doctors can read patients they have appointments with
    # (This will be expanded when appointments are implemented)
    policy always() do
      authorize_if expr(actor.role == :doctor and role == :patient)
    end
  end
end
