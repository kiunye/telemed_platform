defmodule TelemedApiWeb.AuthController do
  @moduledoc """
  Authentication controller for user registration, login, and token management.
  """
  use TelemedApiWeb, :controller

  alias TelemedCore.Accounts.Impl.AuthService

  @doc """
  Register a new user.
  POST /api/v1/auth/register
  """
  def register(conn, params) do
    # Validate role string, defaulting to "patient" if invalid
    role = case params["role"] do
      role when role in ["patient", "doctor", "admin"] -> role
      _ -> "patient"
    end

    attrs = %{
      email: params["email"],
      password: params["password"],
      first_name: params["first_name"],
      last_name: params["last_name"],
      phone: params["phone"],
      role: role
    }

    case AuthService.register(attrs) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> json(%{
          data: %{
            id: user.id,
            email: user.email,
            role: user.role,
            first_name: user.first_name,
            last_name: user.last_name
          }
        })

      {:error, %Ash.Error.Invalid{} = error} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          error: "Validation failed",
          details: format_ash_errors(error)
        })

      {:error, %Ash.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          error: "Validation failed",
          details: format_changeset_errors(changeset)
        })

      {:error, reason} when is_atom(reason) ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: to_string(reason)})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "An error occurred", details: inspect(reason)})
    end
  end

  @doc """
  Login with email and password.
  POST /api/v1/auth/login
  """
  def login(conn, params) do
    email = params["email"]
    password = params["password"]

    opts = [
      ip_address: to_string(:inet_parse.ntoa(conn.remote_ip)),
      user_agent: get_req_header(conn, "user-agent") |> List.first()
    ]

    case AuthService.login(email, password, opts) do
      {:ok, user, access_token, refresh_token, _session} ->
        conn
        |> put_status(:ok)
        |> json(%{
          data: %{
            user: %{
              id: user.id,
              email: user.email,
              role: user.role,
              first_name: user.first_name,
              last_name: user.last_name
            },
            tokens: %{
              access_token: access_token,
              refresh_token: refresh_token,
              token_type: "Bearer"
            }
          }
        })

      {:error, :user_not_found} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{
          error: "Invalid email or password",
          message: "User not found. Please register at POST /api/v1/auth/register"
        })

      {:error, :invalid_password} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid email or password"})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: to_string(reason)})
    end
  end

  @doc """
  Refresh access token using refresh token.
  POST /api/v1/auth/refresh
  """
  def refresh(conn, params) do
    refresh_token = params["refresh_token"]

    case AuthService.refresh_token(refresh_token) do
      {:ok, user, access_token} ->
        conn
        |> put_status(:ok)
        |> json(%{
          data: %{
            user: %{
              id: user.id,
              email: user.email,
              role: user.role
            },
            tokens: %{
              access_token: access_token,
              token_type: "Bearer"
            }
          }
        })

      {:error, :session_not_found} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid refresh token"})

      {:error, :session_expired} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Refresh token expired"})

      {:error, :session_revoked} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Refresh token revoked"})

      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: to_string(reason)})
    end
  end

  @doc """
  Get current user information.
  GET /api/v1/auth/me
  """
  def me(conn, _params) do
    user = conn.assigns.current_user

    conn
    |> put_status(:ok)
    |> json(%{
      data: %{
        id: user.id,
        email: user.email,
        role: user.role,
        first_name: user.first_name,
        last_name: user.last_name,
        phone: user.phone,
        email_verified: user.email_verified,
        phone_verified: user.phone_verified
      }
    })
  end

  @doc """
  Logout (revoke session).
  POST /api/v1/auth/logout
  """
  def logout(conn, params) do
    session_id = params["session_id"] || conn.assigns[:session_id]

    case AuthService.revoke_session(session_id) do
      {:ok, _session} ->
        conn
        |> put_status(:ok)
        |> json(%{message: "Logged out successfully"})

      {:error, _reason} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Session not found"})
    end
  end

  # Helper functions

  defp format_ash_errors(%Ash.Error.Invalid{errors: errors}) do
    errors
    |> Enum.map(fn error ->
      # Extract field from error struct - Ash errors have a :field key
      field = Map.get(error, :field, :base)

      # Get the error message and clean up breadcrumbs
      message = Exception.message(error)
      |> clean_error_message()

      %{
        field: to_string(field),
        message: message
      }
    end)
  end

  defp clean_error_message(message) do
    # Remove breadcrumbs prefix if present
    message
    |> String.split("\n")
    |> Enum.reject(&String.starts_with?(&1, "Bread Crumbs:"))
    |> Enum.reject(&String.starts_with?(&1, "  >"))
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" ")
  end

  defp format_changeset_errors(changeset) do
    changeset.errors
    |> Enum.map(fn error ->
      %{
        field: to_string(error.field || :base),
        message: error.message
      }
    end)
  end
end
