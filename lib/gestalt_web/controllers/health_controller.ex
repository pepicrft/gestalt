defmodule GestaltWeb.HealthController do
  @moduledoc """
  Health check endpoint for monitoring and load balancers.
  """
  use GestaltWeb, :controller

  @doc """
  Returns a simple health status.
  """
  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
