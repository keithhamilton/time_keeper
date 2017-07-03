defmodule TimeKeeper.AuthToken do
  use TimeKeeper.Web, :model

  alias TimeKeeper.{Endpoint, User}
  alias Phoenix.Token

  schema "auth_tokens" do
    field :value, :string
    belongs_to :user, User

    timestamps(updated_at: false)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, user) do
    struct
    |> cast(%{}, [])
    |> put_assoc(:user, user)
    |> put_change(:value, generate_token(user))
    |> validate_required([:value, :user])
    |> unique_constraint(:value)
  end

  defp generate_token(nil), do: nil
  defp generate_token(user) do
    Token.sign(Endpoint, "user", user.id)
  end

end
