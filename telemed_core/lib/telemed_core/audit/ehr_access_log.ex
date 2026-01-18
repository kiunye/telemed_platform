defmodule TelemedCore.Audit.EHRAccessLog do
  @moduledoc """
  EHR (Electronic Health Record) access log for HIPAA compliance.

  Tracks every access to medical records with immutable audit trail.
  """
  use Ash.Resource,
    domain: TelemedCore.Audit,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "ehr_access_logs"
    repo TelemedCore.Repo
  end

  attributes do
    uuid_v7_primary_key :id, prefix: "ehr"

    attribute :access_type, :atom do
      allow_nil? false
      constraints [one_of: [:view, :download, :create, :update, :delete]]
    end

    attribute :accessed_by_id, :string do
      allow_nil? false
      # User ID who accessed the record
    end

    attribute :record_id, :string do
      allow_nil? true
      # Medical record ID (if applicable)
    end

    attribute :patient_id, :string do
      allow_nil? false
      # Patient whose record was accessed
    end

    attribute :reason, :string do
      allow_nil? true
      # Reason for access (e.g., "appointment consultation")
    end

    attribute :ip_address, :string
    attribute :user_agent, :string

    timestamps()
  end

  actions do
    defaults [:read]

    create :log_access do
      accept [:access_type, :accessed_by_id, :record_id, :patient_id, :reason, :ip_address, :user_agent]
    end
  end

  policies do
    # Patients can read their own access logs
    policy always() do
      authorize_if expr(patient_id == ^actor(:id))
    end

    # Admins can read all access logs
    policy always() do
      authorize_if expr(actor.role == :admin)
    end

    # Doctors can read access logs for their patients
    policy always() do
      authorize_if expr(actor.role == :doctor)
    end
  end
end
