# frozen_string_literal: true

require 'rubygems'
require 'rake'


namespace :seek do
  # these are the tasks required for this version upgrade
  task upgrade_version_tasks: %i[
    environment
    db:seed:007_sample_attribute_types
    update_missing_openbis_istest
    update_missing_publication_versions
    update_edam_controlled_vocab_keys
    db:seed:011_topics_controlled_vocab
    db:seed:012_operations_controlled_vocab
    db:seed:013_formats_controlled_vocab
    db:seed:014_data_controlled_vocab
    db:seed:015_isa_tags
    db:seed:003_model_formats
    db:seed:004_model_recommended_environments
    remove_orphaned_versions
    seek:rebuild_workflow_internals
    remove_scale_annotations
    remove_spreadsheet_annotations
    convert_roles
    update_edam_annotation_attributes
    remove_orphaned_project_subscriptions
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

  task(update_missing_openbis_istest: :environment) do
    puts '... creating missing is_test for OpenbisEndpoint...'
    create = 0
    disable_authorization_checks do
      OpenbisEndpoint.find_each do |openbis_endpoint|
        # check if the publication has a version
        # then create one if missing
        if openbis_endpoint.is_test.nil?
          openbis_endpoint.is_test = false # default -> prod, https
          openbis_endpoint.save
          unless openbis_endpoint.is_test.nil?
            create += 1
          end
        end
        # publication.save
      end
    end
    puts " ... finished creating missing is_test for #{create.to_s} OpenbisEndpoint(s)"
  end

  task(update_missing_publication_versions: :environment) do
    puts '... creating missing publications versions ...'
    create = 0
    disable_authorization_checks do
      Publication.find_each do |publication|
        # check if the publication has a version
        # then create one if missing
        if publication.latest_version.nil?
          publication.save_as_new_version 'Version for legacy entries'
          unless publication.latest_version.nil?
            create += 1
          end
        end
        # publication.save
      end
    end
    puts " ... finished creating missing publications versions for #{create.to_s} publications"
  end

  task(remove_orphaned_versions: [:environment]) do
    puts 'Removing orphaned versions ...'
    count = 0
    types = [DataFile::Version, Document::Version, Sop::Version, Model::Version, Presentation::Version,
             Sop::Version, Workflow::Version]
    disable_authorization_checks do
      types.each do |type|
        found = type.where.missing(:parent)
        count += found.length
        found.each(&:destroy)
      end
    end
    puts "... finished removing #{count} orphaned versions"
  end

  task(convert_mysql_charset: [:environment]) do
    if ActiveRecord::Base.connection.instance_values["config"][:adapter] == 'mysql2'
      puts "Attempting MySQL database conversion"
      # Get charset from database.yml, then find appropriate collation from mysql
      db = ActiveRecord::Base.connection.current_database
      charset = ActiveRecord::Base.connection.instance_values["config"][:encoding] || 'utf8mb4'
      collation = "#{charset}_unicode_ci" # Prefer e.g. utf8_unicode_ci over utf8_general_ci
      collation = ActiveRecord::Base.connection.execute("SHOW COLLATION WHERE Charset = '#{charset}' AND Collation = '#{collation}';").first&.first
      unless collation
        # Pick default collation for given charset if above collation not available
        collation = ActiveRecord::Base.connection.execute("SHOW COLLATION WHERE Charset = '#{charset}' `Default` = 'Yes';").first&.first
        unless collation
          puts "Could not find collation for charset: #{charset}, aborting"
          return
        end
      end

      puts "Converting database: #{db} to character set: #{charset}, collation: #{collation}"

      # Set database defaults
      puts "Setting default charset and collation"
      ActiveRecord::Base.connection.execute("ALTER DATABASE #{db} DEFAULT CHARACTER SET #{charset} DEFAULT COLLATE #{collation};")

      # Set/convert each table
      tables = ActiveRecord::Base.connection.exec_query("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA='#{db}' AND TABLE_COLLATION != '#{collation}';").rows.flatten
      puts "#{tables.count} tables to convert"
      tables.each do |table|
        puts "  Converting #{table}"
        ActiveRecord::Base.connection.execute("ALTER TABLE #{table} CONVERT TO CHARACTER SET #{charset} COLLATE #{collation};")
      end
      puts "Done"
    else
      puts "Database adapter is: #{ActiveRecord::Base.connection.instance_values["config"][:adapter]}, doing nothing"
    end
  end

  task(remove_scale_annotations: [:environment]) do
    a = Annotation.joins(:annotation_attribute).where(annotation_attribute: { name: ['additional_scale_info', 'scale'] })
    count = a.count
    a.destroy_all
    AnnotationAttribute.where(name:['scale','additional_scale_info']).destroy_all
    puts "Removed #{count} scale related annotations" if count > 0
  end

  task(remove_spreadsheet_annotations: [:environment]) do
    annotations = Annotation.where(annotatable_type: 'CellRange')
    count = annotations.count
    values = TextValue.joins(:annotations).where(annotations: { annotatable_type: 'CellRange' })
    values.select{|v| v.annotations.count == 1}.each(&:destroy)
    annotations.destroy_all
    AnnotationAttribute.where(name:'annotation').destroy_all
    puts "Removed #{count} spreadsheet related annotations" if count > 0
  end

  task(convert_roles: [:environment]) do
    puts 'Converting roles...'
    disable_authorization_checks do
      Person.find_each do |person|
        RoleType.for_system.each do |rt|
          mask = rt.id
          if (person.roles_mask & mask) != 0
            Role.where(role_type_id: rt.id, person_id: person.id, scope: nil).first_or_create!
          end
        end
      end

      class AdminDefinedRoleProject < ActiveRecord::Base; end

      AdminDefinedRoleProject.find_each do |role|
        RoleType.for_projects.each do |rt|
          mask = rt.id
          if (role.role_mask & mask) != 0
            Role.where(role_type_id: rt.id, person_id: role.person_id,
                       scope_type: 'Project', scope_id: role.project_id).first_or_create!
          end
        end
      end

      class AdminDefinedRoleProgramme < ActiveRecord::Base; end

      AdminDefinedRoleProgramme.find_each do |role|
        RoleType.for_programmes.each do |rt|
          mask = rt.id
          if (role.role_mask & mask) != 0
            Role.where(role_type_id: rt.id, person_id: role.person_id,
                       scope_type: 'Programme', scope_id: role.programme_id).first_or_create!
          end
        end
      end
    end
  end

  task(update_edam_annotation_attributes: [:environment]) do
    defs = {
      "edam_formats": "data_format_annotations",
      "edam_topics": "topic_annotations",
      "edam_operations": "operation_annotations",
      "edam_data": "data_type_annotations"
    }
    defs.each do |old_name,new_name|
      query = AnnotationAttribute.where(name: old_name)
      if query.any?
        puts "Updating EDAM based #{old_name} Annotation Attributes"
        query.update_all(name: new_name)
      end
    end
  end

  task(update_edam_controlled_vocab_keys: [:environment]) do
    defs = {
      topics: 'edam_topics',
      operations: 'edam_operations',
      data_formats: 'edam_formats',
      data_types: 'edam_data'
    }

    defs.each do |property, old_key|
      new_key = SampleControlledVocab::SystemVocabs.database_key_for_property(property)
      query = SampleControlledVocab.where(key: old_key)
      if query.any?
        puts "Updating key for #{old_key} controlled vocabulary"
        query.update_all(key: new_key)
      end
    end
  end

  task(remove_orphaned_project_subscriptions: [:environment]) do
    disable_authorization_checks do
      ProjectSubscription.where.missing(:project).destroy_all
    end
  end

end
