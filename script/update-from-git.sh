#!/bin/sh -e
# use for updating small changes for fairdomhub from git repo

set -e

GREEN='\033[0;32m'
NC='\033[0m' # No Color

#/bin/bash -login
export RAILS_ENV=production

bundle exec rake seek:workers:stop
bundle exec rake sunspot:solr:stop

echo "${GREEN}git pull${NC}"
git pull

cd .. && cd - #this is to allow RVM to pick up the ruby and gemset changes
echo "${GREEN}bundle install${NC}"
bundle install --deployment
echo "${GREEN} db:migrate${NC}"
bundle exec rake db:migrate
echo "${GREEN} precompile assets${NC}"
bundle exec rake assets:precompile # this task will take a while
bundle exec rake seek:reindex_all

bundle exec rake sunspot:solr:start
bundle exec rake seek:workers:start

echo "${GREEN} restart server${NC}"
touch tmp/restart.txt
bundle exec rake tmp:clear