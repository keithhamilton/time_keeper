defmodule TimeKeeper.Repo.Migrations.UpdateJob do
  use Ecto.Migration

  def change do
    alter table(:jobs) do
      add :button_id, :integer
      add :active, :boolean, default: false
    end
  end
end
