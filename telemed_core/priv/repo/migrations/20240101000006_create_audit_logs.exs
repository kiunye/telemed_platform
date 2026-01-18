defmodule TelemedCore.Repo.Migrations.CreateAuditLogs do
  use Ecto.Migration

  def change do
    create table(:audit_logs, primary_key: false) do
      add :id, :string, primary_key: true
      add :action, :string, null: false
      add :actor_id, :string
      add :actor_type, :string
      add :resource_type, :string
      add :resource_id, :string
      add :metadata, :map
      add :ip_address, :string
      add :user_agent, :string
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create index(:audit_logs, [:actor_id])
    create index(:audit_logs, [:action])
    create index(:audit_logs, [:resource_type, :resource_id])
    create index(:audit_logs, [:inserted_at])
  end
end
