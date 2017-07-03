defmodule TimeKeeper.User do
  use TimeKeeper.Web, :model

  schema "users" do
    field :email, :string
    field :board, :string
    has_many :jobs, TimeKeeper.Job
    has_many :auth_tokens, TimeKeeper.AuthToken

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email])
    |> validate_required([:email])
  end
end
