#!/bin/sh

set -e

# Check the Docker daemon is reachable. Works on Linux (native daemon) and
# macOS/Docker Desktop (daemon in a VM).
if ! docker info >/dev/null 2>&1
then
    echo "the Docker service isn't running"
    exit 1
fi

if docker ps -a | grep -qw seek-search
then
    echo "stopping and removing seek-search container"
    docker stop seek-search > /dev/null 2>&1 || true
    docker rm seek-search > /dev/null
fi

echo "removing seek-solr-data-volume"
docker volume rm seek-solr-data-volume > /dev/null 2>&1 || true

echo "recreating seek-solr-data-volume"
docker volume create --name=seek-solr-data-volume

"$(dirname "$0")/start-docker-solr.sh"

echo "reindexing ..."
(cd "$(dirname "$0")/.." && bundle exec rake seek:reindex_all)

echo "done"
