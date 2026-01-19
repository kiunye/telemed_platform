defmodule TelemedCore.Audit.AuditLog do
  @moduledoc """
  General audit log for tracking user actions and system events.

  This is an append-only log for compliance and debugging.
  """
  use Ash.Resource,
    domain: TelemedCore.Audit,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "audit_logs"
    repo TelemedCore.Repo
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :action, :string do
      allow_nil? false
      # Examples: "user.login", "user.register", "appointment.create", etc.
    end

    attribute :actor_id, :string do
      allow_nil? true
      # User ID who performed the action (nil for system actions)
    end

    attribute :actor_type, :string do
      allow_nil? true
      # "user", "system", "admin"
    end

    attribute :resource_type, :string do
      allow_nil? true
      # Type of resource affected: "User", "Appointment", etc.
    end

    attribute :resource_id, :string do
      allow_nil? true
      # ID of resource affected
    end

    attribute :metadata, :map do
      allow_nil? true
      # Additional context (IP address, user agent, etc.)
    end

    attribute :ip_address, :string
    attribute :user_agent, :string

    timestamps()
  end

  actions do
    defaults [:read]

    create :log do
      accept [:action, :actor_id, :actor_type, :resource_type, :resource_id, :metadata, :ip_address, :user_agent]
    end
  end

  policies do
    # Only admins can read audit logs
    policy always() do
      authorize_if expr(actor.role == "admin")
    end
  end
end
