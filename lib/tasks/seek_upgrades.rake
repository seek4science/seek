# frozen_string_literal: true

require 'rubygems'
require 'rake'


namespace :seek do
  # these are the tasks required for this version upgrade
  task upgrade_version_tasks: %i[
    environment
    db:seed:007_sample_attribute_types
    update_rdf
    update_observation_unit_policies
    fix_xlsx_marked_as_zip
    add_policies_to_existing_sample_types
    fix_previous_sample_type_permissions
  ]

  # these are the tasks that are executes for each upgrade as standard, and rarely change
  task standard_upgrade_tasks: %i[
    environment
    clear_filestore_tmp
  ]

  desc('upgrades SEEK from the last released version to the latest released version')
  task(upgrade: [:environment]) do
    puts 'Starting upgrade ...'
    puts '... migrating database ...'
    Rake::Task['db:migrate'].invoke
    Rake::Task['tmp:clear'].invoke
    Rails.cache.clear

    solr = Seek::Config.solr_enabled
    Seek::Config.solr_enabled = false

    begin
      puts '... performing upgrade tasks ...'
      Rake::Task['seek:standard_upgrade_tasks'].invoke
      Rake::Task['seek:upgrade_version_tasks'].invoke

      Seek::Config.solr_enabled = solr
      puts '... queuing search reindexing jobs ...'
      Rake::Task['seek:reindex_all'].invoke if solr

      puts 'Upgrade completed successfully'
    ensure
      Seek::Config.solr_enabled = solr
    end
  end

  # if rdf repository enabled then generate jobs, otherwise just clear the cache. Only runs once
  task(update_rdf: [:environment]) do
    only_once('seek:update_rdf 1.16.1') do
      if Seek::Rdf::RdfRepository.instance&.configured?
        puts '... triggering rdf generation jobs'
        Rake::Task['seek_rdf:generate'].invoke
      else
        path = Seek::Config.rdf_filestore_path
        unless Dir.empty?(path)
          puts "... clearing rdf cache at #{path}"
          FileUtils.rm_rf(path, secure: true)
        end
      end
    end
  end

  task(update_observation_unit_policies: [:environment]) do
    puts '..... creating observation unit policies ...'
    affected_obs_units = []
    ObservationUnit.where.missing(:policy).includes(:study).in_batches(of: 25) do |batch|
      batch.each do |obs_unit|
        policy = obs_unit.study.policy || Policy.default
        policy = policy.deep_copy
        policy.save
        obs_unit.update_column(:policy_id, policy.id)
        affected_obs_units << obs_unit
      end
      putc('.')
    end
    AuthLookupUpdateQueue.enqueue(affected_obs_units)
    RdfGenerationQueue.enqueue(affected_obs_units)
    puts "..... finished updating policies for #{affected_obs_units.count} observation units"
  end

  task(fix_xlsx_marked_as_zip: [:environment]) do
    blobs = ContentBlob.where('original_filename LIKE ?','%.xlsx').where(content_type: 'application/zip')
    if blobs.any?
      n = blobs.count
      blobs.update_all(content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      puts "... fixed #{n} XLSX blobs with zip content type"
    end
  end

  task(add_policies_to_existing_sample_types: [:environment]) do
    puts '... Adding policies to existing sample types'
    counter = 0
    disable_authorization_checks do
      SampleType.includes(:projects, :assays, :studies).where(policy_id: nil).each do |st|
        if st.is_isa_json_compliant?
          st.update_column(:policy_id, st.assays.first.policy_id) if st.assays.any?
          st.update_column(:policy_id, st.studies.first.policy_id) if st.studies.any?
        else
          policy = Policy.new
          policy.name = 'default policy'

          # Visible if linked to public samples
          if st.samples.any? { |sample| sample.is_published? }
            policy.access_type = Policy::ACCESSIBLE
          else
            policy.access_type = Policy::NO_ACCESS
          end
          # Visible to each project
          st.projects.map do |project|
            policy.permissions << Permission.new(contributor_type: Permission::PROJECT, contributor_id: project.id, access_type: Policy::ACCESSIBLE)
          end
          # Project admins can manage
          project_admins = st.projects.map(&:project_administrators).flatten
          project_admins.map do |admin|
            policy.permissions << Permission.new(contributor_type: Permission::PERSON, contributor_id: admin.id, access_type: Policy::MANAGING)
          end

          policy.save
          st.update_column(:policy_id, policy.id)
        end
        putc('.')
        counter += 1
      end
    end
    puts "... Added policies to #{counter} sample types"
  end

  task(fix_previous_sample_type_permissions: [:environment]) do
    only_once('fix_previous_sample_type_permissions 1.16.0') do
      puts '... Updating previous sample type permissions ...'
      SampleType.includes(:policy).where.not(policy_id: nil).each do |sample_type|
        policy = sample_type.policy
        if policy.access_type == Policy::VISIBLE
          policy.update_column(:access_type, Policy::ACCESSIBLE)
        end
        policy.permissions.where(access_type: Policy::VISIBLE).where(contributor_type: Permission::PROJECT).update_all(access_type: Policy::ACCESSIBLE)
        putc('.')
      end
      AuthLookupUpdateQueue.enqueue(SampleType.all)
      puts '... Finished updating previous sample type permissions'
    end
  end

  private

  ##
  # Runs the block for the given task only once.
  # @param task [Rake::Task, String] The task or task name to remember.
  # @return [Boolean] Whether the block executed or not.
  def only_once(task, &block)
    log_action = "UPGRADE-#{task}" # Will convert Rake::Task to string which is the task name (e.g. seek:some_task_name)
    if ActivityLog.where(action: log_action).empty?
      block.call
      ActivityLog.create!(action: log_action, data: "#{Seek::Version::APP_VERSION} upgrade task")
      true
    else
      false
    end
  end
end
