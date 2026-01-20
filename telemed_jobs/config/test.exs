import Config

# Use testing mode for Oban
config :telemed_jobs, Oban, queues: false, plugins: false
