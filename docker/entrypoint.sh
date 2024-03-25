#!/bin/bash

# import some shared functions
. docker/shared_functions.sh

# DB config
check_mysql

# Search
start_search

# Set nginx config
export SEEK_LOCATION="${RAILS_RELATIVE_URL_ROOT:-/}"
export SEEK_SUB_URI="${SEEK_LOCATION%/}"
echo "SEEK_LOCATION: '$SEEK_LOCATION'"
echo "SEEK_SUB_URI: '$SEEK_SUB_URI'"
envsubst '${SEEK_LOCATION} ${SEEK_SUB_URI}' < docker/nginx.conf.template > nginx.conf

# Precompile assets if using sub URI
if [ ! -z $SEEK_SUB_URI ]
then
  echo "COMPILING ASSETS"
  # using --trace prevents giving the feeling things have frozen up during startup
  bundle exec rake assets:precompile --trace
  bundle exec rake assets:clean --trace
fi

# SETUP for OpenSEEK only, to link to openBIS if necessary
if [ ! -z $OPENBIS_USERNAME ]
then
    bundle exec rake db:seed:openseek:default_openbis_endpoint
fi

# Build the sitemap
echo "TRIGGER SITEMAP BUILD"
bundle exec rake sitemap:create &

# Start Rails
echo "STARTING SEEK"
bundle exec puma -C docker/puma.rb &

# Workers and Cron
if [ -z $NO_ENTRYPOINT_WORKERS ] #Don't start if flag set, for use with docker-compose
then
    echo "STARTING WORKERS"
    bundle exec rake seek:workers:start &
    
    setup_and_start_cron
fi

# Ensure things have started up and logs are available before tailing
while [ ! -f log/production.log ]
do
  sleep 0.2
done

tail -f log/production.log &

echo "STARTING NGINX"
nginx -c /seek/nginx.conf -g 'daemon off;'
