#!/bin/sh

set -e

# Check the Docker daemon is reachable. Works on Linux (native daemon) and
# macOS/Docker Desktop (daemon in a VM).
if ! docker info >/dev/null 2>&1
then
    echo "the Docker service isn't running"
    exit 1
fi

if ! docker ps -a | grep -qw seek-seaweedfs
then
    echo "container named seek-seaweedfs does not exist"
    exit 1
fi

echo "stopping and removing seek-seaweedfs container"
docker stop seek-seaweedfs > /dev/null 2>&1 || true
docker rm seek-seaweedfs > /dev/null
echo "stopped (the seek-seaweedfs-data-volume volume is kept)"
