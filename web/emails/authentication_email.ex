defmodule MyApp.AuthenticationEmail do
  use Bamboo.Phoenix, view: TimeKeeper.EmailView

  import Bamboo.Email

  @doc """
    The sign in email containing the login link.
  """
  def login_link(token_value, user) do
    IO.puts "sending new email"
    new_email()
    |> to(user.email)
    |> from("info@tuks.com")
    |> subject("Your login link")
    |> assign(:token, token_value)
    |> render("login_link.text")
  end
end
