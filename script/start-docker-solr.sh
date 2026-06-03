#!/bin/sh

if ! pgrep -x "dockerd" >/dev/null
then
    echo "the Docker service isn't running"
    exit 1
fi

if docker ps | grep -q seek-search
then
    echo "container named seek-search is already running"
    exit 1
fi

if ! (docker volume ls | grep -q seek-solr-data-volume)
then
  echo "creating seek-solr-data-volume"
  docker volume create --name=seek-solr-data-volume
fi

if docker ps -a | grep -q seek-search
then
    echo "starting seek-search container"
    docker start seek-search > /dev/null
else
    echo "creating and starting seek-search container"
    docker run -d --name seek-search --restart=unless-stopped -p 8983:8983 -v "seek-solr-data-volume:/var/solr/" -v "$(pwd)/solr/seek/conf:/opt/solr/server/solr/configsets/seek_config/conf" solr:8.11.4 solr-precreate seek /opt/solr/server/solr/configsets/seek_config
fi

echo "waiting for Solr to be ready ..."
until curl -sf http://localhost:8983/solr/seek/admin/ping > /dev/null 2>&1; do
    sleep 2
done
echo "Solr is ready"
