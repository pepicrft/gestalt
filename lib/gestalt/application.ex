defmodule Gestalt.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        GestaltWeb.Telemetry,
        Gestalt.Repo,
        {Ecto.Migrator,
         repos: Application.fetch_env!(:gestalt, :ecto_repos), skip: skip_migrations?()},
        {DNSCluster, query: Application.get_env(:gestalt, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Gestalt.PubSub},
        # Conversation management
        {Registry, keys: :unique, name: Gestalt.Conversation.Registry},
        Gestalt.Conversation.Supervisor,
        # Start to serve requests, typically the last entry
        GestaltWeb.Endpoint
      ] ++ telegram_children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Gestalt.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GestaltWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations? do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") == nil
  end

  defp telegram_children do
    telegram_config = Application.get_env(:gestalt, :telegram)

    if telegram_config[:bot_token] do
      [Gestalt.Telegram.Poller]
    else
      []
    end
  end
end
