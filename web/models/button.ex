defmodule TimeKeeper.Button do
  use TimeKeeper.Web, :model

  schema "buttons" do
    field :serial_id, :integer
    belongs_to :job, TimeKeeper.Job, foreign_key: :job_id
    field :job_code, :string, virtual: true

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:serial_id])
    |> validate_required([:serial_id])
  end
end
