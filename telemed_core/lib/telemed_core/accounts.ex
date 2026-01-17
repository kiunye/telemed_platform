defmodule TelemedCore.Accounts do
  @moduledoc """
  Accounts domain for user management, authentication, and authorization.

  This domain handles:
  - User registration and profiles
  - Authentication (credentials, sessions)
  - Role-based access control (RBAC)
  - User profiles (patient, doctor, admin)
  """

  use Ash.Domain

  resources do
    resource TelemedCore.Accounts.User
    resource TelemedCore.Accounts.Credential
    resource TelemedCore.Accounts.Session
    resource TelemedCore.Accounts.DoctorProfile
    resource TelemedCore.Accounts.PatientProfile
  end
end
