defmodule TelemedCore.Repo.Migrations.CreateAppointmentEvents do
  use Ecto.Migration

  def change do
    create table(:appointment_events, primary_key: false) do
      add :id, :string, primary_key: true
      add :appointment_id, references(:appointments, type: :string, on_delete: :delete_all), null: false
      add :actor_id, references(:users, type: :string, on_delete: :nilify_all)
      add :event_type, :string, null: false
      add :previous_status, :string
      add :new_status, :string
      add :metadata, :map
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create index(:appointment_events, [:appointment_id])
    create index(:appointment_events, [:actor_id])
    create index(:appointment_events, [:event_type])
    create index(:appointment_events, [:inserted_at])
  end
end
