#!/bin/sh -e
# for small incremental updates from git. For full upgrades please see http://seek4science.org/installing
# should be run from the root folder of the SEEK installation

set -e

GREEN='\033[0;32m'
NC='\033[0m' # No Color

export RAILS_ENV=production

echo "${GREEN}git pull${NC}"
git pull

cd . - #this is to allow RVM to pick up the ruby and gemset changes
echo "${GREEN}bundle install${NC}"
bundle install --deployment

bundle exec rake seek:workers:stop
bundle exec rake sunspot:solr:stop

echo "${GREEN} seek:upgrade${NC}"
bundle exec rake seek:upgrade
echo "${GREEN} precompile assets${NC}"
bundle exec rake assets:precompile # this task will take a while

bundle exec rake sunspot:solr:start
sleep 5 # small delay to make sure SOLR has started up and ready
bundle exec rake seek:workers:start

echo "${GREEN} restart server${NC}"
touch tmp/restart.txt
bundle exec rake tmp:clear
git checkout db/schema.rb
