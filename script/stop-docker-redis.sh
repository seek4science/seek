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

if [ -z "$(docker ps -aq --filter "name=^${CONTAINER}$")" ]
then
    echo "container named ${CONTAINER} does not exist"
    exit 1
fi

echo "stopping and removing ${CONTAINER} container"
docker stop "$CONTAINER" > /dev/null 2>&1 || true
docker rm "$CONTAINER" > /dev/null
echo "stopped (the seek-redis-data-volume volume is kept)"
