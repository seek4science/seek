#!/bin/sh

set -e

# Check the Docker daemon is reachable. Works on Linux (native daemon) and
# macOS/Docker Desktop (daemon in a VM).
if ! docker info >/dev/null 2>&1
then
    echo "the Docker service isn't running"
    exit 1
fi

if docker ps | grep -qw seek-redis
then
    echo "container named seek-redis is currently running, stop first"
    exit 1
fi

echo "deleting seek-redis container and seek-redis-data-volume volume"
if docker ps -a | grep -qw seek-redis
then
    docker rm seek-redis > /dev/null
    echo "deleted container"
else
    echo "container seek-redis does not exist, skipping"
fi
docker volume rm seek-redis-data-volume > /dev/null 2>&1 || true
echo "deleted volume"
