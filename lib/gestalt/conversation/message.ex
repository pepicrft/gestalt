defmodule Gestalt.Conversation.Message do
  @moduledoc """
  Ecto schema for messages within a conversation.

  Messages track the conversation history between the user and the AI assistant.
  Each message has a role (user or assistant) and content.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Gestalt.Conversation
  alias Gestalt.Repo

  @type t :: %__MODULE__{
          id: integer() | nil,
          conversation_id: integer(),
          conversation: Conversation.t() | Ecto.Association.NotLoaded.t(),
          role: String.t(),
          content: String.t(),
          inserted_at: DateTime.t() | nil
        }

  @roles ~w(user assistant system)

  schema "messages" do
    field :role, :string
    field :content, :string

    belongs_to :conversation, Conversation

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Creates a changeset for a new message.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:conversation_id, :role, :content])
    |> validate_required([:conversation_id, :role, :content])
    |> validate_inclusion(:role, @roles)
    |> foreign_key_constraint(:conversation_id)
  end

  @doc """
  Creates a new message in a conversation.
  """
  @spec create(Conversation.t(), String.t(), String.t()) ::
          {:ok, t()} | {:error, Ecto.Changeset.t()}
  def create(%Conversation{id: conversation_id}, role, content) do
    %__MODULE__{}
    |> changeset(%{conversation_id: conversation_id, role: role, content: content})
    |> Repo.insert()
  end
end
