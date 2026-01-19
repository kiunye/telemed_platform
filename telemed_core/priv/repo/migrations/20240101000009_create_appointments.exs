defmodule TelemedCore.Repo.Migrations.CreateAppointments do
  use Ecto.Migration

  def change do
    create table(:appointments, primary_key: false) do
      add :id, :string, primary_key: true
      add :patient_id, references(:users, type: :string, on_delete: :restrict), null: false
      add :doctor_id, references(:users, type: :string, on_delete: :restrict), null: false
      add :availability_slot_id, references(:availability_slots, type: :string, on_delete: :nilify_all)
      add :status, :string, null: false, default: "scheduled"
      add :scheduled_at, :utc_datetime, null: false
      add :duration_minutes, :integer, null: false, default: 30
      add :timezone, :string, null: false, default: "UTC"
      add :reason, :text
      add :notes, :text
      add :version, :integer, default: 1, null: false
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create index(:appointments, [:patient_id])
    create index(:appointments, [:doctor_id])
    create index(:appointments, [:status])
    create index(:appointments, [:scheduled_at])

    # Unique constraint to prevent double-booking of the same slot
    # Note: This also creates an index on availability_slot_id, so we don't need a separate one
    create unique_index(:appointments, [:availability_slot_id],
             where: "status NOT IN ('cancelled', 'completed', 'no_show')"
           )
  end
end
