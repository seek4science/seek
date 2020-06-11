#!/bin/sh -e
# for small updates where database changes or the full upgrade script isn't required

set -e

GREEN='\033[0;32m'
NC='\033[0m' # No Color

export RAILS_ENV=production

echo "${GREEN}git pull${NC}"
git pull

cd . #this is to allow RVM to pick up the ruby and gemset changes
echo "${GREEN}bundle install${NC}"
bundle install --deployment

echo "${GREEN} precompile assets${NC}"
bundle exec rake assets:precompile # this task will take a while

echo "${GREEN} restart workers${NC}"
bundle exec rake seek:workers:restart

echo "${GREEN} restart server${NC}"
touch tmp/restart.txt
bundle exec rake tmp:clear