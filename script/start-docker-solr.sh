#!/bin/sh

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Check the Docker daemon is reachable. Works on Linux (native daemon) and
# macOS/Docker Desktop (daemon in a VM).
if ! docker info >/dev/null 2>&1
then
    echo "the Docker service isn't running"
    exit 1
fi

if docker ps | grep -qw seek-search
then
    echo "container named seek-search is already running"
    exit 1
fi

if ! (docker volume ls | grep -q seek-solr-data-volume)
then
  echo "creating seek-solr-data-volume"
  docker volume create --name=seek-solr-data-volume
fi

docker rm seek-search > /dev/null 2>&1 || true
echo "creating and starting seek-search container"
docker run -d --name seek-search --restart=unless-stopped -p 8983:8983 -v "seek-solr-data-volume:/var/solr/" -v "$REPO_ROOT/solr/seek/conf:/opt/solr/server/solr/configsets/seek_config/conf" solr:9.10.1 solr-precreate seek /opt/solr/server/solr/configsets/seek_config

echo "waiting for Solr to be ready ..."
retries=0
until curl -sf http://localhost:8983/solr/seek/admin/ping > /dev/null 2>&1; do
    sleep 2
    retries=$((retries + 1))
    if [ "$retries" -ge 60 ]; then
        echo "Solr did not become ready within 120 seconds"
        exit 1
    fi
done
echo "Solr is ready"
