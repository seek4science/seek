#!/bin/bash

#Stop the search reverting to disabled if its setting hasn't been changed
if [ ! -f config/initializers/seek_local.rb ]
then
    cp docker/seek_local.rb config/initializers/seek_local.rb
fi

if [ ! -z $MYSQL_DATABASE ]
then
    echo "USING MYSQL"

    cp docker/database.docker.mysql.yml config/database.yml

    if ! mysql -uroot -p$MYSQL_ROOT_PASSWORD -h db -e "use $MYSQL_DATABASE"
    then
        echo "SETTING UP MYSQL DB"
        bundle exec rake db:setup
    fi
fi

bundle exec rake seek:upgrade