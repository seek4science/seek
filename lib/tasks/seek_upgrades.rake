require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'

namespace :seek do
  
  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks=>[
            :environment,
            :reindex_things
  ]

  desc("upgrades SEEK from the last released version to the latest released version")
  task(:upgrade=>[:environment,"db:migrate","tmp:clear","tmp:assets:clear"]) do
    
    solr=Seek::Config.solr_enabled

    Seek::Config.solr_enabled=false

    Rake::Task["seek:upgrade_version_tasks"].invoke

    Seek::Config.solr_enabled = solr

    puts "Upgrade completed successfully"
  end


  desc "removes the older duplicate create activity logs that were added for a short period due to a bug (this only affects versions between stable releases)"
  task(:remove_duplicate_activity_creates=>:environment) do
    ActivityLog.remove_duplicate_creates
  end

  task :reindex_things => :environment do
    #reindex_all task doesn't seem to work as part of the upgrade, because it doesn't successfully discover searchable types (possibly due to classes being in memory before the migration)
    ReindexingJob.add_items_to_queue DataFile.all, 5.seconds.from_now,2
    ReindexingJob.add_items_to_queue Model.all, 5.seconds.from_now,2
    ReindexingJob.add_items_to_queue Sop.all, 5.seconds.from_now,2
    ReindexingJob.add_items_to_queue Publication.all, 5.seconds.from_now,2
    ReindexingJob.add_items_to_queue Presentation.all, 5.seconds.from_now,2

    ReindexingJob.add_items_to_queue Assay.all, 5.seconds.from_now,2
    ReindexingJob.add_items_to_queue Study.all, 5.seconds.from_now,2
    ReindexingJob.add_items_to_queue Investigation.all, 5.seconds.from_now,2

    ReindexingJob.add_items_to_queue Person.all, 5.seconds.from_now,2
    ReindexingJob.add_items_to_queue Project.all, 5.seconds.from_now,2
    ReindexingJob.add_items_to_queue Specimen.all, 5.seconds.from_now,2
    ReindexingJob.add_items_to_queue Sample.all, 5.seconds.from_now,2
  end
end
