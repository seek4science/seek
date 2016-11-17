#!/bin/bash
. docker/shared_functions.sh
#Stop the search reverting to disabled if its setting hasn't been changed
enable_search

check_mysql

# Soffice service
start_soffice

# Search
start_or_setup_search

echo "STARTING WORKERS"
bundle exec rake seek:workers:start
tail -f log/production.log