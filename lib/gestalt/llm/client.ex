defmodule Gestalt.LLM.Client do
  @moduledoc """
  HTTP client for the Anthropic Claude API.

  Handles communication with Claude for generating conversational responses.
  """

  @base_url "https://api.anthropic.com/v1"
  @model "claude-sonnet-4-20250514"
  @max_tokens 4096

  @doc """
  Sends a chat request to Claude and returns the response.

  Takes a list of message structs and converts them to the Anthropic API format.
  """
  @spec chat([Gestalt.Conversation.Message.t()]) :: {:ok, String.t()} | {:error, term()}
  def chat(messages) do
    api_messages = format_messages(messages)

    body = %{
      model: @model,
      max_tokens: @max_tokens,
      system: system_prompt(),
      messages: api_messages
    }

    case request(:post, "/messages", body) do
      {:ok, %{"content" => [%{"text" => text} | _]}} ->
        {:ok, text}

      {:ok, %{"error" => %{"message" => message}}} ->
        {:error, message}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp format_messages(messages) do
    messages
    |> Enum.filter(fn msg -> msg.role in ["user", "assistant"] end)
    |> Enum.map(fn msg ->
      %{role: msg.role, content: msg.content}
    end)
  end

  defp system_prompt do
    """
    You are Gestalt, a helpful AI assistant communicating via Telegram.
    You are friendly, concise, and helpful. Keep responses brief but informative,
    as they will be displayed in a chat interface.

    You can help with a wide variety of tasks including answering questions,
    having conversations, and providing information.
    """
  end

  defp request(:post, path, body) do
    url = "#{@base_url}#{path}"

    headers = [
      {"x-api-key", api_key()},
      {"anthropic-version", "2023-06-01"},
      {"content-type", "application/json"}
    ]

    case Req.request(method: :post, url: url, headers: headers, json: body) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, exception} ->
        {:error, exception}
    end
  end

  defp api_key do
    Application.get_env(:gestalt, :anthropic)[:api_key] ||
      raise "ANTHROPIC_API_KEY is not configured"
  end
end
