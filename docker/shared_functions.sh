#!/bin/sh

function check_mysql {
    if [ ! -z $MYSQL_DATABASE ]
    then
        echo "USING MYSQL"

        cp docker/database.docker.mysql.yml config/database.yml

        while ! mysqladmin ping -h db --silent; do
            echo "WAITING FOR MYSQL"
            sleep 3
        done

        if ! mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h db -e "desc $MYSQL_DATABASE.users" > /dev/null
        then
            echo "SETTING UP MYSQL DB"
            bundle exec rake db:setup
        fi
    fi
}

function enable_search {
    if [ ! -f config/initializers/seek_local.rb ]
    then
        cp docker/seek_local.rb config/initializers/seek_local.rb
    fi
}