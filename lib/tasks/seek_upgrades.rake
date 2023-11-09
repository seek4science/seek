# frozen_string_literal: true

require 'rubygems'
require 'rake'


namespace :seek do
  # these are the tasks required for this version upgrade
  task upgrade_version_tasks: %i[
    environment
    strip_sample_attribute_pids
    rename_registered_sample_multiple_attribute_type
    remove_ontology_attribute_type
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
