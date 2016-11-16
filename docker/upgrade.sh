#!/bin/bash
. docker/shared_functions.sh
#Stop the search reverting to disabled if its setting hasn't been changed
if [ ! -f config/initializers/seek_local.rb ]
then
    cp docker/seek_local.rb config/initializers/seek_local.rb
fi

check_mysql

bundle exec rake seek:upgrade