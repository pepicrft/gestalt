defmodule Gestalt.Conversation.SupervisorTest do
  # async: false because we need shared sandbox mode for spawned GenServer processes
  use Gestalt.DataCase, async: false

  alias Gestalt.Conversation.Server
  alias Gestalt.Conversation.Supervisor, as: ConversationSupervisor

  setup do
    # Start test-scoped registry and supervisor with unique names
    test_id = System.unique_integer([:positive])
    registry_name = :"test_registry_#{test_id}"
    supervisor_name = :"test_supervisor_#{test_id}"

    start_supervised!({Registry, keys: :unique, name: registry_name})
    start_supervised!({ConversationSupervisor, name: supervisor_name, registry: registry_name})

    # Generate unique chat IDs for this test
    chat_id1 = test_id * 1000 + 1
    chat_id2 = test_id * 1000 + 2

    {:ok,
     registry: registry_name, supervisor: supervisor_name, chat_id1: chat_id1, chat_id2: chat_id2}
  end

  describe "ensure_conversation/2" do
    test "starts a new conversation server", %{
      registry: registry,
      supervisor: supervisor,
      chat_id1: chat_id
    } do
      assert {:ok, pid} =
               ConversationSupervisor.ensure_conversation(chat_id, 456,
                 registry: registry,
                 supervisor: supervisor
               )

      assert Process.alive?(pid)
      assert Server.exists?(chat_id, registry: registry)
    end

    test "returns existing server if already started", %{
      registry: registry,
      supervisor: supervisor,
      chat_id1: chat_id
    } do
      {:ok, pid1} =
        ConversationSupervisor.ensure_conversation(chat_id, 456,
          registry: registry,
          supervisor: supervisor
        )

      {:ok, pid2} =
        ConversationSupervisor.ensure_conversation(chat_id, 789,
          registry: registry,
          supervisor: supervisor
        )

      assert pid1 == pid2
    end
  end

  describe "start_conversation/2" do
    test "starts a conversation server", %{
      registry: registry,
      supervisor: supervisor,
      chat_id1: chat_id
    } do
      assert {:ok, pid} =
               ConversationSupervisor.start_conversation(chat_id, 456,
                 registry: registry,
                 supervisor: supervisor
               )

      assert Process.alive?(pid)
    end

    test "returns already_started if server exists", %{
      registry: registry,
      supervisor: supervisor,
      chat_id1: chat_id
    } do
      {:ok, pid1} =
        ConversationSupervisor.start_conversation(chat_id, 456,
          registry: registry,
          supervisor: supervisor
        )

      {:ok, pid2} =
        ConversationSupervisor.start_conversation(chat_id, 456,
          registry: registry,
          supervisor: supervisor
        )

      assert pid1 == pid2
    end
  end

  describe "stop_conversation/1" do
    test "stops a running conversation server", %{
      registry: registry,
      supervisor: supervisor,
      chat_id1: chat_id
    } do
      {:ok, pid} =
        ConversationSupervisor.start_conversation(chat_id, 456,
          registry: registry,
          supervisor: supervisor
        )

      assert Process.alive?(pid)

      :ok =
        ConversationSupervisor.stop_conversation(chat_id,
          registry: registry,
          supervisor: supervisor
        )

      refute Process.alive?(pid)
    end

    test "returns error when conversation doesn't exist", %{
      registry: registry,
      supervisor: supervisor
    } do
      assert {:error, :not_found} =
               ConversationSupervisor.stop_conversation(999_999_999,
                 registry: registry,
                 supervisor: supervisor
               )
    end
  end

  describe "count/0" do
    test "returns count of active conversations", %{
      registry: registry,
      supervisor: supervisor,
      chat_id1: chat_id1,
      chat_id2: chat_id2
    } do
      assert ConversationSupervisor.count(supervisor: supervisor) == 0

      {:ok, _} =
        ConversationSupervisor.start_conversation(chat_id1, 456,
          registry: registry,
          supervisor: supervisor
        )

      assert ConversationSupervisor.count(supervisor: supervisor) == 1

      {:ok, _} =
        ConversationSupervisor.start_conversation(chat_id2, 456,
          registry: registry,
          supervisor: supervisor
        )

      assert ConversationSupervisor.count(supervisor: supervisor) == 2
    end
  end
end
