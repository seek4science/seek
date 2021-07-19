#!/bin/bash
. docker/shared_functions.sh

cp docker/database.docker.mysql.yml config/database.yml

use_mysql_db
wait_for_mysql
wait_for_database

# Soffice service
start_soffice

# Search
start_search

echo "STARTING WORKERS"
bundle exec rake seek:workers:start

# Ensure the workers have started up and the logs are available before tailing
while [ ! -f log/production.log ]
do
  sleep 0.2
done

tail -f log/production.log
