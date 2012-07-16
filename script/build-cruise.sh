#!/bin/sh
source $HOME/.rvm/scripts/rvm

source .rmvrc

bundle check || bundle install &&

bundle exec rake cruise2
