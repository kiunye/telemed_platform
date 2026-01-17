defmodule TelemedCore.Repo.Migrations.CreatePatientProfiles do
  use Ecto.Migration

  def change do
    create table(:patient_profiles, primary_key: false) do
      add :id, :string, primary_key: true
      add :user_id, references(:users, type: :string, on_delete: :delete_all), null: false
      add :date_of_birth, :date
      add :gender, :string
      add :emergency_contact_name, :string
      add :emergency_contact_phone, :string
      add :preferred_language, :string, default: "en"
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create unique_index(:patient_profiles, [:user_id])
  end
end
