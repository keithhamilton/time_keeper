defmodule TimeKeeper.Job do
  use TimeKeeper.Web, :model

  schema "jobs" do
    field :job_name, :string
    field :job_code, :string
    belongs_to :user, TimeKeeper.User, foreign_key: :user_id

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:job_name, :job_code])
    |> validate_required([:job_name, :job_code])
  end
end
