ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Gestalt.Repo, :manual)

# Configure Mimic for mocking
Mimic.copy(Gestalt.Telegram.Client)
Mimic.copy(Gestalt.LLM.Client)
Mimic.copy(Gestalt.Conversation.Supervisor)
Mimic.copy(Gestalt.Conversation.Server)
Mimic.copy(Req)
