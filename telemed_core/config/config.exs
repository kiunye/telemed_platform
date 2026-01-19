import Config

# Configure Ecto repositories
config :telemed_core, ecto_repos: [TelemedCore.Repo]

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded and the deps function in the mix.exs file
# will be used instead.

config :telemed_core, TelemedCore.Repo,
  database: System.get_env("POSTGRES_DB", "telemed_dev"),
  username: System.get_env("POSTGRES_USER", "telemed"),
  password: System.get_env("POSTGRES_PASSWORD", "telemed_dev_password"),
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  port: String.to_integer(System.get_env("POSTGRES_PORT", "5432")),
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Ash configuration
config :telemed_core,
  ash_domains: [TelemedCore.Accounts, TelemedCore.Audit, TelemedCore.Appointments]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
