#!/bin/bash

#export RAILS_ENV=production

echo 'Profile.find(:all).map do |w| w.solr_save end' | ruby script/console
echo 'Project.find(:all).map do |w| w.solr_save end' | ruby script/console
echo 'Institution.find(:all).map do |w| w.solr_save end' | ruby script/console

