#!/bin/bash

# import some shared functions
. docker/shared_functions.sh

# DB config
check_mysql

# Soffice service
start_soffice

# Search
start_search

# SETUP for OpenSEEK only, to link to openBIS if necessary
if [ ! -z $OPENBIS_USERNAME ]
then
    bundle exec rake db:seed:openseek:default_openbis_endpoint
fi

echo "GENERATING CRONTAB"
bundle exec whenever > /seek/seek.crontab

echo "STARTING SUPERCRONIC"
supercronic /seek/seek.crontab &

# Start Rails
echo "STARTING SEEK"
bundle exec puma -C docker/puma.rb -d

# Workers
if [ -z $NO_ENTRYPOINT_WORKERS ] #Don't start if flag set, for use with docker-compose
then
    echo "STARTING WORKERS"
    bundle exec rake seek:workers:start &
fi

# Ensure things have started up and logs are available before tailing
while [ ! -f log/puma.out ] || [ ! -f log/puma.err ] || [ ! -f log/production.log ]
do
  sleep 0.2
done

tail -f log/puma.out log/puma.err log/production.log &

echo "STARTING NGINX"
nginx -g 'daemon off;'
