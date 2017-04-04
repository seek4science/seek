#!/bin/sh

function wait_for_mysql {
    while ! mysqladmin ping -h $MYSQL_HOST --silent; do
            echo "WAITING FOR MYSQL"
            sleep 2
    done
}

function wait_for_database {
    while ! mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_HOST -e "desc $MYSQL_DATABASE.users" > /dev/null
    do
            echo "WAITING FOR DATABASE"
            sleep 2
    done
}

function set_default_mysql_host {
    if [ -z $MYSQL_HOST ]
    then
        export MYSQL_HOST=db
    fi
}

function use_mysql_db {
    set_default_mysql_host
    cp docker/database.docker.mysql.yml config/database.yml
}

function check_mysql {
    if [ ! -z $MYSQL_DATABASE ]
    then
        echo "USING MYSQL"

        use_mysql_db

        wait_for_mysql

        if ! mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_HOST -e "desc $MYSQL_DATABASE.users" > /dev/null
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

function start_soffice {
    echo "STARTING SOFFICE"
    soffice --headless --accept="socket,host=127.0.0.1,port=8100;urp;" --nofirststartwizard &
}

function start_or_setup_search {
    if [ ! -z $SOLR_PORT ]
    then
      echo "USING SOLR CONTAINER"
      cp docker/sunspot.docker.yml config/sunspot.yml
    else
      echo "STARTING SOLR"
      bundle exec rake sunspot:solr:start
    fi
}