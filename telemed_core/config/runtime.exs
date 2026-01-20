import Config

# This file is responsible for configuring your application
# at runtime. It is read after dependencies are compiled.

# Database configuration from environment variables
if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") == "true", do: [:inet6], else: []

  config :telemed_core, TelemedCore.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6
end

# JWT configuration
config :telemed_core,
       :jwt_secret_key,
       System.get_env("JWT_SECRET_KEY", "default-dev-secret-key-change-in-production")
