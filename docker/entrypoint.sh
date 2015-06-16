/seek soffice --headless --accept="socket,host=127.0.0.1,port=8100;urp;" --nofirststartwizard > /dev/null 2>&1 &

/seek bundle exec rake seek:workers:start

/seek bundle exec rake sunspot:solr:start

exec "$@"
