# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :project4,
  ecto_repos: [Project4.Repo]

# Configures the endpoint
config :project4, Project4Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "B1V/QNSxPkFbWiU6I65Gj+xqQBA/f3H1IwEFF6toneuC73QiKS7PmtZVRMr+au/3",
  render_errors: [view: Project4Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Project4.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
