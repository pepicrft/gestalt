defmodule Gestalt.Telegram.PollerTest do
  use ExUnit.Case, async: true

  import Mimic

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

    %{poller: pid, poller_name: name}
  end

  describe "poll/1" do
    test "processes messages from allowed users and sends ack", context do
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

      expect(Client, :send_message, fn chat_id, text ->
        send(test_pid, {:send_message, chat_id, text})
        {:ok, %{"message_id" => 1}}
      end)

      Poller.poll(name)

      assert_receive {:send_message, 42, "Ack: hello"}
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

      reject(&Client.send_message/2)

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

      expect(Client, :send_message, fn chat_id, text ->
        send(test_pid, {:send_message, chat_id, text})
        {:ok, %{"message_id" => 1}}
      end)

      Poller.poll(name)

      assert_receive {:send_message, 999, "Ack: hello"}
    end

    test "handles empty updates", context do
      %{poller_name: name} = start_poller(context, allowed_users: [42])

      stub(Client, :get_updates, fn _opts -> {:ok, []} end)
      reject(&Client.send_message/2)

      Poller.poll(name)
    end

    test "handles API errors gracefully", context do
      %{poller_name: name} = start_poller(context, allowed_users: [42])

      stub(Client, :get_updates, fn _opts -> {:error, "Network error"} end)
      reject(&Client.send_message/2)

      Poller.poll(name)
    end
  end
end
