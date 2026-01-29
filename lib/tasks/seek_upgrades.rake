# frozen_string_literal: true

require 'rubygems'
require 'rake'


namespace :seek do
  # these are the tasks required for this version upgrade
  task upgrade_version_tasks: %i[
    environment
    db:seed:011_topics_controlled_vocab
    db:seed:012_operations_controlled_vocab
    db:seed:013_data_formats_controlled_vocab
    db:seed:014_data_types_controlled_vocab
    db:seed:003_model_formats
    db:seed:004_model_recommended_environments
    db:seed:004_model_types
    db:seed:005_publication_types
    update_rdf
    update_morpheus_model
    db:seed:018_discipline_vocab
    strip_publication_abstracts
    db:seed:019_sop_type_controlled_vocab
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
    only_once('seek:update_rdf 1.17.0') do
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

  task(update_morpheus_model: [:environment]) do
    puts "... updating morpheus model"
    affected_models = []
    errors = []
    Model.find_each do |model|
      next unless model.is_morpheus_supported?
      begin
        unless model.model_format
          model.model_format = ModelFormat.find_by!(title: 'Morpheus')
        end
        unless model.recommended_environment
          model.recommended_environment = RecommendedModelEnvironment.find_by!(title: 'Morpheus')
        end
      rescue ActiveRecord::RecordNotFound => e
        error_message = "Error: #{e.message}. Ensure that the required 'Morpheus' records exist in the database."
        puts error_message
        errors << error_message
        next
      end
      model.update_columns(model_format_id: model.model_format_id, recommended_environment_id: model.recommended_environment_id)
      affected_models << model
    end
    ReindexingQueue.enqueue(affected_models)
    puts "... reindexing job triggered for #{affected_models.count} models"
    unless errors.empty?
      puts "The following errors were encountered during the update:"
      errors.each { |error| puts error }
    end
  end

  task(strip_publication_abstracts: [:environment]) do
    puts 'Stripping publication abstracts...'
    updated_count = 0
    Publication.select(:id, :abstract).find_each do |publication|
      if publication.abstract.present?
        stripped = publication.abstract.strip
        if stripped.length != publication.abstract.length
          publication.update_column(:abstract, stripped)
          updated_count += 1
        end
      end
    end
    puts "... updated #{updated_count} publications"
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
