import Config

##########################
# General configurations #
##########################

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Include HEEx debug annotations as HTML comments in rendered markup
config :phoenix_live_view, :debug_heex_annotations, true

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

config :joken,
  default_signer: [
    signer_alg: "Ed25519",
    key_openssh: """
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
    QyNTUxOQAAACDVgskcQdNGPgcP9UJIwA6AB1FUnvCyO19dChVY3EFuZQAAAKDVn3NU1Z9z
    VAAAAAtzc2gtZWQyNTUxOQAAACDVgskcQdNGPgcP9UJIwA6AB1FUnvCyO19dChVY3EFuZQ
    AAAECOw1cqNcGfb/U3HgERb+cujt5dvVM+QzIWMMEWeaua5NWCyRxB00Y+Bw/1QkjADoAH
    UVSe8LI7X10KFVjcQW5lAAAAF2FyZW5hQGdhdGV3YXkubWlycmEuZGV2AQIDBAUG
    -----END OPENSSH PRIVATE KEY-----
    """
  ]

############################
# App configuration: arena #
############################

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we can use it
# to bundle .js and .css sources.
config :arena, ArenaWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "0zq8I9ztj7kj4cLdFmvduHwXQJJi9yzNUAUFAlKHkdXS/nJkxUvNPjlSdJPDSUf5"

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4000,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :arena, ArenaWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/arena_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :arena, dev_routes: true
config :arena, :spawn_bots, true

################################
# App configuration: champions #
################################

###################################
# App configuration: game_backend #
###################################

# Configure your database
config :game_backend, GameBackend.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "game_backend",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

##################################
# App configuration: game_client #
##################################

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we can use it
# to bundle .js and .css sources.
config :game_client, GameClientWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 3000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "0zq8I9ztj7kj4cLdFmvduHwXQJJi9yzNUAUFAlKHkdXS/nJkxUvNPjlSdJPDSUf5",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:game_client, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:game_client, ~w(--watch)]}
  ]

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4000,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :game_client, GameClientWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/game_client_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :game_client, dev_routes: true

##############################
# App configuration: gateway #
##############################

config :gateway, Gateway.Endpoint,
  secret_key_base: "/v6PsTH3UkyIS1yUg7J0Df7SfgWUZbxfMtsI9Mjwp0kFe4MaXxHObc4L8IkfWhvR"

###################################
# App configuration: configurator #
###################################
# Configure your database
config :configurator, Configurator.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "configurator_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we can use it
# to bundle .js and .css sources.
config :configurator, ConfiguratorWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  url: [host: "localhost", port: 4100],
  http: [ip: {127, 0, 0, 1}, port: 4100],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "zNPZNBpWqXzyDETN+L01C8CBynVluG4WQ9s4P7ZfTk3UK+9v6X7WVntnkfIunZzY",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:configurator, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:configurator, ~w(--watch)]}
  ]

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :configurator, ConfiguratorWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/configurator_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :configurator, dev_routes: true
