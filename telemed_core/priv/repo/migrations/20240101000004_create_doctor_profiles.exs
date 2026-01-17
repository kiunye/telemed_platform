defmodule TelemedCore.Repo.Migrations.CreateDoctorProfiles do
  use Ecto.Migration

  def change do
    create table(:doctor_profiles, primary_key: false) do
      add :id, :string, primary_key: true
      add :user_id, references(:users, type: :string, on_delete: :delete_all), null: false
      add :specialty, :string
      add :license_number, :string
      add :license_state, :string
      add :bio, :text
      add :years_of_experience, :integer
      add :verified, :boolean, default: false, null: false
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create unique_index(:doctor_profiles, [:user_id])
    create index(:doctor_profiles, [:verified])
    create index(:doctor_profiles, [:specialty])
  end
end
