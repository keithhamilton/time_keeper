defmodule TimeKeeper.SessionController do
  @moduledoc """
    Actions for creating and signing in with magic link tokens.
  """
  use TimeKeeper.Web, :controller

  alias TimeKeeper.{TokenAuthentication, User}
  alias TimeKeeper.Router.Helpers, as: Routes

  def new(conn, _params) do
      render(conn, "new.html")
  end

  def create(conn, %{"session" => %{"email" => email}}) do
    user = User |> Repo.get_by(email: email)
    case user do
      nil -> conn
        |> assign(:user, %{"email" => email, "board" => "e779cdff"})
        |> redirect(to: session_path(conn, :create))
      _ -> TokenAuthentication.provide_token(email)
    end

    conn
    |> put_flash(:info, "We have sent a sign-in link to #{email}.")
    |> redirect(to: user_path(conn, :new))
  end

  def create(conn, %{"user" => user_params}) do
    changeset = User.changeset(%User{}, user_params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        TokenAuthentication.provide_token(user)

        conn
        |> put_flash(:info, "Success! Please check your email.")
        |> redirect(to: user_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"token" => token}) do
    case TokenAuthentication.verify_token_value(token) do
      {:ok, user} ->
        conn
        |> assign(:current_user, user)
        |> put_session(:user_id, user.id)
        |> configure_session(renew: true)
        |> put_flash(:info, "You signed in successfully")
        |> redirect(to: work_path(conn, :switch_manual))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "The login token is invalid.")
        |> redirect(to: session_path(conn, :new))
    end
  end

  def delete(conn, _params) do
    conn
    |> assign(:current_user, nil)
    |> configure_session(drop: true)
    |> delete_session(:user_id)
    |> put_flash(:info, "You logged out successfully. Enjoy your day!")
    |> redirect(to: user_path(conn, :new))
  end

end
