defmodule TimeKeeper.Button do
  use TimeKeeper.Web, :model

  schema "buttons" do
    field :serial_id, :integer
    field :job_id, :integer
    field :job_name, :string, virtual: true
    field :job_code, :string, virtual: true
    belongs_to :user, TimeKeeper.User, foreign_key: :user_id

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:serial_id, :job_id])
    |> validate_required([:serial_id])
  end
end
