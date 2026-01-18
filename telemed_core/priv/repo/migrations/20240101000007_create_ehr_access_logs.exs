defmodule TelemedCore.Repo.Migrations.CreateEHRAccessLogs do
  use Ecto.Migration

  def change do
    create table(:ehr_access_logs, primary_key: false) do
      add :id, :string, primary_key: true
      add :access_type, :string, null: false
      add :accessed_by_id, :string, null: false
      add :record_id, :string
      add :patient_id, :string, null: false
      add :reason, :string
      add :ip_address, :string
      add :user_agent, :string
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create index(:ehr_access_logs, [:accessed_by_id])
    create index(:ehr_access_logs, [:patient_id])
    create index(:ehr_access_logs, [:record_id])
    create index(:ehr_access_logs, [:inserted_at])
  end
end
