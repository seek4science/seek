#!/bin/bash

# DB
bundle exec rake db:setup

# Assets (CSS/JS)
bundle exec rake assets:precompile

soffice --headless --accept="socket,host=127.0.0.1,port=8100;urp;" --nofirststartwizard > /dev/null 2>&1 &

# Workers
bundle exec rake seek:workers:start

# Search
bundle exec rake sunspot:solr:start

chown -R app:app /home/app/seek

exec "$@"
