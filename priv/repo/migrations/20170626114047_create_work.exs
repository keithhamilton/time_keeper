defmodule TimeKeeper.Repo.Migrations.CreateWork do
  use Ecto.Migration

  def change do
    create table(:work) do
      add :complete, :boolean, default: false, null: false
      add :job_id, references(:jobs, on_delete: :nothing)

      timestamps()
    end
    create index(:work, [:job_id])

  end
end
