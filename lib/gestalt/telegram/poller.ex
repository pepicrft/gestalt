defmodule Gestalt.Telegram.Poller do
  @moduledoc """
  GenServer that polls for Telegram updates using long polling.

  This process continuously fetches updates from the Telegram API and
  processes incoming messages. It filters messages to only allow
  configured users.
  """

  use GenServer

  alias Gestalt.Conversation.Server, as: ConversationServer
  alias Gestalt.Conversation.Supervisor, as: ConversationSupervisor
  alias Gestalt.Telegram.Client

  require Logger

  @poll_timeout 30
  @error_backoff 5_000

  # Client API

  @doc """
  Starts the Telegram poller.

  ## Options
    - `:name` - Process name (defaults to `__MODULE__`)
    - `:allowed_users` - List of allowed Telegram user IDs
    - `:error_backoff` - Backoff time in ms after errors (default: 5000)
  """
  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    state = %{
      offset: nil,
      allowed_users: Keyword.get(opts, :allowed_users, allowed_users()),
      error_backoff: Keyword.get(opts, :error_backoff, @error_backoff),
      auto_poll: Keyword.get(opts, :auto_poll, true)
    }

    if state.auto_poll do
      {:ok, state, {:continue, :poll}}
    else
      {:ok, state}
    end
  end

  @doc """
  Triggers a single poll cycle. Used for testing.
  """
  def poll(server \\ __MODULE__) do
    GenServer.call(server, :poll)
  end

  @impl true
  def handle_call(:poll, _from, state) do
    state = poll_and_process(state)
    {:reply, :ok, state}
  end

  @impl true
  def handle_continue(:poll, state) do
    state = poll_and_process(state)
    {:noreply, state, {:continue, :poll}}
  end

  @impl true
  def handle_info(:poll, state) do
    state = poll_and_process(state)
    {:noreply, state, {:continue, :poll}}
  end

  # Private Functions

  defp poll_and_process(state) do
    case Client.get_updates(offset: state.offset, timeout: @poll_timeout) do
      {:ok, []} ->
        state

      {:ok, updates} ->
        process_updates(updates, state.allowed_users)
        new_offset = get_next_offset(updates)
        %{state | offset: new_offset}

      {:error, reason} ->
        Logger.error("Failed to fetch Telegram updates: #{inspect(reason)}")
        Process.sleep(state.error_backoff)
        state
    end
  end

  defp process_updates(updates, allowed_users) do
    Enum.each(updates, fn update ->
      process_update(update, allowed_users)
    end)
  end

  defp process_update(%{"message" => message}, allowed_users) do
    user_id = get_in(message, ["from", "id"])
    chat_id = get_in(message, ["chat", "id"])
    text = message["text"]

    cond do
      user_id == nil ->
        Logger.debug("Ignoring message without user_id")

      allowed_users != [] and user_id not in allowed_users ->
        Logger.warning("Ignoring message from unauthorized user: #{user_id}")

      text == nil ->
        Logger.debug("Ignoring non-text message")

      true ->
        handle_message(chat_id, user_id, text)
    end
  end

  defp process_update(_update, _allowed_users) do
    :ok
  end

  defp handle_message(chat_id, user_id, text) do
    Logger.info("Received message from user #{user_id}: #{text}")

    # Ensure conversation server is running
    case ConversationSupervisor.ensure_conversation(chat_id, user_id) do
      {:ok, _pid} ->
        # Send message to conversation server (handles LLM and response)
        ConversationServer.send_message(chat_id, text)

      {:error, reason} ->
        Logger.error("Failed to start conversation: #{inspect(reason)}")

        Client.send_message(
          chat_id,
          "Sorry, I'm having trouble starting our conversation. Please try again."
        )
    end
  end

  defp get_next_offset(updates) do
    updates
    |> List.last()
    |> Map.get("update_id")
    |> Kernel.+(1)
  end

  defp allowed_users do
    Application.get_env(:gestalt, :telegram)[:allowed_users] || []
  end
end
