#!/bin/sh

set -e

# Check the Docker daemon is reachable. Works on Linux (native daemon) and
# macOS/Docker Desktop (daemon in a VM).
if ! docker info >/dev/null 2>&1
then
    echo "the Docker service isn't running"
    exit 1
fi

if ! docker ps -a | grep -qw seek-redis
then
    echo "container named seek-redis does not exist"
    exit 1
fi

echo "stopping and removing seek-redis container"
docker stop seek-redis > /dev/null 2>&1 || true
docker rm seek-redis > /dev/null
echo "stopped (the seek-redis-data-volume volume is kept)"
