#!/bin/bash

# Change secret token
sed -i "s/secret_token = '.*'/key = '"`bundle exec rake secret`"'/" config/initializers/secret_token.rb

# DB
soffice --headless --accept="socket,host=127.0.0.1,port=8100;urp;" --nofirststartwizard > /dev/null 2>&1 &

# Workers
bundle exec rake seek:workers:start

# Search
bundle exec rake sunspot:solr:start

chown -R app:app /home/app/seek

/sbin/my_init
