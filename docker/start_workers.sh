#!/bin/bash
. docker/shared_functions.sh
#Stop the search reverting to disabled if its setting hasn't been changed
enable_search

wait_for_mysql
wait_for_database

# Soffice service
start_soffice

# Search
start_or_setup_search

echo "STARTING WORKERS"
bundle exec rake seek:workers:start
tail -f log/production.log