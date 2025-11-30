defmodule Gestalt.Repo do
  use Ecto.Repo,
    otp_app: :gestalt,
    adapter: Ecto.Adapters.SQLite3
end
