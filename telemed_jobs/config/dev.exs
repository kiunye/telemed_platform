import Config

# Disable Oban in dev (or enable for testing)
config :telemed_jobs, Oban, queues: false
