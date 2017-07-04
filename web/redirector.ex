defmodule TimeKeeper.Redirector do
  use Plug.Redirect

  redirect("/work/:start_date/:end_date", "/work/:start_date/:end_date/browser")
end
