#!/bin/bash

# Change secret token
sed -i "s/secret_token = '.*'/key = '"`bundle exec rake secret`"'/" config/initializers/secret_token.rb

# DB config

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


# Soffice service
soffice --headless --accept="socket,host=127.0.0.1,port=8100;urp;" --nofirststartwizard > /dev/null 2>&1 &

# Workers
bundle exec rake seek:workers:start

# Search
bundle exec rake sunspot:solr:start

bundle exec rails server -b 0.0.0.0 &

nginx -g 'daemon off;'
