import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :gestalt, Gestalt.Repo,
  database: Path.expand("../gestalt_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :gestalt, GestaltWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "amtG+byvPAglm0ZFs1/CZhP/0ZHRH0OS6bGUS9jCp7bhwG85dH/x19p2tPCX6bjy",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
