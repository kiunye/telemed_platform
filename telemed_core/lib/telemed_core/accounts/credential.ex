defmodule TelemedCore.Accounts.Credential do
  @moduledoc """
  Credential resource for storing password hashes.

  Each user has one credential record with a bcrypt-hashed password.
  """
  use Ash.Resource,
    domain: TelemedCore.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "credentials"
    repo TelemedCore.Repo
  end

  attributes do
    uuid_v7_primary_key :id, prefix: "crd"

    attribute :password_hash, :string do
      allow_nil? false
      private? true
    end

    timestamps()
  end

  relationships do
    belongs_to :user, TelemedCore.Accounts.User do
      attribute_writable? true
      allow_nil? false
    end
  end

  actions do
    defaults [:read]

    create :create_with_password do
      accept [:user_id]
      argument :password, :string, allow_nil? false

      change fn changeset, context ->
        password = Ash.Changeset.get_argument(changeset, :password)

        # Validate password strength
        if String.length(password) < 8 do
          Ash.Changeset.add_error(
            changeset,
            field: :password,
            message: "must be at least 8 characters"
          )
        else
          # Hash password with bcrypt
          hash = Bcrypt.hash_pwd_salt(password)
          Ash.Changeset.change_attribute(changeset, :password_hash, hash)
        end
      end
    end

    update :update_password do
      accept []
      argument :password, :string, allow_nil? false

      change fn changeset, context ->
        password = Ash.Changeset.get_argument(changeset, :password)

        if String.length(password) < 8 do
          Ash.Changeset.add_error(
            changeset,
            field: :password,
            message: "must be at least 8 characters"
          )
        else
          hash = Bcrypt.hash_pwd_salt(password)
          Ash.Changeset.change_attribute(changeset, :password_hash, hash)
        end
      end
    end
  end

  policies do
    # Users can only read their own credentials (for verification)
    policy always() do
      authorize_if expr(user_id == ^actor(:id))
    end

    # Admins can read all credentials (for support)
    policy always() do
      authorize_if expr(actor.role == :admin)
    end
  end
end
