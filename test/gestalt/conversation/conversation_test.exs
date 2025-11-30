defmodule Gestalt.ConversationTest do
  # async: false required for SQLite (single writer)
  use Gestalt.DataCase, async: false

  alias Gestalt.Conversation
  alias Gestalt.Conversation.Message

  # Generate unique IDs to avoid conflicts between async tests
  defp unique_chat_id, do: System.unique_integer([:positive])

  describe "changeset/2" do
    test "valid changeset with required fields" do
      attrs = %{telegram_chat_id: 123, telegram_user_id: 456}
      changeset = Conversation.changeset(%Conversation{}, attrs)

      assert changeset.valid?
    end

    test "invalid without telegram_chat_id" do
      attrs = %{telegram_user_id: 456}
      changeset = Conversation.changeset(%Conversation{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).telegram_chat_id
    end

    test "invalid without telegram_user_id" do
      attrs = %{telegram_chat_id: 123}
      changeset = Conversation.changeset(%Conversation{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).telegram_user_id
    end

    test "validates state inclusion" do
      attrs = %{telegram_chat_id: 123, telegram_user_id: 456, state: "invalid"}
      changeset = Conversation.changeset(%Conversation{}, attrs)

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).state
    end

    test "accepts valid states" do
      for state <- ["active", "archived"] do
        attrs = %{telegram_chat_id: 123, telegram_user_id: 456, state: state}
        changeset = Conversation.changeset(%Conversation{}, attrs)

        assert changeset.valid?
      end
    end
  end

  describe "find_or_create/2" do
    test "creates a new conversation when none exists" do
      chat_id = unique_chat_id()
      assert {:ok, conversation} = Conversation.find_or_create(chat_id, 456)

      assert conversation.telegram_chat_id == chat_id
      assert conversation.telegram_user_id == 456
      assert conversation.state == "active"
      assert conversation.id != nil
    end

    test "returns existing conversation if one exists" do
      chat_id = unique_chat_id()
      {:ok, original} = Conversation.find_or_create(chat_id, 456)
      {:ok, found} = Conversation.find_or_create(chat_id, 789)

      assert original.id == found.id
    end

    test "enforces unique telegram_chat_id" do
      chat_id = unique_chat_id()
      {:ok, _} = Conversation.find_or_create(chat_id, 456)

      # Trying to insert directly should fail
      changeset =
        Conversation.changeset(%Conversation{}, %{
          telegram_chat_id: chat_id,
          telegram_user_id: 789
        })

      assert {:error, changeset} = Repo.insert(changeset)
      assert "has already been taken" in errors_on(changeset).telegram_chat_id
    end
  end

  describe "get_with_messages/1" do
    test "returns conversation with messages preloaded" do
      chat_id = unique_chat_id()
      {:ok, conversation} = Conversation.find_or_create(chat_id, 456)
      {:ok, _} = Message.create(conversation, "user", "Hello")
      {:ok, _} = Message.create(conversation, "assistant", "Hi there!")

      loaded = Conversation.get_with_messages(chat_id)

      assert loaded.id == conversation.id
      assert length(loaded.messages) == 2
    end

    test "returns nil when conversation doesn't exist" do
      assert Conversation.get_with_messages(unique_chat_id()) == nil
    end
  end

  describe "get_recent_messages/2" do
    test "returns messages in chronological order" do
      chat_id = unique_chat_id()
      {:ok, conversation} = Conversation.find_or_create(chat_id, 456)
      {:ok, _msg1} = Message.create(conversation, "user", "First")
      {:ok, _msg2} = Message.create(conversation, "assistant", "Second")
      {:ok, _msg3} = Message.create(conversation, "user", "Third")

      messages = Conversation.get_recent_messages(conversation)

      assert length(messages) == 3
      assert [first, second, third] = messages
      # Verify order by content since IDs are sequential
      assert first.content == "First"
      assert second.content == "Second"
      assert third.content == "Third"
    end

    test "respects limit parameter" do
      chat_id = unique_chat_id()
      {:ok, conversation} = Conversation.find_or_create(chat_id, 456)

      for i <- 1..10 do
        Message.create(conversation, "user", "Message #{i}")
      end

      messages = Conversation.get_recent_messages(conversation, 5)

      assert length(messages) == 5
    end
  end
end
