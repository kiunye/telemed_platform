import Config

# Oban configuration
config :telemed_jobs, Oban,
  repo: TelemedCore.Repo,
  queues: [notifications: 10, integrations: 5, webhooks: 5]

# Import environment specific config
import_config "#{config_env()}.exs"
