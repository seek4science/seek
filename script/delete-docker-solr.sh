#!/bin/sh

if ! pgrep -x "dockerd" >/dev/null
then
    echo "the Docker service isn't running"
    exit 1
fi

if docker ps | grep -q seek-search
then
    echo "container named seek-search is current running, stop first"
    exit 1
fi


echo "deleting seek-search container and seek-solr-data-volume volume"
docker rm seek-search > /dev/null
echo "deleted container"
docker volume rm seek-solr-data-volume /dev/null
echo "deleted volume"