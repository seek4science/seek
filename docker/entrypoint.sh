#!/bin/bash

# Change secret token
sed -i "s/secret_token = '.*'/key = '"`bundle exec rake secret`"'/" config/initializers/secret_token.rb

# Force search on
if [ ! -f config/initializers/seek_local.rb ]
then
    cp docker/seek_local.rb config/initializers/seek_local.rb
fi

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
echo "STARTING SOFFICE"
soffice --headless --accept="socket,host=127.0.0.1,port=8100;urp;" --nofirststartwizard > /dev/null 2>&1 &

# Search
if [ ! -z $SOLR_PORT ]
then
  echo "USING SOLR CONTAINER"
  cp docker/sunspot.docker.yml config/sunspot.yml
else
  echo "STARTING SOLR"
  bundle exec rake sunspot:solr:start
fi

# Start Rails
echo "STARTING SEEK"
bundle exec puma -C config/puma.rb -d

# Workers
echo "STARTING WORKERS"
bundle exec rake seek:workers:start &

echo "STARTING NGINX"
nginx -g 'daemon off;'
