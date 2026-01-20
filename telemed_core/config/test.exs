import Config

# Configure your database for tests
config :telemed_core, TelemedCore.Repo,
  database: System.get_env("POSTGRES_DB", "telemed_test"),
  username: System.get_env("POSTGRES_USER", "telemed"),
  password: System.get_env("POSTGRES_PASSWORD", "telemed_dev_password"),
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  port: String.to_integer(System.get_env("POSTGRES_PORT", "5432")),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  parameters: [client_encoding: "utf8"]
