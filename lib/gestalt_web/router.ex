defmodule GestaltWeb.Router do
  use GestaltWeb, :router

  pipeline :gestalt do
    plug :accepts, ["json"]
  end

  scope "/", GestaltWeb do
    pipe_through :gestalt

    get "/", HealthController, :index
    get "/health", HealthController, :index
  end

  scope "/api", GestaltWeb do
    pipe_through :gestalt

    get "/health", HealthController, :index
  end
end
