#!/bin/sh

set -e

if ! pgrep -x "dockerd" >/dev/null
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
