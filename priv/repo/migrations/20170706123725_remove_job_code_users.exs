defmodule TimeKeeper.Repo.Migrations.RemoveJobCodeUsers do
  use Ecto.Migration

  def change do
    alter table(:buttons) do
      remove :job_code
      add :job_id, :integer
    end
  end
end
