defmodule TimeKeeper.Repo.Migrations.CreateJob do
  use Ecto.Migration

  def change do
    create table(:jobs) do
      add :job_name, :string
      add :job_code, :string

      timestamps()
    end

  end
end
