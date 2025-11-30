import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/gestalt start
if System.get_env("PHX_SERVER") do
  config :gestalt, GestaltWeb.Endpoint, server: true
end

config :gestalt, GestaltWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

# Telegram configuration (required)
if config_env() != :test do
  telegram_token = System.get_env("TELEGRAM_BOT_TOKEN")

  allowed_users =
    case System.get_env("TELEGRAM_ALLOWED_USERS") do
      nil -> []
      users -> users |> String.split(",") |> Enum.map(&String.to_integer/1)
    end

  # Coding agent configuration
  coding_agent =
    case System.get_env("GESTALT_CODING_AGENT", "claude_code") do
      "claude_code" -> :claude_code
      "codex" -> :codex
      other -> raise "Unknown coding agent: #{other}. Use 'claude_code' or 'codex'."
    end

  # Anthropic API configuration for LLM
  config :gestalt, :anthropic, api_key: System.get_env("ANTHROPIC_API_KEY")

  # API keys for coding agents
  config :gestalt, :api_keys,
    anthropic: System.get_env("ANTHROPIC_API_KEY"),
    openai: System.get_env("OPENAI_API_KEY")

  config :gestalt, :coding_agent, coding_agent

  config :gestalt, :telegram,
    bot_token: telegram_token,
    allowed_users: allowed_users
end

if config_env() == :prod do
  database_path =
    System.get_env("DATABASE_PATH") ||
      raise """
      environment variable DATABASE_PATH is missing.
      For example: /etc/gestalt/gestalt.db
      """

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "localhost"

  config :gestalt, Gestalt.Repo,
    database: database_path,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5")

  config :gestalt, GestaltWeb.Endpoint,
    url: [host: host],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base
end
