# frozen_string_literal: true

require 'rubygems'
require 'rake'


namespace :seek do
  # these are the tasks required for this version upgrade
  task upgrade_version_tasks: %i[
    environment
    decouple_extracted_samples_policies
    decouple_extracted_samples_projects
    link_sample_datafile_attributes
    db:seed:007_sample_attribute_types
    db:seed:001_create_controlled_vocabs
    db:seed:017_minimal_starter_isa_templates
    recognise_isa_json_compliant_items
    implement_assay_streams_for_isa_assays
    set_ls_login_legacy_mode
    rename_custom_metadata_legacy_supported_type
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

  task(decouple_extracted_samples_policies: [:environment]) do
    puts '..... creating independent policies for extracted samples (this can take a while if there are many samples) ...'
    affected_samples = []

    Policy.skip_callback :commit, :after, :queue_update_auth_table
    Policy.skip_callback :commit, :after, :queue_rdf_generation_job
    Permission.skip_callback :commit, :after, :queue_update_auth_table
    Permission.skip_callback :commit, :after, :queue_rdf_generation_job

    disable_authorization_checks do
      Sample.includes(:originating_data_file).in_batches(of: 250) do |batch|
        batch.each do |sample|
          # check if the sample was extracted from a datafile and their policies are linked
          if sample.extracted? && sample.policy_id == sample.originating_data_file&.policy_id
            policy = sample.policy.deep_copy
            policy.save
            sample.update_column(:policy_id, policy.id)
            affected_samples << sample
          end
        end
        putc('.')
      end
    end
    puts "..... finished creating independent policies of #{affected_samples.count} extracted samples"
  ensure
    Policy.set_callback :commit, :after, :queue_update_auth_table
    Policy.set_callback :commit, :after, :queue_rdf_generation_job
    Permission.set_callback :commit, :after, :queue_update_auth_table
    Permission.set_callback :commit, :after, :queue_rdf_generation_job
  end

  task(decouple_extracted_samples_projects: [:environment]) do
    puts '..... copying project ids for extracted samples...'
    decoupled_count = 0
    hash_array = []
    disable_authorization_checks do
      Sample.includes(:originating_data_file).where.missing(:projects).in_batches(of: 250) do |batch|
        batch.each do |sample|
          # check if the sample was extracted from a datafile and their projects are linked
          if sample.extracted? && sample.project_ids.empty?
            sample.originating_data_file.project_ids.each do |project_id|
              hash_array << { project_id: project_id, sample_id: sample.id }
            end
            decoupled_count += 1
          end
        end
        putc('.')
      end
      unless hash_array.empty?
        class ProjectsSample < ActiveRecord::Base; end;
        ProjectsSample.insert_all(hash_array)
      end
    end
    puts " ... finished copying project ids of #{decoupled_count.to_s} extracted samples"
  end

  task(link_sample_datafile_attributes: [:environment]) do
    puts '... updating sample_resource_links for samples with data_file attributes...'
    samples_updated = 0
    disable_authorization_checks do
      df_attrs = SampleAttribute.joins(:sample_attribute_type).where('sample_attribute_types.base_type' => Seek::Samples::BaseType::SEEK_DATA_FILE).pluck(:id)
      samples = Sample.joins(sample_type: :sample_attributes).where('sample_attributes.id' => df_attrs)
      samples.each do |sample|
        if sample.sample_resource_links.where(resource_type: 'DataFile').empty?
          sample.send(:update_sample_resource_links)
          samples_updated += 1
        end
      end
    end
    puts " ... finished updating sample_resource_links of #{samples_updated.to_s} samples with data_file attributes"
  end

  task(recognise_isa_json_compliant_items: [:environment]) do
    puts '... searching for ISA compliant investigations'
    investigations_updated = 0
    disable_authorization_checks do
      investigations_to_update = Study.joins(:investigation)
                                   .where('investigations.is_isa_json_compliant IS NULL OR investigations.is_isa_json_compliant = ?', false)
                                      .select { |study| study.sample_types.any? }
                                      .map(&:investigation)
                                      .compact
                                      .uniq

      investigations_to_update.each do |inv|
        inv.update_column(:is_isa_json_compliant, true)
        investigations_updated += 1
      end
    end
    puts "...Updated #{investigations_updated.to_s} investigations"
  end

  task(implement_assay_streams_for_isa_assays: [:environment]) do
    puts '... Organising isa json compliant assays in assay streams'
    assay_streams_created = 0
    disable_authorization_checks do
      # find assays linked to a study through their sample_types
      # Should be isa json compliant
      # Shouldn't already have an assay stream (don't update assays that have been updated already)
      # Previous ST should be second ST of study
      first_assays_in_stream = Assay.joins(:sample_type, study: :investigation)
                                    .where(assay_stream_id: nil, investigation: { is_isa_json_compliant: true })
                                 .select { |a| a.sample_type.previous_linked_sample_type == a.study.sample_types.second }

      first_assays_in_stream.map do |fas|
        stream_name = "Assay Stream - #{UUID.generate}"
        assay_stream = Assay.create(title: stream_name,
                                    study_id: fas.study_id,
                                    assay_class_id: AssayClass.assay_stream.id,
                                    contributor: fas.contributor,
                                    position: 0)

        # Transfer extended metadata from first assay to newly created assay stream
        unless fas.extended_metadata.nil?
          em = ExtendedMetadata.find_by(item_id: fas.id)
          em.update_column(:item_id, assay_stream.id)
        end

        assay_position = 1
        current_assay = fas
        while current_assay
          current_assay.update_column(:position, assay_position)
          current_assay.update_column(:assay_stream_id, assay_stream.id)

          assay_position += 1
          current_assay = if current_assay.sample_type.nil?
                            nil
                          else
                            current_assay.sample_type.next_linked_sample_types.first&.assays&.first
                          end
        end
        assay_streams_created += 1
      end
    end

    puts "...Created #{assay_streams_created} new assay streams"
  end

  task(set_ls_login_legacy_mode: [:environment]) do
    only_once('ls_login_legacy') do
      if Seek::Config.omniauth_elixir_aai_enabled
        puts "Enabling LS Login legacy mode"
        Seek::Config.omniauth_elixir_aai_legacy_mode = true
      end
    end
  end

  task(rename_custom_metadata_legacy_supported_type: [:environment]) do
    if ExtendedMetadataType.where(supported_type: 'CustomMetadata').any?
      puts "... Renaming ExtendedMetadata supported_type from Custom to ExtendedMetadata"
      ExtendedMetadataType.where(supported_type: 'CustomMetadata').update_all(supported_type: 'ExtendedMetadata')
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
