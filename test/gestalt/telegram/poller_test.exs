defmodule Gestalt.Telegram.PollerTest do
  use ExUnit.Case, async: true

  import Mimic

  alias Gestalt.Conversation.Server, as: ConversationServer
  alias Gestalt.Conversation.Supervisor, as: ConversationSupervisor
  alias Gestalt.Telegram.Client
  alias Gestalt.Telegram.Poller

  setup :set_mimic_private

  defp start_poller(context, opts) do
    name = :"poller_#{context.test}"

    default_opts = [
      name: name,
      auto_poll: false,
      error_backoff: 0
    ]

    {:ok, pid} = Poller.start_link(Keyword.merge(default_opts, opts))

    # Allow the GenServer process to use mocks from the test process
    allow(Client, self(), pid)
    allow(ConversationSupervisor, self(), pid)
    allow(ConversationServer, self(), pid)

    %{poller: pid, poller_name: name}
  end

  describe "poll/1" do
    test "processes messages from allowed users and routes to conversation", context do
      test_pid = self()
      %{poller_name: name} = start_poller(context, allowed_users: [42])

      stub(Client, :get_updates, fn _opts ->
        {:ok,
         [
           %{
             "update_id" => 123,
             "message" => %{
               "from" => %{"id" => 42},
               "chat" => %{"id" => 42},
               "text" => "hello"
             }
           }
         ]}
      end)

      expect(ConversationSupervisor, :ensure_conversation, fn chat_id, user_id ->
        send(test_pid, {:ensure_conversation, chat_id, user_id})
        {:ok, self()}
      end)

      expect(ConversationServer, :send_message, fn chat_id, text ->
        send(test_pid, {:send_message, chat_id, text})
        :ok
      end)

      Poller.poll(name)

      assert_receive {:ensure_conversation, 42, 42}
      assert_receive {:send_message, 42, "hello"}
    end

    test "ignores messages from unauthorized users", context do
      %{poller_name: name} = start_poller(context, allowed_users: [42])

      stub(Client, :get_updates, fn _opts ->
        {:ok,
         [
           %{
             "update_id" => 123,
             "message" => %{
               "from" => %{"id" => 999},
               "chat" => %{"id" => 999},
               "text" => "hello"
             }
           }
         ]}
      end)

      reject(&ConversationSupervisor.ensure_conversation/2)

      Poller.poll(name)
    end

    test "allows all users when allowed_users is empty", context do
      test_pid = self()
      %{poller_name: name} = start_poller(context, allowed_users: [])

      stub(Client, :get_updates, fn _opts ->
        {:ok,
         [
           %{
             "update_id" => 123,
             "message" => %{
               "from" => %{"id" => 999},
               "chat" => %{"id" => 999},
               "text" => "hello"
             }
           }
         ]}
      end)

      expect(ConversationSupervisor, :ensure_conversation, fn chat_id, user_id ->
        send(test_pid, {:ensure_conversation, chat_id, user_id})
        {:ok, self()}
      end)

      expect(ConversationServer, :send_message, fn chat_id, text ->
        send(test_pid, {:send_message, chat_id, text})
        :ok
      end)

      Poller.poll(name)

      assert_receive {:ensure_conversation, 999, 999}
      assert_receive {:send_message, 999, "hello"}
    end

    test "sends error message when conversation fails to start", context do
      test_pid = self()
      %{poller_name: name} = start_poller(context, allowed_users: [42])

      stub(Client, :get_updates, fn _opts ->
        {:ok,
         [
           %{
             "update_id" => 123,
             "message" => %{
               "from" => %{"id" => 42},
               "chat" => %{"id" => 42},
               "text" => "hello"
             }
           }
         ]}
      end)

      expect(ConversationSupervisor, :ensure_conversation, fn _chat_id, _user_id ->
        {:error, :some_error}
      end)

      expect(Client, :send_message, fn chat_id, text ->
        send(test_pid, {:error_message, chat_id, text})
        {:ok, %{"message_id" => 1}}
      end)

      Poller.poll(name)

      assert_receive {:error_message, 42, text}
      assert text =~ "Sorry"
    end

    test "handles empty updates", context do
      %{poller_name: name} = start_poller(context, allowed_users: [42])

      stub(Client, :get_updates, fn _opts -> {:ok, []} end)
      reject(&ConversationSupervisor.ensure_conversation/2)

      Poller.poll(name)
    end

    test "handles API errors gracefully", context do
      %{poller_name: name} = start_poller(context, allowed_users: [42])

      stub(Client, :get_updates, fn _opts -> {:error, "Network error"} end)
      reject(&ConversationSupervisor.ensure_conversation/2)

      Poller.poll(name)
    end
  end
end
