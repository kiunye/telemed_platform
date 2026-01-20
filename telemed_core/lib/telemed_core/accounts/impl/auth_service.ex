defmodule TelemedCore.Accounts.Impl.AuthService do
  @moduledoc """
  Authentication service for user registration, login, and session management.

  This is the boundary layer that orchestrates authentication operations.
  """
  import Ash.Expr
  require Ash.Query
  require Logger
  alias TelemedCore.Accounts.{User, Credential, Session}
  alias TelemedCore.Accounts.Impl.JWT

  @doc """
  Registers a new user with email and password.
  """
  def register(attrs) do
    sanitized_attrs = sanitize_registration_attrs(attrs)

    with {:ok, user} <- create_user_ecto(sanitized_attrs),
         {:ok, _credential} <- create_credential_ecto(user.id, sanitized_attrs[:password]) do
      {:ok, user}
    end
  end

  defp create_user_ecto(attrs) do
    now = DateTime.utc_now()

    user = %TelemedCore.Accounts.User{
      email: attrs[:email],
      first_name: sanitize_string(attrs[:first_name]),
      last_name: sanitize_string(attrs[:last_name]),
      phone: sanitize_string(attrs[:phone]),
      role: attrs[:role] || "patient",
      email_verified: false,
      phone_verified: false,
      version: 1,
      inserted_at: now,
      updated_at: now
    }

    sql = """
    INSERT INTO users (id, version, role, email, first_name, last_name, phone, email_verified, phone_verified, inserted_at, updated_at)
    VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
    RETURNING id
    """

    case TelemedCore.Repo.query(sql, [
           user.version,
           user.role,
           user.email,
           user.first_name,
           user.last_name,
           user.phone,
           user.email_verified,
           user.phone_verified,
           user.inserted_at,
           user.updated_at
         ]) do
      {:ok, result} ->
        id = List.first(result.rows) |> List.first()
        {:ok, %{user | id: id}}

      {:error, error} ->
        {:error, error}
    end
  end

  defp create_credential_ecto(user_id, password) when is_binary(password) do
    hash = Bcrypt.hash_pwd_salt(password)

    sql = """
    INSERT INTO credentials (id, user_id, password_hash, inserted_at, updated_at)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING id
    """

    case TelemedCore.Repo.query(sql, [
           UUID.uuid4(),
           user_id,
           hash,
           DateTime.utc_now(),
           DateTime.utc_now()
         ]) do
      {:ok, result} -> {:ok, %{id: List.first(result.rows)}}
      {:error, error} -> {:error, error}
    end
  end

  defp create_credential_ecto(_user_id, _password) do
    {:error, :password_required}
  end

  defp sanitize_registration_attrs(attrs) do
    attrs
    |> Map.update(:first_name, nil, &sanitize_string/1)
    |> Map.update(:last_name, nil, &sanitize_string/1)
    |> Map.update(:phone, nil, &sanitize_string/1)
    |> Map.update(:email, nil, &sanitize_string/1)
    |> Map.update(:password, nil, &sanitize_string/1)
  end

  defp sanitize_string(nil), do: nil

  defp sanitize_string(value) when is_binary(value) do
    cleaned = String.replace(value, ~r/[\x00-\x08\x0b\x0c\x0e-\x1f\x80-\x9f]/, "")

    case :unicode.characters_to_binary(cleaned, :utf8, :utf8) do
      {:error, result, _} -> result
      {:incomplete, result, _} -> result
      result when is_binary(result) -> result
      _ -> cleaned
    end
  end

  defp sanitize_string(_), do: nil

  @doc """
  Authenticates a user with email and password, returns tokens.
  """
  def login(email, password, opts \\ []) do
    ip_address = Keyword.get(opts, :ip_address)
    user_agent = Keyword.get(opts, :user_agent)

    with {:ok, user} <- find_user_by_email(email),
         {:ok, credential} <- find_credential_by_user_id(user.id),
         :ok <- verify_password(credential, password),
         {:ok, access_token, _access_expires_at} <- JWT.generate_access_token(user),
         {:ok, refresh_token, refresh_expires_at} <- JWT.generate_refresh_token(user),
         {:ok, session} <-
           create_session(user.id, refresh_token, refresh_expires_at, ip_address, user_agent) do
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
        session
        |> Ash.Changeset.for_update(:revoke, %{})
        |> Ash.update()

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

  defp find_user_by_email(email) do
    case Ash.read_one(
           Ash.Query.for_read(User, :read)
           |> Ash.Query.filter(expr(email == ^email))
         ) do
      {:ok, nil} -> {:error, :user_not_found}
      {:ok, user} -> {:ok, user}
      error -> error
    end
  end

  defp find_user_by_id(user_id) do
    case Ash.read_one(
           Ash.Query.for_read(User, :read)
           |> Ash.Query.filter(expr(id == ^user_id))
         ) do
      {:ok, nil} -> {:error, :user_not_found}
      {:ok, user} -> {:ok, user}
      error -> error
    end
  end

  defp find_credential_by_user_id(user_id) do
    case Ash.read_one(
           Ash.Query.for_read(Credential, :read)
           |> Ash.Query.filter(expr(user_id == ^user_id))
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

  defp create_session(user_id, refresh_token, expires_at_unix, ip_address, user_agent) do
    cond do
      is_nil(refresh_token) ->
        {:error, :invalid_refresh_token}

      is_nil(expires_at_unix) ->
        {:error, :invalid_expires_at}

      true ->
        case DateTime.from_unix(expires_at_unix) do
          {:ok, expires_at} ->
            sql = """
            INSERT INTO sessions (id, user_id, refresh_token, expires_at, ip_address, user_agent, inserted_at, updated_at)
            VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7)
            RETURNING id
            """

            case TelemedCore.Repo.query(sql, [
                   user_id,
                   sanitize_string(refresh_token),
                   expires_at,
                   sanitize_string(ip_address || ""),
                   sanitize_string(user_agent || ""),
                   DateTime.utc_now(),
                   DateTime.utc_now()
                 ]) do
              {:ok, result} ->
                session_id = List.first(result.rows) |> List.first()

                {:ok,
                 %{
                   id: session_id,
                   user_id: user_id,
                   refresh_token: refresh_token,
                   expires_at: expires_at
                 }}

              {:error, error} ->
                {:error, error}
            end

          {:error, _reason} ->
            {:error, :invalid_timestamp}
        end
    end
  end

  defp find_session_by_token(refresh_token) do
    sql = """
    SELECT id, user_id, refresh_token, expires_at, revoked_at, inserted_at, updated_at
    FROM sessions
    WHERE refresh_token = $1
    """

    case TelemedCore.Repo.query(sql, [refresh_token]) do
      {:ok, result} ->
        if result.rows == [] do
          {:error, :session_not_found}
        else
          [id, user_id, _refresh_token, expires_at, revoked_at, inserted_at, updated_at] =
            List.first(result.rows)

          {:ok,
           %{
             id: id,
             user_id: user_id,
             expires_at: expires_at,
             revoked_at: revoked_at,
             inserted_at: inserted_at,
             updated_at: updated_at
           }}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp validate_session(session) do
    cond do
      session.revoked_at != nil ->
        {:error, :session_revoked}

      is_expired?(session.expires_at) ->
        {:error, :session_expired}

      true ->
        :ok
    end
  end

  defp is_expired?(%DateTime{} = expires_at) do
    DateTime.compare(expires_at, DateTime.utc_now()) == :lt
  end

  defp is_expired?(%NaiveDateTime{} = expires_at) do
    # Convert NaiveDateTime to DateTime assuming UTC
    expires_at
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.compare(DateTime.utc_now()) == :lt
  end

  defp is_expired?(_), do: false
end
