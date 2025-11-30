defmodule Gestalt.Conversation do
  @moduledoc """
  Ecto schema for conversations.

  A conversation represents a persistent chat session with a Telegram user.
  Each user has one active conversation at a time, identified by their chat ID.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Gestalt.Conversation.Message
  alias Gestalt.Repo

  @type t :: %__MODULE__{
          id: integer() | nil,
          telegram_chat_id: integer(),
          telegram_user_id: integer(),
          state: String.t(),
          messages: [Message.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @states ~w(active archived)

  schema "conversations" do
    field :telegram_chat_id, :integer
    field :telegram_user_id, :integer
    field :state, :string, default: "active"

    has_many :messages, Message

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for a new conversation.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:telegram_chat_id, :telegram_user_id, :state])
    |> validate_required([:telegram_chat_id, :telegram_user_id])
    |> validate_inclusion(:state, @states)
    |> unique_constraint(:telegram_chat_id)
  end

  @doc """
  Finds or creates a conversation for a given Telegram chat.
  """
  @spec find_or_create(integer(), integer()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def find_or_create(telegram_chat_id, telegram_user_id) do
    case Repo.get_by(__MODULE__, telegram_chat_id: telegram_chat_id) do
      nil ->
        %__MODULE__{}
        |> changeset(%{telegram_chat_id: telegram_chat_id, telegram_user_id: telegram_user_id})
        |> Repo.insert()

      conversation ->
        {:ok, conversation}
    end
  end

  @doc """
  Gets a conversation by chat ID with messages preloaded.
  """
  @spec get_with_messages(integer()) :: t() | nil
  def get_with_messages(telegram_chat_id) do
    __MODULE__
    |> where([c], c.telegram_chat_id == ^telegram_chat_id)
    |> preload(:messages)
    |> Repo.one()
  end

  @doc """
  Gets the recent messages for a conversation, ordered by creation time.
  """
  @spec get_recent_messages(t(), integer()) :: [Message.t()]
  def get_recent_messages(%__MODULE__{id: id}, limit \\ 50) do
    Message
    |> where([m], m.conversation_id == ^id)
    |> order_by([m], desc: m.id)
    |> limit(^limit)
    |> Repo.all()
    |> Enum.reverse()
  end
end
