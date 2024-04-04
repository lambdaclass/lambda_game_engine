import Config

##########################
# General configurations #
##########################

# Configures Swoosh API Client
config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: Arena.Finch

# Disable Swoosh Local Memory Storage
config :swoosh, local: false

# Do not print debug messages in production
config :logger, level: :info

############################
# App configuration: arena #
############################

# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix assets.deploy` task,
# which you should run after static files are built and
# before starting your production server.
config :arena, ArenaWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

################################
# App configuration: champions #
################################

###################################
# App configuration: game_backend #
###################################

# Configure your database
config :game_backend, GameBackend.Repo,
  url: System.get_env("DATABASE_URL"),
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

##################################
# App configuration: game_client #
##################################

# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix assets.deploy` task,
# which you should run after static files are built and
# before starting your production server.
config :game_client, GameClientWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json"

##############################
# App configuration: gateway #
##############################

###################################
# App configuration: configurator #
###################################

# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix assets.deploy` task,
# which you should run after static files are built and
# before starting your production server.
config :configurator, ConfiguratorWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json"
