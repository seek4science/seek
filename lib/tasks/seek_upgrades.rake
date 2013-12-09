require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'uuidtools'
require 'colorize'


namespace :seek do

  #these are the tasks required for this version upgrade
  task :upgrade_version_tasks=>[
            :environment,
            :update_admin_assigned_roles,
            :repopulate_auth_lookup_tables,
            :increase_sheet_empty_rows
  ]

  desc("upgrades SEEK from the last released version to the latest released version")
  task(:upgrade=>[:environment,"db:migrate","db:sessions:clear","tmp:clear","tmp:assets:clear"]) do
    
    solr=Seek::Config.solr_enabled

    Seek::Config.solr_enabled=false

    Rake::Task["seek:upgrade_version_tasks"].invoke

    Seek::Config.solr_enabled = solr

    if (solr)
      Rake::Task["seek:reindex_all"].invoke
    end

    puts "Upgrade completed successfully"
  end

  task(:update_admin_assigned_roles=>:environment) do
    Person.where("roles_mask > 0").each do |p|
      if p.admin_defined_role_projects.empty?
        roles = []
        (p.role_names & Person::PROJECT_DEPENDENT_ROLES).each do |role|
          puts "Updating #{p.name} for - '#{role}' - adding to #{p.projects.count} projects"
          roles << [role,p.projects]
        end
        roles << ["admin"] if p.is_admin?
        unless roles.empty?
          Person.record_timestamps = false
          begin
            p.roles = roles
            disable_authorization_checks do
              p.save!
            end
          rescue Exception=>e
            puts "Error saving #{p.name} - #{p.id}: #{e.message}"
          ensure
            Person.record_timestamps = true
          end
        end

      end

    end
  end


  desc("Increase the min rows from 10 to 35")
  task(:increase_sheet_empty_rows => :environment) do
    worksheets = Worksheet.all.compact
    min_rows = Seek::Data::SpreadsheetExplorerRepresentation::MIN_ROWS
    worksheets.each do |ws|
      if ws.last_row < min_rows
        ws.last_row = min_rows
        ws.save
      end
    end
  end

  desc("Synchronised the assay types assigned to assays according to the current ontology")
  task(:resynchronise_assay_types => :environment) do
    label_map = {"generic experimental assay"=>"experimental assay type",
                 "generic modelling analysis"=>"model analysis type",
                 "cdna microarray"=>"transcriptional profiling",
                 "modelling analysis type"=>"model analysis type"}

    Assay.record_timestamps = false

    Assay.all.each do |assay|
      assay_type_label_hash = assay.assay_type_reader.class_hierarchy.hash_by_label

      label = assay[:assay_type_label].try(:downcase)

      unless label.nil?
        #check to see if the label can resolve to a uri
        resolved_uri = assay_type_label_hash[label].try(:uri).try(:to_s)

        #if the resolved uri is nil try a mapped label
        resolved_uri ||= assay_type_label_hash[label_map[label]].try(:uri).try(:to_s)

        #if the uri is resovled, update the stored uri and remove the label
        unless resolved_uri.nil?
          if assay.assay_type_uri != resolved_uri
            assay.assay_type_uri = resolved_uri
            puts "the assay type URI for Assay #{assay.id} updated to #{resolved_uri.inspect} based on the label #{label.inspect}".green
          end
          assay.assay_type_label = nil
        end

      end

      unless assay.valid_assay_type_uri?
        #if the uri is still invalid, we need to set it to the default
        uri = assay[:assay_type_uri]
        puts "the assay type label and URI for Assay #{assay.id} cannot be resolved, so resetting the URI to the default, but keeping the stored label.\n\t the original label was #{label.inspect} and URI was #{uri.inspect}".red
        assay.use_default_assay_type_uri!
      end

      if !assay[:assay_type_label].nil? && assay_type_label_hash[assay.assay_type_label].nil?
         puts "The Assay #{assay.id} has a suggested assay type label of #{assay.assay_type_label}, currently attached to the parent URI #{assay.assay_type_uri}".yellow
      end

      disable_authorization_checks do
        assay.save if assay.changed?
      end

    end
    Assay.record_timestamps = true
  end

  desc("Synchronised the technology types assigned to assays according to the current ontology")
  task(:resynchronise_technology_types => :environment) do
    Assay.record_timestamps = false

    tech_type_label_hash = Seek::Ontologies::TechnologyTypeReader.instance.class_hierarchy.hash_by_label

    label_map = {"technology"=>"technology type",
                 "cdna microarray"=>"microarray",
                 "enzymatic activity experiments"=>"enzymatic activity measurements"}

    Assay.all.each do |assay|
      unless assay.is_modelling?
        label = assay[:technology_type_label].try(:downcase)
        unless label.nil?

          resolved_uri = tech_type_label_hash[label].try(:uri).try(:to_s)

          #if the resolved uri is nil try a mapped label
          resolved_uri ||= tech_type_label_hash[label_map[label]].try(:uri).try(:to_s)

          #if the uri is resovled, update the stored uri and remove the label
          unless resolved_uri.nil?
            if assay.technology_type_uri != resolved_uri
              assay.technology_type_uri = resolved_uri
              puts "the technology type URI for Assay #{assay.id} updated to #{resolved_uri.inspect} based on the label #{label.inspect}".green
            end
            assay.technology_type_label = nil
          end

        end
      else
        assay.technology_type_uri = nil
      end
      unless assay.valid_technology_type_uri?
        uri = assay[:technology_type_uri]
        puts "the technology type label and URI for Assay #{assay.id} cannot be resolved, so resetting the URI to the default, but keeping the stored label.\n\t the original label was #{label.inspect} and URI was #{uri.inspect}".red
        assay.use_default_technology_type_uri!
      end

      disable_authorization_checks do
        assay.save if assay.changed?
      end
      if !assay[:technology_type_label].nil? && tech_type_label_hash[assay.technology_type_label].nil?
        puts "The Assay #{assay.id} has a suggested technology type label of #{assay.technology_type_label}, currently attached to the parent URI #{assay.technology_type_uri}".yellow
      end
    end
    Assay.record_timestamps = true
  end

end
