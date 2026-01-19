# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :telemed_admin,
  generators: [timestamp_type: :utc_datetime]

# Configure Ecto repositories (for telemed_core dependency)
config :telemed_core, ecto_repos: [TelemedCore.Repo]

# Configure database connection for TelemedCore.Repo
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

# Configures the endpoint
config :telemed_admin, TelemedAdminWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: TelemedAdminWeb.ErrorHTML, json: TelemedAdminWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: TelemedAdmin.PubSub,
  live_view: [signing_salt: "mmWqQl23"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :telemed_admin, TelemedAdmin.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  telemed_admin: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  telemed_admin: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
