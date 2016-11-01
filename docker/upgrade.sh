#!/bin/bash

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