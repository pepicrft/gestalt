defmodule Gestalt.LLM.ClientTest do
  use ExUnit.Case, async: true

  import Mimic

  alias Gestalt.LLM.Client

  setup :set_mimic_private

  describe "chat/1" do
    test "returns response text on success" do
      messages = [
        %{role: "user", content: "Hello!"}
      ]

      expect(Req, :request, fn opts ->
        assert opts[:method] == :post
        assert opts[:url] == "https://api.anthropic.com/v1/messages"

        # Check headers
        headers = Map.new(opts[:headers])
        assert headers["x-api-key"] == "test-api-key"
        assert headers["anthropic-version"] == "2023-06-01"

        # Check body
        body = opts[:json]
        assert body.model == "claude-sonnet-4-20250514"
        assert body.max_tokens == 4096
        assert is_binary(body.system)
        assert body.messages == [%{role: "user", content: "Hello!"}]

        {:ok,
         %Req.Response{
           status: 200,
           body: %{
             "content" => [%{"type" => "text", "text" => "Hi there! How can I help you?"}]
           }
         }}
      end)

      Application.put_env(:gestalt, :anthropic, api_key: "test-api-key")

      assert {:ok, "Hi there! How can I help you?"} = Client.chat(messages)
    after
      Application.delete_env(:gestalt, :anthropic)
    end

    test "filters out system messages from input" do
      messages = [
        %{role: "system", content: "System prompt"},
        %{role: "user", content: "Hello!"},
        %{role: "assistant", content: "Hi!"},
        %{role: "user", content: "How are you?"}
      ]

      expect(Req, :request, fn opts ->
        body = opts[:json]

        # System messages should be filtered out
        assert body.messages == [
                 %{role: "user", content: "Hello!"},
                 %{role: "assistant", content: "Hi!"},
                 %{role: "user", content: "How are you?"}
               ]

        {:ok,
         %Req.Response{
           status: 200,
           body: %{
             "content" => [%{"type" => "text", "text" => "I'm doing well!"}]
           }
         }}
      end)

      Application.put_env(:gestalt, :anthropic, api_key: "test-api-key")

      assert {:ok, "I'm doing well!"} = Client.chat(messages)
    after
      Application.delete_env(:gestalt, :anthropic)
    end

    test "returns error on API error response" do
      expect(Req, :request, fn _opts ->
        {:ok,
         %Req.Response{
           status: 400,
           body: %{"error" => %{"message" => "Invalid request"}}
         }}
      end)

      Application.put_env(:gestalt, :anthropic, api_key: "test-api-key")

      assert {:error, {:http_error, 400, _}} = Client.chat([%{role: "user", content: "Hi"}])
    after
      Application.delete_env(:gestalt, :anthropic)
    end

    test "returns error on network failure" do
      expect(Req, :request, fn _opts ->
        {:error, %Req.TransportError{reason: :timeout}}
      end)

      Application.put_env(:gestalt, :anthropic, api_key: "test-api-key")

      assert {:error, %Req.TransportError{reason: :timeout}} =
               Client.chat([%{role: "user", content: "Hi"}])
    after
      Application.delete_env(:gestalt, :anthropic)
    end
  end
end
