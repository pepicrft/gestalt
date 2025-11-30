defmodule Gestalt.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add :telegram_chat_id, :integer, null: false
      add :telegram_user_id, :integer, null: false
      add :state, :string, null: false, default: "active"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:conversations, [:telegram_chat_id])
    create index(:conversations, [:telegram_user_id])
    create index(:conversations, [:state])
  end
end
