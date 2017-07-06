defmodule TimeKeeper.Repo.Migrations.AddJobCodeToButtons do
  use Ecto.Migration

  def change do
    alter table(:buttons) do
      add :job_code, :string
    end
  end
end
