defmodule TimeKeeper.Repo.Migrations.RemoveJobUserRelationship do
  use Ecto.Migration

  def change do
    alter table(:jobs) do
      remove :user_id
    end
    alter table(:buttons) do
      remove :job_id
      add :user_id, references(:users, on_delete: :delete_all)
    end
  end
end
