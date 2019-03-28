#!/bin/sh

cp test/config/virtuoso_test_settings.yml config/virtuoso_settings.yml

docker pull tenforce/virtuoso
docker run \
    -p 8890:8890 -p 1111:1111 \
    -e DBA_PASSWORD=tester \
    -e SPARQL_UPDATE=true \
    -e DEFAULT_GRAPH=http://www.example.com/my-graph \
    -d tenforce/virtuoso