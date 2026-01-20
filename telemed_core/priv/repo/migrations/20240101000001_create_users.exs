defmodule TelemedCore.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add(:id, :string, primary_key: true, default: fragment("gen_random_uuid()::text"))
      add(:email, :string, null: false)
      add(:role, :string, null: false)
      add(:first_name, :string)
      add(:last_name, :string)
      add(:phone, :string)
      add(:email_verified, :boolean, default: false, null: false)
      add(:phone_verified, :boolean, default: false, null: false)
      add(:version, :integer, default: 1, null: false)
      add(:inserted_at, :utc_datetime, null: false)
      add(:updated_at, :utc_datetime, null: false)
    end

    create(unique_index(:users, [:email]))
    create(index(:users, [:role]))
  end
end
