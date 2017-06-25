defmodule TimeKeeper.Repo.Migrations.CreateButton do
  use Ecto.Migration

  def change do
    create table(:buttons) do
      add :serial_id, :integer
      add :job, references(:jobs, on_delete: :nothing)

      timestamps()
    end
    create index(:buttons, [:job])

  end
end
