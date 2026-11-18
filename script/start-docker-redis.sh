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
    echo "container named ${CONTAINER} is already running"
    exit 1
fi

# Another container already publishing 6379 would stop this one from binding the port.
PORT_HOLDER="$(docker ps --filter publish=6379 --format '{{.Names}}')"
if [ -n "$PORT_HOLDER" ]
then
    echo "port 6379 is already published by container: ${PORT_HOLDER}"
    echo "stop and remove it first, e.g. docker rm -f ${PORT_HOLDER}"
    exit 1
fi

if ! (docker volume ls | grep -q seek-redis-data-volume)
then
  echo "creating seek-redis-data-volume"
  docker volume create --name=seek-redis-data-volume
fi

# REDIS_PASSWORD, if set, is passed as an env var and expanded in the container to keep it out of the
# command line. docker-entrypoint.sh still drops root to the redis user.
docker rm "$CONTAINER" > /dev/null 2>&1 || true
echo "creating and starting ${CONTAINER} container"
docker run -d --name "$CONTAINER" --restart=unless-stopped -p 127.0.0.1:6379:6379 -v "seek-redis-data-volume:/data" \
  ${REDIS_PASSWORD:+-e REDIS_PASSWORD} redis:8.6-alpine \
  sh -c 'exec docker-entrypoint.sh redis-server "$@" ${REDIS_PASSWORD:+--requirepass "$REDIS_PASSWORD"}' sh \
  --appendonly yes --maxmemory "${REDIS_MAXMEMORY:-256mb}" --maxmemory-policy allkeys-lru

echo "waiting for Redis to be ready ..."
retries=0
# REDISCLI_AUTH is set for the docker exec alone and forwarded only when there is a password, so the
# readiness check authenticates without the password on the redis-cli command line.
until REDISCLI_AUTH="${REDIS_PASSWORD:-}" docker exec ${REDIS_PASSWORD:+-e REDISCLI_AUTH} "$CONTAINER" redis-cli ping 2>/dev/null | grep -q PONG; do
    sleep 1
    retries=$((retries + 1))
    if [ "$retries" -ge 60 ]; then
        echo "Redis did not become ready within 60 seconds"
        exit 1
    fi
done
echo "Redis is ready"
