# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :time_keeper,
  ecto_repos: [TimeKeeper.Repo]

# Configures the endpoint
config :time_keeper, TimeKeeper.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "L8t+vunUMHlhED3fXkEmdIgVYmAae3h96uMLqr2iBONF+NgZrFrDZWf2RG3kwXeQ",
  render_errors: [view: TimeKeeper.ErrorView, accepts: ~w(html json)],
  pubsub: [name: TimeKeeper.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
