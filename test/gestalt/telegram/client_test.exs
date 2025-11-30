defmodule Gestalt.Telegram.ClientTest do
  use ExUnit.Case, async: true

  import Mimic

  alias Gestalt.Telegram.Client

  setup :set_mimic_private

  describe "get_updates/1" do
    test "returns updates on success" do
      expect(Req, :request, fn opts ->
        assert opts[:method] == :get
        assert opts[:url] == "https://api.telegram.org/bottest-token/getUpdates"
        assert opts[:params] == %{timeout: 30}

        {:ok,
         %Req.Response{
           status: 200,
           body: %{
             "ok" => true,
             "result" => [%{"update_id" => 123, "message" => %{"text" => "hello"}}]
           }
         }}
      end)

      assert {:ok, [%{"update_id" => 123, "message" => %{"text" => "hello"}}]} =
               Client.get_updates(bot_token: "test-token")
    end

    test "returns updates with offset" do
      expect(Req, :request, fn opts ->
        assert opts[:params] == %{timeout: 30, offset: 100}

        {:ok,
         %Req.Response{
           status: 200,
           body: %{"ok" => true, "result" => []}
         }}
      end)

      assert {:ok, []} = Client.get_updates(bot_token: "test-token", offset: 100)
    end

    test "returns error on API failure" do
      expect(Req, :request, fn _opts ->
        {:ok,
         %Req.Response{
           status: 200,
           body: %{"ok" => false, "description" => "Unauthorized"}
         }}
      end)

      assert {:error, "Unauthorized"} = Client.get_updates(bot_token: "test-token")
    end

    test "returns error on HTTP error" do
      expect(Req, :request, fn _opts ->
        {:ok,
         %Req.Response{
           status: 500,
           body: %{"error" => "Internal Server Error"}
         }}
      end)

      assert {:error, {:http_error, 500, %{"error" => "Internal Server Error"}}} =
               Client.get_updates(bot_token: "test-token")
    end

    test "returns error on network failure" do
      expect(Req, :request, fn _opts ->
        {:error, %Req.TransportError{reason: :timeout}}
      end)

      assert {:error, %Req.TransportError{reason: :timeout}} =
               Client.get_updates(bot_token: "test-token")
    end
  end

  describe "send_message/3" do
    test "sends message successfully" do
      expect(Req, :request, fn opts ->
        assert opts[:method] == :post
        assert opts[:url] == "https://api.telegram.org/bottest-token/sendMessage"
        assert opts[:json] == %{chat_id: 123, text: "Hello!"}

        {:ok,
         %Req.Response{
           status: 200,
           body: %{"ok" => true, "result" => %{"message_id" => 456}}
         }}
      end)

      assert {:ok, %{"message_id" => 456}} =
               Client.send_message(123, "Hello!", bot_token: "test-token")
    end

    test "sends message with parse_mode" do
      expect(Req, :request, fn opts ->
        assert opts[:json] == %{chat_id: 123, text: "*bold*", parse_mode: "Markdown"}

        {:ok,
         %Req.Response{
           status: 200,
           body: %{"ok" => true, "result" => %{"message_id" => 456}}
         }}
      end)

      assert {:ok, _} =
               Client.send_message(123, "*bold*", bot_token: "test-token", parse_mode: "Markdown")
    end

    test "sends message with reply_to_message_id" do
      expect(Req, :request, fn opts ->
        assert opts[:json] == %{chat_id: 123, text: "Reply", reply_to_message_id: 789}

        {:ok,
         %Req.Response{
           status: 200,
           body: %{"ok" => true, "result" => %{"message_id" => 456}}
         }}
      end)

      assert {:ok, _} =
               Client.send_message(123, "Reply",
                 bot_token: "test-token",
                 reply_to_message_id: 789
               )
    end

    test "returns error on failure" do
      expect(Req, :request, fn _opts ->
        {:ok,
         %Req.Response{
           status: 200,
           body: %{"ok" => false, "description" => "Chat not found"}
         }}
      end)

      assert {:error, "Chat not found"} =
               Client.send_message(123, "Hello!", bot_token: "test-token")
    end
  end

  describe "get_me/1" do
    test "returns bot info on success" do
      expect(Req, :request, fn opts ->
        assert opts[:method] == :get
        assert opts[:url] == "https://api.telegram.org/bottest-token/getMe"

        {:ok,
         %Req.Response{
           status: 200,
           body: %{"ok" => true, "result" => %{"id" => 123, "username" => "test_bot"}}
         }}
      end)

      assert {:ok, %{"id" => 123, "username" => "test_bot"}} =
               Client.get_me(bot_token: "test-token")
    end

    test "returns error on failure" do
      expect(Req, :request, fn _opts ->
        {:ok,
         %Req.Response{
           status: 200,
           body: %{"ok" => false, "description" => "Unauthorized"}
         }}
      end)

      assert {:error, "Unauthorized"} = Client.get_me(bot_token: "test-token")
    end
  end
end
