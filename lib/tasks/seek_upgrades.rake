#encoding: utf-8
require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'colorize'
require 'seek/mime_types'

include Seek::MimeTypes

namespace :seek do

  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks => [
           :environment,
           :consolidate_news_feeds,
           :delete_orphaned_strains
       ]

  #these are the tasks that are executes for each upgrade as standard, and rarely change
  task :standard_upgrade_tasks => [
           :environment,
           :clear_filestore_tmp,
           :repopulate_auth_lookup_tables,
           :resynchronise_ontology_types
       ]

  desc("upgrades SEEK from the last released version to the latest released version")
  task(:upgrade => [:environment, "db:migrate", "tmp:clear"]) do

    solr=Seek::Config.solr_enabled
    Seek::Config.solr_enabled=false

    Rake::Task["seek:standard_upgrade_tasks"].invoke
    Rake::Task["seek:upgrade_version_tasks"].invoke

    Seek::Config.solr_enabled = solr
    if (solr)
      Rake::Task["seek:reindex_all"].invoke
    end

    puts "Upgrade completed successfully"
  end

  task(:consolidate_news_feeds=>:environment) do
    Seek::Config.news_enabled = Seek::Config.community_news_enabled || Seek::Config.project_news_enabled
    Seek::Config.news_feed_urls = [Seek::Config.community_news_feed_urls, Seek::Config.project_news_feed_urls].join(',')
    Seek::Config.news_number_of_entries = Seek::Config.community_news_number_of_entries +
        Seek::Config.project_news_number_of_entries
  end

  task(:delete_orphaned_strains=>:environment) do
    puts "Checking for orphaned Strains..."
    disable_authorization_checks do
      Strain.where("organism_id is NOT NULL").select { |s| s.organism.nil? }.each do |strain|
        puts "Deleting #{strain.title}"
        strain.destroy
      end
    end
    puts "Done"
  end

end
