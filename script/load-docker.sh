#!/bin/sh

set -e

location=$1

#do some sanity checks

error() {
  echo "ERROR:$1"
  echo "Usage: load-docker.sh path"
  echo ""
  echo " .. the path should point to a directory containing the filestore directory, and a seek.sql dump of database"
  exit 1
}

if [ -z "$location" ];then
  error "the path parameter is missing"
fi

if [ ! -f "$location/seek.sql" ];then
  error "$location/seek.sql file cannot be found"
fi

if [ ! -d "$location/filestore" ];then
  error "$location/filestore directory cannot be found"
fi

docker-compose down
docker volume rm seek-filestore 
docker volume rm seek-solr-data
docker volume rm seek-mysql-db
docker volume rm seek-cache
docker volume create --name=seek-filestore
docker volume create --name=seek-solr-data
docker volume create --name=seek-mysql-db
docker volume create --name=seek-cache
docker-compose up --no-start
docker-compose start seek db

echo "waiting 10 seconds for db to start up ..."
sleep 10

echo "copying filestore ..."
docker run --rm --volumes-from seek -v $location:/backup ubuntu bash -c "rm -rf /seek/filestore/*"
docker run --rm --volumes-from seek -v $location:/backup ubuntu bash -c "cp -rfv /backup/filestore/* seek/filestore/"
docker run --rm --volumes-from seek ubuntu bash -c "chown -R www-data.www-data /seek/filestore/*"

echo "copying database dump file ..."
docker run --rm --volumes-from seek -v $location:/backup ubuntu bash -c "cp /backup/seek.sql /seek/filestore/"

echo "loading up database ..."
docker exec seek bash -c 'bundle exec rake db:drop && bundle exec rake db:create'
docker exec seek bash -c 'mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h$MYSQL_HOST $MYSQL_DATABASE < /seek/filestore/seek.sql'

docker exec seek bash -c 'bundle exec rake tmp:clear'
docker exec seek bash -c 'bundle exec rake seek:reindex_all'
docker exec seek bash -c 'rm /seek/filestore/seek.sql'

echo "Starting up"
docker-compose restart
