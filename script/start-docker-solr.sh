#!/bin/sh

if ! pgrep -x "dockerd" >/dev/null
then
    echo "the Docker service isn't running"
    exit 1
fi

if docker ps | grep -q seek-search
then
    echo "container named seek-search is already running"
    exit 1
fi

if docker ps -a | grep -q seek-search
then
    echo "starting seek-search container"
    docker start seek-search
else
    echo "creating and starting seek-search container"
    docker run -d --name seek-search -p 8983:8983 fairdom/seek-solr:8.11 solr-precreate seek /opt/solr/server/solr/configsets/seek_config
fi