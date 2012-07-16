#!/bin/sh
source $HOME/.rvm/scripts/rvm

rvm use ruby-1.8.7@seek0.15

bundle check || bundle install &&

rake cruise2
