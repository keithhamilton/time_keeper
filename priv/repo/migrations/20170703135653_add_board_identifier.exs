defmodule TimeKeeper.Repo.Migrations.AddBoardIdentifier do
  use Ecto.Migration

  def change do
    alter table(:jobs) do
      add :user_id, references(:users, on_delete: :delete_all)
    end

    alter table(:users) do
      add :serial, :string
    end
  end
end
