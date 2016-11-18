#!/bin/bash
. docker/shared_functions.sh
#Stop the search reverting to disabled if its setting hasn't been changed
enable_search

check_mysql

bundle exec rake seek:upgrade