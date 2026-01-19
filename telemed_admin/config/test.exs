import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :telemed_admin, TelemedAdminWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "nKvO2SqDF9F5m+S6nT+A7SGeUHifvxaEreyFVPPae/Zl7jFgQ2yvC7LY0uSS9J9p",
  server: false

# In test we don't send emails
config :telemed_admin, TelemedAdmin.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Configure database for tests
config :telemed_core, TelemedCore.Repo,
  database: System.get_env("POSTGRES_DB", "telemed_test"),
  username: System.get_env("POSTGRES_USER", "telemed"),
  password: System.get_env("POSTGRES_PASSWORD", "telemed_dev_password"),
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  port: String.to_integer(System.get_env("POSTGRES_PORT", "5432")),
  pool_size: 10
