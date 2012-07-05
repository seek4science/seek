require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'

namespace :seek do
  
  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks=>[
            :environment,
            :relink_strains,
            :repopulate_auth_lookup_tables,
            :rebuild_default_subscriptions,
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
    ReindexingJob.add_items_to_queue Investigation.all, 5.seconds.from_now,2
    ReindexingJob.add_items_to_queue Project.all, 5.seconds.from_now,2
    ReindexingJob.add_items_to_queue Strain.all, 5.seconds.from_now,2
    ReindexingJob.add_items_to_queue Specimen.all, 5.seconds.from_now,2
    ReindexingJob.add_items_to_queue Sample.all, 5.seconds.from_now,2
  end


  task :relink_strains => :environment do
    disable_authorization_checks do
      Strain.all.select{|s| s.organism.nil?}.each do |s|
        s.destroy
      end
    end

    strains = YAML.load_file(File.join(Rails.root,"config","default_data","strains.yml"))
    disable_authorization_checks do
      strains.keys.each do |key|
        strain = strains[key]
        title = strain["title"]
        organism = strain["organism"]
        if (Strain.find_by_title(title).nil?)
          o = Organism.find_by_title(organism)
          if (!o.nil?)
            s = Strain.new :title=>title, :organism=>o
            policy = Policy.public_policy
            policy.save
            s.policy_id = policy.id
            s.save!
          end
        end
      end
    end
  end

  #reverts to use pre-2.3.4 id generation to keep generated ID's consistent
  def revert_fixtures_identify
    def Fixtures.identify(label)
      label.to_s.hash.abs
    end
  end

  desc "Resubscribe all existing people by their projects with weekly frequency"
  task :rebuild_default_subscriptions => :environment do
    puts "Rebuilding subscription details - this can take some time so please be patient!"
    ProjectSubscription.delete_all
    Subscription.delete_all
    Person.all(:order=>:id).each do |p|
      p.set_default_subscriptions
      disable_authorization_checks { p.save(false) }
      puts "\tcompleted for person id:#{p.id}"
    end
    puts "Finished rebuilding subscription details"
  end
end
