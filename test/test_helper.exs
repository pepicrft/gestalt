ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Gestalt.Repo, :manual)

# Configure Mimic for mocking
Mimic.copy(Gestalt.Telegram.Client)
Mimic.copy(Req)
