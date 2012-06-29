require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'

namespace :seek do
  
  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks=>[
            :environment,
            :rebuild_default_subscriptions
  ]

  desc("upgrades SEEK from the last released version to the latest released version")
  task(:upgrade=>[:environment,"db:migrate","tmp:clear","tmp:assets:clear"]) do
    
    solr=Seek::Config.solr_enabled

    Seek::Config.solr_enabled=false

    Rake::Task["seek:upgrade_version_tasks"].invoke

    Seek::Config.solr_enabled = solr

    begin
      Rake::Task["sunspot:solr:reindex"].invoke if solr
    rescue 
      puts "Reindexing failed - maybe solr isn't running?' - Error: #{$!}."
      puts "If not You should start solr and run rake sunspot:reindex manually"
    end

    puts "Upgrade completed successfully"
  end


  desc "removes the older duplicate create activity logs that were added for a short period due to a bug (this only affects versions between stable releases)"
  task(:remove_duplicate_activity_creates=>:environment) do
    ActivityLog.remove_duplicate_creates
  end

  desc "Resubscribe all existing people by their projects with weekly frequency"
  task :rebuild_default_subscriptions => :environment do
    ProjectSubscription.delete_all
    Subscription.delete_all
    Person.all.each do |p|
      p.set_default_subscriptions
      disable_authorization_checks { p.save(false) }
    end
  end
end
