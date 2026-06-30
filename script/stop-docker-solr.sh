#!/bin/sh

set -e

# Check the Docker daemon is reachable. Works on Linux (native daemon) and
# macOS/Docker Desktop (daemon in a VM).
if ! docker info >/dev/null 2>&1
then
    echo "the Docker service isn't running"
    exit 1
fi

if ! docker ps -a | grep -qw seek-search
then
    echo "container named seek-search does not exist"
    exit 1
fi

echo "stopping and removing seek-search container"
docker stop seek-search > /dev/null 2>&1 || true
docker rm seek-search > /dev/null
echo "stopped"
