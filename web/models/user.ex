defmodule TimeKeeper.User do
  use TimeKeeper.Web, :model

  schema "users" do
    field :email, :string
    field :name, :string
    field :encrypted_password, :string
    has_many :buttons, TimeKeeper.Button

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    IO.inspect struct
    IO.inspect params
    struct
    |> cast(params, [:email, :board, :name])
    |> validate_required([:email])
  end
end
