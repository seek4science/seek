#!/bin/sh

set -e

# Check the Docker daemon is reachable. Works on Linux (native daemon) and
# macOS/Docker Desktop (daemon in a VM).
if ! docker info >/dev/null 2>&1
then
    echo "the Docker service isn't running"
    exit 1
fi

if docker ps | grep -qw seek-cache
then
    echo "container named seek-cache is currently running, stop first"
    exit 1
fi

echo "deleting seek-cache container and seek-redis-data-volume volume"
if docker ps -a | grep -qw seek-cache
then
    docker rm seek-cache > /dev/null
    echo "deleted container"
else
    echo "container seek-cache does not exist, skipping"
fi
docker volume rm seek-redis-data-volume > /dev/null 2>&1 || true
echo "deleted volume"
