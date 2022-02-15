#!/bin/sh

if ! pgrep -x "dockerd" >/dev/null
then
    echo "the Docker service isn't running"
    exit 1
fi

if ! docker ps | grep -q seek-search
then
    echo "container named seek-search is not running"
    exit 1
fi

echo "stopping seek-search container"
docker stop seek-search > /dev/null
echo "stopped"