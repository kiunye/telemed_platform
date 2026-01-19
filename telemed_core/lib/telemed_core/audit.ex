defmodule TelemedCore.Audit do
  @moduledoc """
  Audit domain for logging system events and access to sensitive data.

  This domain handles:
  - General audit logs (user actions, system events)
  - EHR access logs (HIPAA compliance requirement)
  """
  use Ash.Domain,
    extensions: [Ash.Policy.Authorizer]

  resources do
    resource TelemedCore.Audit.AuditLog
    resource TelemedCore.Audit.EHRAccessLog
  end
end
