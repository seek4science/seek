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
    strip_sample_attribute_pids
    rename_registered_sample_multiple_attribute_type
    remove_ontology_attribute_type
    db:seed:007_sample_attribute_types
    recognise_isa_json_compliant_items
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

  task(rename_registered_sample_multiple_attribute_type: [:environment]) do
    attr = SampleAttributeType.find_by(title:'Registered Sample (multiple)')
    if attr
      puts "..... Renaming sample attribute type 'Registered Sample (multiple)' to 'Registered Sample List'."
      attr.update_column(:title, 'Registered Sample List')
    end
  end

  task(strip_sample_attribute_pids: [:environment]) do
    puts '..... Stripping Sample Attribute PIds ...'
    n = 0
    SampleAttribute.where('pid is NOT NULL AND pid !=?','').each do |attribute|
      new_pid = attribute.pid.strip
      if attribute.pid != new_pid
        attribute.update_column(:pid, new_pid)
        n += 1
      end
    end
    puts "..... Finished stripping #{n} Sample Attribute PIds."
  end

  task(remove_ontology_attribute_type: [:environment]) do
    ontology_attr_type = SampleAttributeType.find_by(title:'Ontology')
    cv_attr_type = SampleAttributeType.find_by(title:'Controlled Vocabulary')
    if ontology_attr_type
      puts '..... Removing the Ontology sample attribute type ...'
      if cv_attr_type
        if ontology_attr_type.sample_attributes.any?
          puts "..... Moving #{ontology_attr_type.sample_attributes.count} sample attributes to Controlled Vocabulary"
          ontology_attr_type.sample_attributes.each do |attr_type|
            attr_type.update_column(:sample_attribute_type_id, cv_attr_type.id)
          end
        end
        if ontology_attr_type.isa_template_attributes.any?
          puts "..... Moving #{ontology_attr_type.isa_template_attributes.count} template attributes to Controlled Vocabulary"
          ontology_attr_type.isa_template_attributes.each do |attr_type|
            attr_type.update_column(:sample_attribute_type_id, cv_attr_type.id)
          end
        end

        ontology_attr_type.destroy
      else
        puts '..... Target Controlled Vocabulary attribute type not found'
      end
    end
  end

  task(decouple_extracted_samples_policies: [:environment]) do
    puts '..... creating independent policies for extracted samples (this can take a while if there are many samples) ...'
    affected_samples = []
    disable_authorization_checks do
      Sample.includes(:originating_data_file).find_each do |sample|
        # check if the sample was extracted from a datafile and their policies are linked
        if sample.extracted? && sample.policy_id == sample.originating_data_file&.policy_id
          policy = sample.policy.deep_copy
          policy.save
          sample.update_column(:policy_id, policy.id)
          putc('.')
          affected_samples << sample
        end
      end
      #won't have been queued, as the policy has no associated assets yet when saved
      AuthLookupUpdateQueue.enqueue(affected_samples) if affected_samples.any?
    end
    puts "..... finished creating independent policies of #{affected_samples.count} extracted samples"
  end

  task(decouple_extracted_samples_projects: [:environment]) do
    puts '..... copying project ids for extracted samples...'
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
                                      .where('investigations.is_isa_json_compliant = ?', false)
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
