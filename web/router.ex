defmodule TimeKeeper.Router do
  use TimeKeeper.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
#    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TimeKeeper do
    pipe_through :browser # Use the default browser stack

    get "/", SessionController, :new
    get "/signin/:token", SessionController, :show, as: :signin
    get "/work/switch", WorkController, :switch_manual
    post "/work/switch", WorkController, :switch
    get "/work", WorkController, :dashboard
    get "/work/:start_date/:end_date", WorkController, :job_work
    get "/work/:start_date/:end_date/:download", WorkController, :job_work

    resources "/jobs", JobController
    resources "/buttons", ButtonController
    resources "/sessions", SessionController, only: [:new, :create, :delete]
    resources "/users", UserController
    resources "/work", WorkController

  end

  # Other scopes may use custom stacks.
  # scope "/api", TimeKeeper do
  #   pipe_through :api
  # end
end
