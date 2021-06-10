# frozen_string_literal: true

require 'rubygems'
require 'rake'


namespace :seek do
  # these are the tasks required for this version upgrade
  task upgrade_version_tasks: %i[
    environment    
    update_samples_json
    migrate_old_jobs
    delete_redundant_jobs
    set_version_visibility
    remove_old_project_join_logs
    fix_negative_programme_role_mask
    db:seed:007_sample_attribute_types
    db:seed:008_miappe_custom_metadata
    delete_users_with_invalid_person
    delete_specimen_activity_logs
    update_session_store
    update_cv_sample_templates
  ]

  # these are the tasks that are executes for each upgrade as standard, and rarely change
  task standard_upgrade_tasks: %i[
    environment
    clear_filestore_tmp
    repopulate_auth_lookup_tables
  ]

  desc('upgrades SEEK from the last released version to the latest released version')
  task(upgrade: [:environment]) do
    puts "Starting upgrade ..."
    puts "... trimming old session data ..."
    Rake::Task['db:sessions:trim'].invoke
    puts "... migrating database ..."
    Rake::Task['db:migrate'].invoke
    Rake::Task['tmp:clear'].invoke

    solr = Seek::Config.solr_enabled
    Seek::Config.solr_enabled = false

    begin
      puts "... performing upgrade tasks ..."
      Rake::Task['seek:standard_upgrade_tasks'].invoke
      Rake::Task['seek:upgrade_version_tasks'].invoke

      Seek::Config.solr_enabled = solr
      puts "... queuing search reindexing jobs ..."
      Rake::Task['seek:reindex_all'].invoke if solr

      puts 'Upgrade completed successfully'
    ensure
      Seek::Config.solr_enabled = solr
    end
  end

  task(update_samples_json: :environment) do
    puts '... converting stored sample JSON ...'
    SampleType.find_each do |sample_type|

      # gather the attributes that need updating
      attributes_for_update = sample_type.sample_attributes.select do |attr|
        attr.accessor_name != attr.original_accessor_name
      end
      

      if attributes_for_update.any?
        # work through each sample
        sample_type.samples.each do |sample|
          json = JSON.parse(sample.json_metadata)
          attributes_for_update.each do |attr|
            # replace the json key
            json[attr.accessor_name] = json.delete(attr.original_accessor_name)
          end
          sample.update_column(:json_metadata,json.to_json)
        end

        # update the original accessor name for each affected attribute
        attributes_for_update.each do |attr|
          attr.update_column(:original_accessor_name, attr.accessor_name)
        end
      end
    end
    puts " ... finished updating sample JSON"
  end  

  task(migrate_old_jobs: :environment) do
    puts "Migrating RdfGenerationJobs..."
    count = RdfGenerationQueue.count
    Delayed::Job.where(failed_at: nil).where('handler LIKE ?', '%RdfGenerationJob%').where('handler LIKE ?','%item_type_name%').find_each do |job|
      data = YAML.load(job.handler.sub("--- !ruby/object:RdfGenerationJob\n",''))
      item = nil
      begin
        item = data["item_type_name"].constantize.find(data["item_id"])
      rescue StandardError => e
        puts "Exception migrating job (#{job.id}) #{e.class} #{e.message}"
        puts e.backtrace.join("\n")
      else
        RdfGenerationQueue.enqueue(item, refresh_dependents: data["refresh_dependents"], queue_job: false) if item
        job.destroy
      end      
    end
    queued = (RdfGenerationQueue.count - count)
    RdfGenerationJob.new.queue_job if queued > 0
    puts "Queued RDF generation for #{queued} items"
  end

  task(delete_redundant_jobs: :environment) do
    puts "Deleting redundant jobs..."
    deleted = 0

    ['SendPeriodicEmailsJob', 'ContentBlobCleanerJob', 'NewsFeedRefreshJob', 'ProjectLeavingJob',
     'OpenbisEndpointCacheRefreshJob', 'OpenbisSyncJob', 'ReindexingJob'].each do |klass|
      jobs = Delayed::Job.where(failed_at: nil).where('handler LIKE ?', "%#{klass}%")
      deleted += jobs.count
      jobs.destroy_all
    end

    puts "Deleted #{deleted} jobs"
  end

  task(set_version_visibility: :environment) do
    puts "... Setting version visibility..."
    disable_authorization_checks do
      [DataFile::Version, Document::Version, Model::Version, Node::Version, Presentation::Version, Sop::Version, Workflow::Version].each do |klass|
        scope = klass.where(visibility: nil)
        count = scope.count
        if count == 0
          puts "  No #{klass.name} with unset visibility found, skipping"
          next
        else
          print "  Updating #{count} #{klass.name}'s visibility"
        end

        check_doi = klass.attribute_method?(:doi)
        # Go through all versions and set the "latest" versions to publicly visible
        scope.find_each do |version|
          if version.latest_version? || check_doi && version.doi.present?
            version.update_column(:visibility, Seek::ExplicitVersioning::VISIBILITY_INV[:public])
          else
            version.update_column(:visibility, Seek::ExplicitVersioning::VISIBILITY_INV[:registered_users])
          end
        end
        puts " - done"
      end
    end

    puts "... Done"
  end

  task(remove_old_project_join_logs: :environment) do
    puts "... Removing redundant project join request logs ..."
    logs = MessageLog.project_membership_requests
    logs.each do |log|
      begin
        JSON.parse(log.details)
      rescue JSON::ParserError
        log.destroy
      end
    end
    puts "... Done"
  end

  task(fix_negative_programme_role_mask: :environment) do
    problems = Person.where('roles_mask < 0')
    problems.each do |person|
      mask = person.roles_mask
      while mask < 0
        mask = mask + 32
      end
      person.update_column(:roles_mask,mask)
    end
  end

  # removes users with a person_id which no longer exist
  task(delete_users_with_invalid_person: :environment) do
    found = User.where.not(person:nil).select{|u| u.person.nil?}
    if found.any?
      puts "... Removing #{found.count} users with a no longer existing person"
      found.each(&:destroy)
    end
  end

  task(delete_specimen_activity_logs: :environment) do
    logs = ActivityLog.where(activity_loggable_type: 'Specimen')
    if logs.any?
      puts "... removing #{logs.count} redundant Specimen related #{'log'.pluralize(logs.count)}"
      logs.delete_all
    end
  end

  task(update_session_store: :environment) do
    puts '... Updating session store'
    Rake::Task['db:sessions:upgrade'].invoke
  end
  
  task(update_cv_sample_templates: :environment) do
    puts '... Queue jobs for Sample templates containing controlled vocabularies'
    SampleType.all.each do |st|
      if st.template && st.sample_attributes.detect(&:controlled_vocab?)
        st.queue_template_generation
      end
    end
  end
end
