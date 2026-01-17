defmodule TelemedCore.Accounts.Session do
  @moduledoc """
  Session resource for managing user authentication sessions.

  Stores JWT refresh tokens and session metadata.
  """
  use Ash.Resource,
    domain: TelemedCore.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "sessions"
    repo TelemedCore.Repo
  end

  attributes do
    uuid_v7_primary_key :id, prefix: "ses"

    attribute :refresh_token, :string do
      allow_nil? false
      private? true
    end

    attribute :expires_at, :utc_datetime do
      allow_nil? false
    end

    attribute :revoked_at, :utc_datetime

    attribute :ip_address, :string
    attribute :user_agent, :string

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

    create :create_session do
      accept [:user_id, :ip_address, :user_agent]
      argument :refresh_token, :string, allow_nil? false
      argument :expires_at, :utc_datetime, allow_nil? false

      change fn changeset, _context ->
        refresh_token = Ash.Changeset.get_argument(changeset, :refresh_token)
        expires_at = Ash.Changeset.get_argument(changeset, :expires_at)

        changeset
        |> Ash.Changeset.change_attribute(:refresh_token, refresh_token)
        |> Ash.Changeset.change_attribute(:expires_at, expires_at)
      end
    end

    update :revoke do
      accept []

      change fn changeset, _context ->
        Ash.Changeset.force_change_attribute(
          changeset,
          :revoked_at,
          DateTime.utc_now()
        )
      end
    end
  end

  policies do
    # Users can read their own sessions
    policy always() do
      authorize_if expr(user_id == ^actor(:id))
    end

    # Admins can read all sessions
    policy always() do
      authorize_if expr(actor.role == :admin)
    end
  end
end
