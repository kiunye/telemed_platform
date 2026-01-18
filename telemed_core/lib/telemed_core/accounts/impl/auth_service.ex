defmodule TelemedCore.Accounts.Impl.AuthService do
  @moduledoc """
  Authentication service for user registration, login, and session management.

  This is the boundary layer that orchestrates authentication operations.
  """
  alias TelemedCore.Accounts
  alias TelemedCore.Accounts.{User, Credential, Session}
  alias TelemedCore.Accounts.Impl.JWT

  @doc """
  Registers a new user with email and password.
  """
  def register(attrs) do
    with {:ok, user} <- create_user(attrs),
         {:ok, _credential} <- create_credential(user.id, attrs[:password]) do
      {:ok, user}
    end
  end

  @doc """
  Authenticates a user with email and password, returns tokens.
  """
  def login(email, password, opts \\ []) do
    ip_address = Keyword.get(opts, :ip_address)
    user_agent = Keyword.get(opts, :user_agent)

    with {:ok, user} <- find_user_by_email(email),
         {:ok, credential} <- find_credential_by_user_id(user.id),
         :ok <- verify_password(credential, password),
         {:ok, access_token, access_expires_at} <- JWT.generate_access_token(user),
         {:ok, refresh_token, refresh_expires_at} <- JWT.generate_refresh_token(user),
         {:ok, session} <- create_session(user.id, refresh_token, refresh_expires_at, ip_address, user_agent) do
      {:ok, user, access_token, refresh_token, session}
    end
  end

  @doc """
  Refreshes an access token using a refresh token.
  """
  def refresh_token(refresh_token_string) do
    with {:ok, claims} <- JWT.verify_refresh_token(refresh_token_string),
         {:ok, user_id} <- JWT.get_user_id_from_claims(claims),
         {:ok, session} <- find_session_by_token(refresh_token_string),
         :ok <- validate_session(session),
         {:ok, user} <- find_user_by_id(user_id),
         {:ok, access_token, _expires_at} <- JWT.generate_access_token(user) do
      {:ok, user, access_token}
    end
  end

  @doc """
  Revokes a session (logout).
  """
  def revoke_session(session_id) do
    case Ash.get(Session, session_id) do
      {:ok, session} ->
        Session.revoke(session)

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Verifies an access token and returns the user.
  """
  def verify_access_token(token) do
    with {:ok, claims} <- JWT.verify_access_token(token),
         {:ok, user_id} <- JWT.get_user_id_from_claims(claims),
         {:ok, user} <- find_user_by_id(user_id) do
      {:ok, user}
    end
  end

  # Private helper functions

  defp create_user(attrs) do
    User.register(attrs)
  end

  defp create_credential(user_id, password) when is_binary(password) do
    Credential.create_with_password(%{user_id: user_id}, %{password: password})
  end

  defp create_credential(_user_id, _password) do
    {:error, :password_required}
  end

  defp find_user_by_email(email) do
    case Ash.read_one(
           Ash.Query.for_read(User, :read)
           |> Ash.Query.filter(email == ^email)
         ) do
      {:ok, nil} -> {:error, :user_not_found}
      {:ok, user} -> {:ok, user}
      error -> error
    end
  end

  defp find_user_by_id(user_id) do
    case Ash.get(User, user_id) do
      {:ok, user} -> {:ok, user}
      {:error, _} = error -> error
    end
  end

  defp find_credential_by_user_id(user_id) do
    case Ash.read_one(
           Ash.Query.for_read(Credential, :read)
           |> Ash.Query.filter(user_id == ^user_id)
         ) do
      {:ok, nil} -> {:error, :credential_not_found}
      {:ok, credential} -> {:ok, credential}
      error -> error
    end
  end

  defp verify_password(credential, password) do
    if Bcrypt.verify_pass(password, credential.password_hash) do
      :ok
    else
      {:error, :invalid_password}
    end
  end

  defp create_session(user_id, refresh_token, expires_at, ip_address, user_agent) do
    Session.create_session(
      %{
        user_id: user_id,
        ip_address: ip_address,
        user_agent: user_agent
      },
      %{
        refresh_token: refresh_token,
        expires_at: DateTime.from_unix!(expires_at)
      }
    )
  end

  defp find_session_by_token(refresh_token) do
    case Ash.read_one(
           Ash.Query.for_read(Session, :read)
           |> Ash.Query.filter(refresh_token == ^refresh_token)
         ) do
      {:ok, nil} -> {:error, :session_not_found}
      {:ok, session} -> {:ok, session}
      error -> error
    end
  end

  defp validate_session(session) do
    cond do
      session.revoked_at != nil ->
        {:error, :session_revoked}

      DateTime.compare(session.expires_at, DateTime.utc_now()) == :lt ->
        {:error, :session_expired}

      true ->
        :ok
    end
  end

end
