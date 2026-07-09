#!/bin/sh

set -e

# Check the Docker daemon is reachable. Works on Linux (native daemon) and
# macOS/Docker Desktop (daemon in a VM).
if ! docker info >/dev/null 2>&1
then
    echo "the Docker service isn't running"
    exit 1
fi

if docker ps | grep -qw seek-search
then
    echo "container named seek-search is current running, stop first"
    exit 1
fi


echo "deleting seek-search container and seek-solr-data-volume volume"
if docker ps -a | grep -qw seek-search
then
    docker rm seek-search > /dev/null
    echo "deleted container"
else
    echo "container seek-search does not exist, skipping"
fi
docker volume rm seek-solr-data-volume > /dev/null 2>&1 || true
echo "deleted volume"