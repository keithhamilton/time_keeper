defmodule TimeKeeper.TokenAuthentication do
  @moduledoc """
    Service with functions for creating and signing in with magic link tokens.
  """
  import Ecto.Query, only: [where: 3]

  alias TimeKeeper.AuthToken
  alias TimeKeeper.Endpoint
  alias TimeKeeper.Mailer
  alias TimeKeeper.Repo
  alias TimeKeeper.User
  alias Phoenix.Token

  # token valid for 30 days
  @token_max_age 2_592_000

  @doc """
    Creates and sends a new magic login token to the user or emial.
  """
  def provide_token(nil), do: {:error, :not_found}

  def provide_token(email) when is_binary(email) do
    user = User |> Repo.get_by(email: email)
    case user do
      nil -> 
    end
    User
    |> Repo.get_by(email: email)
    |> send_token()
  end

  def provide_token(user) do
    send_token(user)
  end

  @doc """
    Checks the given token.
  """
  def verify_token_value(value) do
    AuthToken
    |> where([t], t.value == ^value)
    |> where([t], t.inserted_at > datetime_add(^Ecto.DateTime.utc, ^(@token_max_age * -1), "second"))
    |> Repo.one()
    |> verify_token()
  end

  defp verify_token(nil), do: {:error, :invald}
  defp verify_token(token) do
    token =
      token
      |> Repo.preload(:user)
      |> Repo.delete!

    user_id = token.user.id

    #verify the token matching the user id
    case Token.verify(Endpoint, "user", token.value, max_age: @token_max_age) do
      {:ok, ^user_id} ->
        {:ok, token.user}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp send_token(nil), do: {:error, :not_found}
  defp send_token(user) do
    user
    |> create_token()
    |> AuthenticationEmail.login_link(user)
    |> Mailer.deliver_now()

    IO.puts "Email sent"
    {:ok, user}
  end

  defp create_token(user) do
    changeset = AuthToken.changeset(%AuthToken{}, user)
    auth_token = Repo.insert!(changeset)
    auth_token.value
  end
end
