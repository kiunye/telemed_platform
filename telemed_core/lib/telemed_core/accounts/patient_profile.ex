defmodule TelemedCore.Accounts.PatientProfile do
  @moduledoc """
  Patient profile with medical information and preferences.
  """
  use Ash.Resource,
    domain: TelemedCore.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "patient_profiles"
    repo TelemedCore.Repo
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :date_of_birth, :date
    attribute :gender, :string
    attribute :emergency_contact_name, :string
    attribute :emergency_contact_phone, :string
    attribute :preferred_language, :string, default: "en"

    timestamps()
  end

  relationships do
    belongs_to :user, TelemedCore.Accounts.User do
      attribute_writable? true
      allow_nil? false
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create_profile do
      accept [:user_id, :date_of_birth, :gender, :emergency_contact_name, :emergency_contact_phone, :preferred_language]
    end

    update :update_profile do
      accept [:date_of_birth, :gender, :emergency_contact_name, :emergency_contact_phone, :preferred_language]
    end
  end

  policies do
    # Patients can read their own profile
    policy always() do
      authorize_if expr(user_id == ^actor(:id))
    end

    # Doctors can read patient profiles for appointments they have
    # (Will be expanded when appointments are implemented)
    policy always() do
      authorize_if expr(actor.role == "doctor")
    end

    # Admins can read all profiles
    policy always() do
      authorize_if expr(actor.role == "admin")
    end
  end
end
