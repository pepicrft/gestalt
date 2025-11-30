defmodule Gestalt.Conversation.MessageTest do
  # async: false required for SQLite (single writer)
  use Gestalt.DataCase, async: false

  alias Gestalt.Conversation
  alias Gestalt.Conversation.Message

  setup do
    chat_id = System.unique_integer([:positive])
    {:ok, conversation} = Conversation.find_or_create(chat_id, 456)
    {:ok, conversation: conversation}
  end

  describe "changeset/2" do
    test "valid changeset with required fields", %{conversation: conversation} do
      attrs = %{conversation_id: conversation.id, role: "user", content: "Hello"}
      changeset = Message.changeset(%Message{}, attrs)

      assert changeset.valid?
    end

    test "invalid without conversation_id" do
      attrs = %{role: "user", content: "Hello"}
      changeset = Message.changeset(%Message{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).conversation_id
    end

    test "invalid without role" do
      attrs = %{conversation_id: 1, content: "Hello"}
      changeset = Message.changeset(%Message{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).role
    end

    test "invalid without content" do
      attrs = %{conversation_id: 1, role: "user"}
      changeset = Message.changeset(%Message{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).content
    end

    test "validates role inclusion" do
      attrs = %{conversation_id: 1, role: "invalid", content: "Hello"}
      changeset = Message.changeset(%Message{}, attrs)

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).role
    end

    test "accepts valid roles" do
      for role <- ["user", "assistant", "system"] do
        attrs = %{conversation_id: 1, role: role, content: "Hello"}
        changeset = Message.changeset(%Message{}, attrs)

        assert changeset.valid?
      end
    end
  end

  describe "create/3" do
    test "creates a message for a conversation", %{conversation: conversation} do
      assert {:ok, message} = Message.create(conversation, "user", "Hello world")

      assert message.conversation_id == conversation.id
      assert message.role == "user"
      assert message.content == "Hello world"
      assert message.inserted_at != nil
    end

    test "creates assistant messages", %{conversation: conversation} do
      assert {:ok, message} = Message.create(conversation, "assistant", "Hi there!")

      assert message.role == "assistant"
    end

    test "creates system messages", %{conversation: conversation} do
      assert {:ok, message} = Message.create(conversation, "system", "System prompt")

      assert message.role == "system"
    end
  end
end
