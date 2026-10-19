# frozen_string_literal: true

require 'rubygems'
require 'rake'

namespace :seek do
  # these are the tasks required for this version upgrade
  task upgrade_version_tasks: %i[
    environment
    db:seed:019_sop_type_controlled_vocab
    migrate_delayed_jobs_to_solid_queue
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
    Rake::Task['seek:clear_cache'].invoke

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
    only_once('seek:update_rdf 1.18.0') do
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

  desc('migrates any jobs left in the delayed_jobs table into Solid Queue (one-off, post-cutover)')
  task(migrate_delayed_jobs_to_solid_queue: [:environment]) do
    only_once('seek:migrate_delayed_jobs_to_solid_queue 1.19.0') do
      puts '... migrating any remaining delayed_jobs into Solid Queue'
      result = Seek::DelayedJobMigrator.run(logger: ->(message) { puts "    #{message}" })
      puts "... #{result.summary}"
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
