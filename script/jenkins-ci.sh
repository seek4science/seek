#!/bin/sh

set -e

RUBY_VERSION=$(cat .ruby-version)
GEMSET=$(cat .ruby-gemset)

cp test/database.cc.yml config/database.yml

echo "USING RUBY - $RUBY_VERSION with gemset - $GEMSET"
rvm list | grep $RUBY_VERSION > /dev/null || rvm install $RUBY_VERSION || exit 1
rvm gemset create ${GEMSET}
rvm use ${RUBY_VERSION}@${GEMSET}
gem install bundler
bundle install

bundle exec rake db:setup
bundle exec rake db:test:prepare
bundle exec rake test
bundle exec rake assets:precompile
