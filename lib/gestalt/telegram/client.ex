defmodule Gestalt.Telegram.Client do
  @moduledoc """
  HTTP client for the Telegram Bot API.
  """

  @base_url "https://api.telegram.org"

  @doc """
  Fetches updates from the Telegram API using long polling.

  ## Options
    - `:offset` - Identifier of the first update to be returned
    - `:timeout` - Timeout in seconds for long polling (default: 30)
    - `:bot_token` - Bot token (defaults to config)
  """
  @spec get_updates(keyword()) :: {:ok, list(map())} | {:error, term()}
  def get_updates(opts \\ []) do
    offset = Keyword.get(opts, :offset)
    timeout = Keyword.get(opts, :timeout, 30)
    bot_token = Keyword.get_lazy(opts, :bot_token, &bot_token/0)

    params =
      %{timeout: timeout}
      |> maybe_put(:offset, offset)

    case request(:get, "/getUpdates", params, bot_token) do
      {:ok, %{"ok" => true, "result" => updates}} ->
        {:ok, updates}

      {:ok, %{"ok" => false, "description" => description}} ->
        {:error, description}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Sends a text message to a chat.

  ## Options
    - `:parse_mode` - Parse mode for the message (e.g., "Markdown", "HTML")
    - `:reply_to_message_id` - Message ID to reply to
    - `:bot_token` - Bot token (defaults to config)
  """
  @spec send_message(integer(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def send_message(chat_id, text, opts \\ []) do
    parse_mode = Keyword.get(opts, :parse_mode)
    reply_to_message_id = Keyword.get(opts, :reply_to_message_id)
    bot_token = Keyword.get_lazy(opts, :bot_token, &bot_token/0)

    params =
      %{chat_id: chat_id, text: text}
      |> maybe_put(:parse_mode, parse_mode)
      |> maybe_put(:reply_to_message_id, reply_to_message_id)

    case request(:post, "/sendMessage", params, bot_token) do
      {:ok, %{"ok" => true, "result" => message}} ->
        {:ok, message}

      {:ok, %{"ok" => false, "description" => description}} ->
        {:error, description}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Gets information about the bot.

  ## Options
    - `:bot_token` - Bot token (defaults to config)
  """
  @spec get_me(keyword()) :: {:ok, map()} | {:error, term()}
  def get_me(opts \\ []) do
    bot_token = Keyword.get_lazy(opts, :bot_token, &bot_token/0)

    case request(:get, "/getMe", %{}, bot_token) do
      {:ok, %{"ok" => true, "result" => bot_info}} ->
        {:ok, bot_info}

      {:ok, %{"ok" => false, "description" => description}} ->
        {:error, description}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp request(method, path, params, bot_token) do
    url = "#{@base_url}/bot#{bot_token}#{path}"

    req_opts =
      case method do
        :get -> [params: params]
        :post -> [json: params]
      end

    case Req.request([method: method, url: url] ++ req_opts) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, exception} ->
        {:error, exception}
    end
  end

  defp bot_token do
    Application.get_env(:gestalt, :telegram)[:bot_token] ||
      raise "TELEGRAM_BOT_TOKEN is not configured"
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
