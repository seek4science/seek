require 'rubygems'
require 'rake'

namespace :solr do
  task(:resolr=>:environment) do
    Person.find(:all).map do |w| w.solr_save end
    Project.find(:all).map do |w| w.solr_save end
    Institution.find(:all).map do |w| w.solr_save end
  end
end