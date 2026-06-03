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

"$(dirname "$0")/start-docker-solr.sh"

echo "reindexing ..."
(cd "$(dirname "$0")/.." && bundle exec rake seek:reindex_all)

echo "done"
