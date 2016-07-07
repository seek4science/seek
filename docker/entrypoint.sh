#!/bin/bash

# Change secret token
sed -i "s/secret_token = '.*'/key = '"`bundle exec rake secret`"'/" config/initializers/secret_token.rb

# DB config

cp docker/database.docker.mysql.yml config/database.yml

bundle exec rake db:setup


# Soffice service
soffice --headless --accept="socket,host=127.0.0.1,port=8100;urp;" --nofirststartwizard > /dev/null 2>&1 &

# Workers
bundle exec rake seek:workers:start RAILS_ENV=production

# Search
bundle exec rake sunspot:solr:start RAILS_ENV=production

chown -R app:app .

/sbin/my_init
