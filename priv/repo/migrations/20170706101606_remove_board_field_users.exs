defmodule TimeKeeper.Repo.Migrations.RemoveBoardFieldUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :board
    end
  end
end
