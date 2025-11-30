defmodule Gestalt.Conversation.Supervisor do
  @moduledoc """
  DynamicSupervisor for conversation servers.

  Manages the lifecycle of conversation GenServers, with one server per Telegram chat.
  Conversations are started on-demand when a user sends their first message.
  """

  use DynamicSupervisor

  alias Gestalt.Conversation.Server

  require Logger

  @default_registry Gestalt.Conversation.Registry

  @doc """
  Starts the conversation supervisor.

  ## Options
    - `:name` - The name to register the supervisor (defaults to `__MODULE__`).
    - `:registry` - The registry to use for conversations (defaults to `Gestalt.Conversation.Registry`).
  """
  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    DynamicSupervisor.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Starts or returns an existing conversation server for the given chat.
  """
  @spec ensure_conversation(integer(), integer(), keyword()) :: {:ok, pid()} | {:error, term()}
  def ensure_conversation(telegram_chat_id, telegram_user_id, opts \\ []) do
    registry = Keyword.get(opts, :registry, @default_registry)

    if Server.exists?(telegram_chat_id, registry: registry) do
      case Registry.lookup(registry, telegram_chat_id) do
        [{pid, _}] -> {:ok, pid}
        [] -> start_conversation(telegram_chat_id, telegram_user_id, opts)
      end
    else
      start_conversation(telegram_chat_id, telegram_user_id, opts)
    end
  end

  @doc """
  Starts a new conversation server.
  """
  @spec start_conversation(integer(), integer(), keyword()) :: {:ok, pid()} | {:error, term()}
  def start_conversation(telegram_chat_id, telegram_user_id, opts \\ []) do
    supervisor = Keyword.get(opts, :supervisor, __MODULE__)
    registry = Keyword.get(opts, :registry, @default_registry)

    child_spec = {
      Server,
      telegram_chat_id: telegram_chat_id, telegram_user_id: telegram_user_id, registry: registry
    }

    case DynamicSupervisor.start_child(supervisor, child_spec) do
      {:ok, pid} ->
        Logger.info("Started conversation server",
          telegram_chat_id: telegram_chat_id,
          pid: inspect(pid)
        )

        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}

      {:error, reason} = error ->
        Logger.error("Failed to start conversation server",
          telegram_chat_id: telegram_chat_id,
          error: inspect(reason)
        )

        error
    end
  end

  @doc """
  Stops a conversation server.
  """
  @spec stop_conversation(integer(), keyword()) :: :ok | {:error, :not_found}
  def stop_conversation(telegram_chat_id, opts \\ []) do
    supervisor = Keyword.get(opts, :supervisor, __MODULE__)
    registry = Keyword.get(opts, :registry, @default_registry)

    case Registry.lookup(registry, telegram_chat_id) do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(supervisor, pid)

      [] ->
        {:error, :not_found}
    end
  end

  @doc """
  Returns the count of active conversations.
  """
  @spec count(keyword()) :: non_neg_integer()
  def count(opts \\ []) do
    supervisor = Keyword.get(opts, :supervisor, __MODULE__)
    DynamicSupervisor.count_children(supervisor).active
  end
end
