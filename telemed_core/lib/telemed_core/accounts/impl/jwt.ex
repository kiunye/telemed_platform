defmodule TelemedCore.Accounts.Impl.JWT do
  @moduledoc """
  JWT token generation and verification helpers.

  Uses Joken for JWT operations with HS256 algorithm.
  """
  alias Joken.Signer

  @access_token_expiry_hours 24
  @refresh_token_expiry_days 30

  @doc """
  Generates an access token for a user.
  """
  def generate_access_token(user) do
    secret = get_secret_key()
    signer = Signer.create("HS256", secret)

    now = DateTime.utc_now() |> DateTime.to_unix()
    expires_at = now + @access_token_expiry_hours * 3600

    claims = %{
      "sub" => user.id,
      "email" => user.email,
      "role" => to_string(user.role),
      "iat" => now,
      "exp" => expires_at,
      "type" => "access"
    }

    case Joken.generate_and_sign(%{}, claims, signer) do
      {:ok, token, _claims} -> {:ok, token, expires_at}
      error -> error
    end
  end

  @doc """
  Generates a refresh token for a user.
  """
  def generate_refresh_token(user) do
    secret = get_secret_key()
    signer = Signer.create("HS256", secret)

    now = DateTime.utc_now() |> DateTime.to_unix()
    expires_at = now + @refresh_token_expiry_days * 86400

    claims = %{
      "sub" => user.id,
      "iat" => now,
      "exp" => expires_at,
      "type" => "refresh"
    }

    case Joken.generate_and_sign(%{}, claims, signer) do
      {:ok, token, _claims} -> {:ok, token, expires_at}
      error -> error
    end
  end

  @doc """
  Verifies and decodes an access token.
  """
  def verify_access_token(token) do
    secret = get_secret_key()
    signer = Signer.create("HS256", secret)

    case Joken.verify_and_validate(%{}, token, signer) do
      {:ok, claims} ->
        if claims["type"] == "access" do
          {:ok, claims}
        else
          {:error, :invalid_token_type}
        end

      error ->
        error
    end
  end

  @doc """
  Verifies and decodes a refresh token.
  """
  def verify_refresh_token(token) do
    secret = get_secret_key()
    signer = Signer.create("HS256", secret)

    case Joken.verify_and_validate(%{}, token, signer) do
      {:ok, claims} ->
        if claims["type"] == "refresh" do
          {:ok, claims}
        else
          {:error, :invalid_token_type}
        end

      error ->
        error
    end
  end

  @doc """
  Extracts user ID from token claims.
  """
  def get_user_id_from_claims(claims) do
    case Map.get(claims, "sub") do
      nil -> {:error, :missing_user_id}
      user_id -> {:ok, user_id}
    end
  end

  defp get_secret_key do
    Application.get_env(:telemed_core, :jwt_secret_key) ||
      System.get_env("JWT_SECRET_KEY") ||
      raise """
      JWT_SECRET_KEY environment variable is missing.
      Set it in your .env file or config/runtime.exs.
      """
  end
end
