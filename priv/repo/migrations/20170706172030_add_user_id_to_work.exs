defmodule TimeKeeper.Repo.Migrations.AddUserIdToWork do
  use Ecto.Migration

  def change do
    alter table(:work) do
      add :user_id, :integer
    end
  end
end
