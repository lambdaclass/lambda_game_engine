#!/usr/bin/env bash
. "${HOME}/.cargo/env"
set -ex

export PATH=${PATH}:/opt/homebrew/bin/

if [ -d "/tmp/mirra_backend" ]; then
	rm -rf /tmp/mirra_backend
fi

cd /tmp
git clone git@github.com:lambdaclass/mirra_backend.git --branch ${BRANCH_NAME} mirra_backend
cd mirra_backend

chmod +x devops/entrypoint.sh

mix local.hex --force && mix local.rebar --force
mix deps.get --only $MIX_ENV
MIX_ENV=$MIX_ENV mix compile
MIX_ENV=$MIX_ENV mix tailwind configurator --minify
MIX_ENV=$MIX_ENV mix esbuild configurator --minify
MIX_ENV=$MIX_ENV mix phx.digest
mix release ${RELEASE} --overwrite
if [ ${RELEASE} == "central_backend" ]; then
	mix ecto.migrate
fi

export PHX_HOST=$PHX_HOST
export DATABASE_URL=$DATABASE_URL
export PHX_SERVER=$PHX_SERVER
export SECRET_KEY_BASE=$SECRET_KEY_BASE
export JWT_PRIVATE_KEY_BASE_64=$JWT_PRIVATE_KEY_BASE_64
export PORT=$PORT
export RELEASE_NODE=$RELEASE_NODE
export GATEWAY_URL=$GATEWAY_URL
export METRICS_ENDPOINT_PORT=$METRICS_ENDPOINT_PORT
export OVERRIDE_JWT=$OVERRIDE_JWT
export GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID
export BOT_MANAGER_PORT=$BOT_MANAGER_PORT
export BOT_MANAGER_HOST=$BOT_MANAGER_HOST
export CONFIGURATOR_HOST=$CONFIGURATOR_HOST
export CONFIGURATOR_GOOGLE_CLIENT_ID=$CONFIGURATOR_GOOGLE_CLIENT_ID
export CONFIGURATOR_GOOGLE_CLIENT_SECRET=$CONFIGURATOR_GOOGLE_CLIENT_SECRET
export RELEASE=$RELEASE
export TARGET_SERVER=$TARGET_SERVER
export LOADTEST_EUROPE_HOST=$LOADTEST_EUROPE_HOST
export LOADTEST_BRAZIL_HOST=$LOADTEST_BRAZIL_HOST
export LOADTEST_CHILE_HOST=$LOADTEST_CHILE_HOST

/Users/lambdaclass/arena/mirra_backend/_build/prod/rel/arena/bin/arena stop

rm -rf ${HOME}/arena/mirra_backend
mv /tmp/mirra_backend ${HOME}/arena/

/Users/lambdaclass/arena/mirra_backend/_build/prod/rel/arena/bin/arena daemon
