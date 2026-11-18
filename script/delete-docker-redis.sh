#!/bin/sh

set -e

# Check the Docker daemon is reachable. Works on Linux (native daemon) and
# macOS/Docker Desktop (daemon in a VM).
if ! docker info >/dev/null 2>&1
then
    echo "the Docker service isn't running"
    exit 1
fi

CONTAINER=seek-redis-cache

if [ -n "$(docker ps -q --filter "name=^${CONTAINER}$")" ]
then
    echo "container named ${CONTAINER} is currently running, stop first"
    exit 1
fi

echo "deleting ${CONTAINER} container and seek-redis-data-volume volume"
if [ -n "$(docker ps -aq --filter "name=^${CONTAINER}$")" ]
then
    docker rm "$CONTAINER" > /dev/null
    echo "deleted container"
else
    echo "container ${CONTAINER} does not exist, skipping"
fi
docker volume rm seek-redis-data-volume > /dev/null 2>&1 || true
echo "deleted volume"
