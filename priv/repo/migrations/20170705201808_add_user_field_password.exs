defmodule TimeKeeper.Repo.Migrations.AddUserFieldPassword do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :encrypted_password, :string
    end
  end
end
