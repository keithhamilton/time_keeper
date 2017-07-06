defmodule TimeKeeper.Work do
  use TimeKeeper.Web, :model

  alias TimeKeeper.User

  schema "work" do
    field :complete, :boolean, default: false
    belongs_to :job, TimeKeeper.Job, foreign_key: :job_id
    field :user_id, :integer

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:complete, :user_id])
    |> validate_required([:complete])
  end
end
