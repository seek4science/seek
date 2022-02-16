#!/bin/bash

# import some shared functions
. docker/shared_functions.sh

# DB config
check_mysql

# Soffice service
start_soffice

# Search
start_search

# Precompile assets if using RAILS_RELATIVE_URL_ROOT
if [ ! -z $RAILS_RELATIVE_URL_ROOT ]
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

# Start Rails
echo "STARTING SEEK"
bundle exec puma -C docker/puma.rb -d

# Workers and Cron
if [ -z $NO_ENTRYPOINT_WORKERS ] #Don't start if flag set, for use with docker-compose
then
    echo "STARTING WORKERS"
    bundle exec rake seek:workers:start &
    
    setup_and_start_cron
fi

# Ensure things have started up and logs are available before tailing
while [ ! -f log/puma.out ] || [ ! -f log/puma.err ] || [ ! -f log/production.log ]
do
  sleep 0.2
done

tail -f log/puma.out log/puma.err log/production.log &

echo "STARTING NGINX"
nginx -g 'daemon off;'
