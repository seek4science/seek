#!/bin/sh

set -e

if ! pgrep -x "dockerd" >/dev/null
then
    echo "the Docker service isn't running"
    exit 1
fi

if ! docker ps | grep -q seek-search
then
    echo "container named seek-search is not running"
    exit 1
fi

echo "stopping and removing seek-search container"
docker stop seek-search > /dev/null
docker rm seek-search > /dev/null

echo "removing seek-solr-data-volume"
docker volume rm seek-solr-data-volume

echo "recreating seek-solr-data-volume"
docker volume create --name=seek-solr-data-volume

echo "creating and starting seek-search container"
"$(dirname "$0")/start-docker-solr.sh"

echo "waiting for Solr to be ready ..."
until curl -sf http://localhost:8983/solr/seek/admin/ping > /dev/null 2>&1; do
    sleep 2
done
echo "Solr is ready"

echo "reindexing ..."
bundle exec rake seek:reindex_all

echo "done"
