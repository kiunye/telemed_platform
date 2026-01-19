import Config

# Configure your database
config :telemed_core, TelemedCore.Repo,
  database: System.get_env("POSTGRES_DB", "telemed_dev"),
  username: System.get_env("POSTGRES_USER", "telemed"),
  password: System.get_env("POSTGRES_PASSWORD", "telemed_dev_password"),
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  port: String.to_integer(System.get_env("POSTGRES_PORT", "5432")),
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  log: :info,
  parameters: [client_encoding: "UTF8"]
