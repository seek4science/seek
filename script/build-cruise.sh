#!/bin/sh
source $HOME/.rvm/scripts/rvm

rvm use ruby-1.8.7@seek015 --create

gem list --local bundler | grep bundler || gem install bundler || exit 1

bundle check || bundle install &&

bundle exec rake cruise2
