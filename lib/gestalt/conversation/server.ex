defmodule Gestalt.Conversation.Server do
  @moduledoc """
  GenServer that manages a single conversation session.

  Each conversation is identified by a Telegram chat ID. The server:
  - Maintains conversation state
  - Persists messages to the database
  - Interfaces with the LLM to generate responses
  - Sends responses back via Telegram
  """

  use GenServer

  alias Gestalt.Conversation
  alias Gestalt.Conversation.Message
  alias Gestalt.LLM.Client, as: LLMClient
  alias Gestalt.Telegram.Client, as: TelegramClient

  require Logger

  @type state :: %{
          conversation: Conversation.t(),
          telegram_chat_id: integer()
        }

  @default_registry Gestalt.Conversation.Registry

  # Client API

  @doc """
  Starts a conversation server for the given chat.

  ## Options
    - `:telegram_chat_id` - Required. The Telegram chat ID.
    - `:telegram_user_id` - Required. The Telegram user ID.
    - `:registry` - Optional. The registry to use (defaults to `Gestalt.Conversation.Registry`).
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    telegram_chat_id = Keyword.fetch!(opts, :telegram_chat_id)
    telegram_user_id = Keyword.fetch!(opts, :telegram_user_id)
    registry = Keyword.get(opts, :registry, @default_registry)

    GenServer.start_link(
      __MODULE__,
      %{telegram_chat_id: telegram_chat_id, telegram_user_id: telegram_user_id},
      name: via_tuple(telegram_chat_id, registry)
    )
  end

  @doc """
  Sends a message to the conversation and gets a response.
  """
  @spec send_message(integer(), String.t(), keyword()) :: :ok
  def send_message(telegram_chat_id, content, opts \\ []) do
    registry = Keyword.get(opts, :registry, @default_registry)
    GenServer.cast(via_tuple(telegram_chat_id, registry), {:message, content})
  end

  @doc """
  Gets the current conversation state.
  """
  @spec get_conversation(integer(), keyword()) :: Conversation.t()
  def get_conversation(telegram_chat_id, opts \\ []) do
    registry = Keyword.get(opts, :registry, @default_registry)
    GenServer.call(via_tuple(telegram_chat_id, registry), :get_conversation)
  end

  @doc """
  Checks if a conversation server is running for the given chat.
  """
  @spec exists?(integer(), keyword()) :: boolean()
  def exists?(telegram_chat_id, opts \\ []) do
    registry = Keyword.get(opts, :registry, @default_registry)

    case Registry.lookup(registry, telegram_chat_id) do
      [] -> false
      _ -> true
    end
  end

  # Server callbacks

  @impl true
  def init(init_arg) do
    {:ok, init_arg, {:continue, :load_conversation}}
  end

  @impl true
  def handle_continue(:load_conversation, state) do
    %{telegram_chat_id: chat_id, telegram_user_id: user_id} = state

    case Conversation.find_or_create(chat_id, user_id) do
      {:ok, conversation} ->
        Logger.info("Conversation loaded",
          conversation_id: conversation.id,
          telegram_chat_id: chat_id
        )

        {:noreply, %{conversation: conversation, telegram_chat_id: chat_id}}

      {:error, reason} ->
        Logger.error("Failed to load conversation",
          telegram_chat_id: chat_id,
          error: inspect(reason)
        )

        {:stop, {:failed_to_load_conversation, reason}, state}
    end
  end

  @impl true
  def handle_cast({:message, content}, state) do
    %{conversation: conversation, telegram_chat_id: chat_id} = state

    # Store the user message
    {:ok, _user_message} = Message.create(conversation, "user", content)

    # Get conversation history for context
    messages = Conversation.get_recent_messages(conversation)

    # Generate response from LLM
    case LLMClient.chat(messages) do
      {:ok, response} ->
        # Store the assistant message
        {:ok, _assistant_message} = Message.create(conversation, "assistant", response)

        # Send response via Telegram
        case TelegramClient.send_message(chat_id, response) do
          {:ok, _} ->
            Logger.debug("Response sent", telegram_chat_id: chat_id)

          {:error, reason} ->
            Logger.error("Failed to send response",
              telegram_chat_id: chat_id,
              error: inspect(reason)
            )
        end

      {:error, reason} ->
        Logger.error("LLM request failed",
          telegram_chat_id: chat_id,
          error: inspect(reason)
        )

        # Send error message to user
        TelegramClient.send_message(
          chat_id,
          "Sorry, I encountered an error processing your message. Please try again."
        )
    end

    {:noreply, state}
  end

  @impl true
  def handle_call(:get_conversation, _from, state) do
    {:reply, state.conversation, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("Conversation server terminating",
      telegram_chat_id: state.telegram_chat_id,
      reason: inspect(reason)
    )

    :ok
  end

  # Private functions

  defp via_tuple(telegram_chat_id, registry) do
    {:via, Registry, {registry, telegram_chat_id}}
  end
end
