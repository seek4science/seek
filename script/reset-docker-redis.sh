#!/bin/sh

set -e

# Check the Docker daemon is reachable. Works on Linux (native daemon) and
# macOS/Docker Desktop (daemon in a VM).
if ! docker info >/dev/null 2>&1
then
    echo "the Docker service isn't running"
    exit 1
fi

# Note: this wipes everything in Redis - cache entries and any sessions, so logged-in users on this
# instance will be signed out.
if docker ps -a | grep -qw seek-redis
then
    echo "stopping and removing seek-redis container"
    docker stop seek-redis > /dev/null 2>&1 || true
    docker rm seek-redis > /dev/null
fi

echo "removing seek-redis-data-volume"
docker volume rm seek-redis-data-volume > /dev/null 2>&1 || true

echo "recreating seek-redis-data-volume"
docker volume create --name=seek-redis-data-volume > /dev/null

"$(dirname "$0")/start-docker-redis.sh"

echo "done"
