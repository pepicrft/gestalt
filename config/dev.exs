import Config

# Configure your database
config :gestalt, Gestalt.Repo,
  # For development, we disable any cache and enable
  # debugging and code reloading.
  database: Path.expand("../gestalt_dev.db", __DIR__),
  pool_size: 5,
  stacktrace: true,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  show_sensitive_data_on_connection_error: true

config :gestalt, GestaltWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "aJKGA7EHueJ5kxOA034Sf4COmnIS74p7BI9JCyD/uVLPFkEE+E3vgz+Y9GVmpSPf"

# Enable dev routes for health checks
config :gestalt, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :default_formatter, format: "[$level] $message\n"

# Initialize plugs at runtime for faster development compilation
# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :plug_init_mode, :runtime
config :phoenix, :stacktrace_depth, 20
