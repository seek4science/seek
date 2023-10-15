# frozen_string_literal: true

require 'rubygems'
require 'rake'


namespace :seek do
  # these are the tasks required for this version upgrade
  task upgrade_version_tasks: %i[
    environment
    decouple_extracted_samples_policies
    decouple_extracted_samples_projects
  ]

  # these are the tasks that are executes for each upgrade as standard, and rarely change
  task standard_upgrade_tasks: %i[
    environment
    clear_filestore_tmp
  ]

  desc('upgrades SEEK from the last released version to the latest released version')
  task(upgrade: [:environment]) do
    puts 'Starting upgrade ...'
    puts '... trimming old session data ...'
    Rake::Task['db:sessions:trim'].invoke
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

  task(decouple_extracted_samples_policies: [:environment]) do
    puts '... creating independent policies for extracted samples...'
    decoupled = 0
    disable_authorization_checks do
      Sample.find_each do |sample|
        # check if the sample was extracted from a datafile and their policies are linked
        if sample.extracted? && sample.policy == sample.originating_data_file&.policy
          sample.policy = sample.policy.deep_copy
          sample.policy.save
          decoupled += 1
        end
      end
    end
    puts " ... finished creating independent policies of #{decoupled.to_s} extracted samples"
  end

  task(decouple_extracted_samples_projects: [:environment]) do
    puts '... copying project ids for extracted samples...'
    decoupled = 0
    hash_array = []
    disable_authorization_checks do
      Sample.find_each do |sample|
        # check if the sample was extracted from a datafile and their projects are linked
        if sample.extracted? && sample.project_ids.empty?
          sample.originating_data_file.project_ids.each do |project_id|
            hash_array << { project_id: project_id, sample_id: sample.id }
          end
          decoupled += 1
        end
      end
      unless hash_array.empty?
        class ProjectsSample < ActiveRecord::Base; end;
        ProjectsSample.insert_all(hash_array)
      end
    end
    puts " ... finished copying project ids of #{decoupled.to_s} extracted samples"
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
