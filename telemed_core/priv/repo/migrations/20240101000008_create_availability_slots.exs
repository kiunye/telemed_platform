defmodule TelemedCore.Repo.Migrations.CreateAvailabilitySlots do
  use Ecto.Migration

  def change do
    create table(:availability_slots, primary_key: false) do
      add :id, :string, primary_key: true
      add :doctor_id, references(:users, type: :string, on_delete: :delete_all), null: false
      add :start_time, :utc_datetime, null: false
      add :end_time, :utc_datetime, null: false
      add :timezone, :string, null: false, default: "UTC"
      add :is_recurring, :boolean, default: false, null: false
      add :recurrence_pattern, :string
      add :is_available, :boolean, default: true, null: false
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create index(:availability_slots, [:doctor_id])
    create index(:availability_slots, [:start_time, :end_time])
    create index(:availability_slots, [:is_available])
  end
end
