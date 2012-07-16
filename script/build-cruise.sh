#!/bin/sh
source $HOME/.rvm/scripts/rvm

source .rmvrc

gem list --local bundler | grep bundler || gem install bundler || exit 1

bundle check || bundle install &&

bundle exec rake cruise2
