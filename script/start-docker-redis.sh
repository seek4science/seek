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
    echo "container named seek-redis is already running"
    exit 1
fi

if ! (docker volume ls | grep -q seek-redis-data-volume)
then
  echo "creating seek-redis-data-volume"
  docker volume create --name=seek-redis-data-volume
fi

docker rm seek-redis > /dev/null 2>&1 || true
echo "creating and starting seek-redis container"
docker run -d --name seek-redis --restart=unless-stopped -p 6379:6379 -v "seek-redis-data-volume:/data" redis:8.6-alpine redis-server --appendonly yes --maxmemory "${SEEK_REDIS_MAXMEMORY:-256mb}" --maxmemory-policy allkeys-lru

echo "waiting for Redis to be ready ..."
retries=0
until docker exec seek-redis redis-cli ping 2>/dev/null | grep -q PONG; do
    sleep 1
    retries=$((retries + 1))
    if [ "$retries" -ge 60 ]; then
        echo "Redis did not become ready within 60 seconds"
        exit 1
    fi
done
echo "Redis is ready"
