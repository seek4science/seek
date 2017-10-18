# encoding: utf-8

require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'colorize'
require 'seek/mime_types'

include Seek::MimeTypes

namespace :seek do
  # these are the tasks required for this version upgrade
  task upgrade_version_tasks: %i[
    environment

    update_ontology_settings_for_jerm
    update_assay_and_tech_types
    resynchronise_ontology_types
    update_relationship_types
    flag_simulation_data
    rebuild_rdf
    generate_organism_uuids
    strip_weblinks

  ]

  # these are the tasks that are executes for each upgrade as standard, and rarely change
  task standard_upgrade_tasks: %i[
    environment
    clear_filestore_tmp
    repopulate_auth_lookup_tables
  ]

  desc('upgrades SEEK from the last released version to the latest released version')
  task(upgrade: [:environment, 'db:migrate', 'tmp:clear']) do
    solr = Seek::Config.solr_enabled
    Seek::Config.solr_enabled = false

    Rake::Task['seek:standard_upgrade_tasks'].invoke
    Rake::Task['seek:upgrade_version_tasks'].invoke

    Seek::Config.solr_enabled = solr
    Rake::Task['seek:reindex_all'].invoke if solr

    puts 'Upgrade completed successfully'
  end

  task(update_ontology_settings_for_jerm: :environment) do
    if Seek::Config.assay_type_ontology_file=='JERM-RDFXML.owl'
      Seek::Config.assay_type_ontology_file='JERM.rdf'
    end

    if Seek::Config.assay_type_base_uri=="http://www.mygrid.org.uk/ontology/JERMOntology#Experimental_assay_type"
      Seek::Config.assay_type_base_uri="http://jermontology.org/ontology/JERMOntology#Experimental_assay_type"
    end

    if Seek::Config.technology_type_ontology_file=='JERM-RDFXML.owl'
      Seek::Config.technology_type_ontology_file='JERM.rdf'
    end

    if Seek::Config.technology_type_base_uri=="http://www.mygrid.org.uk/ontology/JERMOntology#Technology_type"
      Seek::Config.technology_type_base_uri="http://jermontology.org/ontology/JERMOntology#Technology_type"
    end

    if Seek::Config.modelling_analysis_type_ontology_file=='JERM-RDFXML.owl'
      Seek::Config.modelling_analysis_type_ontology_file='JERM.rdf'
    end

    if Seek::Config.modelling_analysis_type_base_uri=="http://www.mygrid.org.uk/ontology/JERMOntology#Model_analysis_type"
      Seek::Config.modelling_analysis_type_base_uri="http://jermontology.org/ontology/JERMOntology#Model_analysis_type"
    end
  end

  task(update_assay_and_tech_types: :environment) do
    disable_authorization_checks do
      Assay.where("assay_type_uri LIKE ?",'%www.mygrid.org.uk%').each do |assay|
        new_uri = assay.assay_type_uri.gsub('www.mygrid.org.uk','jermontology.org')
        puts new_uri
        assay.update_attribute(:assay_type_uri,new_uri)
      end

      Assay.where("technology_type_uri LIKE ?",'%www.mygrid.org.uk%').each do |assay|
        new_uri = assay.technology_type_uri.gsub('www.mygrid.org.uk','jermontology.org')
        assay.update_attribute(:technology_type_uri,new_uri)
      end

      SuggestedAssayType.where("ontology_uri LIKE ?",'%www.mygrid.org.uk%').each do |type|
        new_uri = type.ontology_uri.gsub('www.mygrid.org.uk','jermontology.org')
        type.update_attribute(:ontology_uri,new_uri)
      end

      SuggestedTechnologyType.where("ontology_uri LIKE ?",'%www.mygrid.org.uk%').each do |type|
        new_uri = type.ontology_uri.gsub('www.mygrid.org.uk','jermontology.org')
        type.update_attribute(:ontology_uri,new_uri)
      end
    end
  end

  task(update_relationship_types: [:environment, 'db:seed:relationship_types']) do; end

  task(flag_simulation_data: :environment) do
    disable_authorization_checks do
      AssayAsset.simulation.where(asset_type: 'DataFile').collect(&:asset).uniq.each do |data_file|
        data_file.update_attributes(simulation_data: true)
      end
    end
  end

  #cleans old the old rdf, and triggers a task to create jobs to build new rdf
  task(rebuild_rdf: :environment) do
    dir = Seek::Config.rdf_filestore_path
    if Dir.exist?(dir)
      FileUtils.rm_r(dir,force:true)
    end
    Rake::Task['seek_rdf:generate'].invoke
  end

  task(generate_organism_uuids: :environment) do
    Organism.all.each do |org|
      org.check_uuid
      org.record_timestamps = false
      org.save(validate:false)
    end
  end

  task(strip_weblinks: :environment) do

    #Person webpage
    Person.select{|p| !p.web_page.blank?}.select{|p| p.web_page != p.web_page.strip}.each do |person|
      person.record_timestamps = false
      puts "Fixing '#{person.web_page}' for Person:#{person.id}"
      person.web_page = person.web_page.strip
      disable_authorization_checks do
        person.save(validate:false)
      end
    end

    #Project webpage
    Project.select{|p| !p.web_page.blank?}.select{|p| p.web_page != p.web_page.strip}.each do |project|
      project.record_timestamps = false
      puts "Fixing '#{project.web_page}' for Project:#{project.id}"
      project.web_page = project.web_page.strip
      disable_authorization_checks do
        project.save(validate:false)
      end
    end

    #Project wiki page
    Project.select{|p| !p.wiki_page.blank?}.select{|p| p.wiki_page != p.wiki_page.strip}.each do |project|
      project.record_timestamps = false
      puts "Fixing '#{project.wiki_page}' for Project:#{project.id}"
      project.wiki_page = project.wiki_page.strip
      disable_authorization_checks do
        project.save(validate:false)
      end
    end

    #Programme webpage
    Programme.select{|p| !p.web_page.blank?}.select{|p| p.web_page != p.web_page.strip}.each do |prog|
      prog.record_timestamps = false
      puts "Fixing '#{prog.web_page}' for Programme:#{prog.id}"
      prog.web_page = prog.web_page.strip
      disable_authorization_checks do
        project.save(validate:false)
      end
    end

    #Institution webpage
    Institution.select{|i| !i.web_page.blank?}.select{|i| i.web_page != i.web_page.strip}.each do |institution|
      institution.record_timestamps = false
      puts "Fixing '#{institution.web_page}' for Institution:#{institution.id}"
      institution.web_page = institution.web_page.strip
      disable_authorization_checks do
        institution.save(validate:false)
      end
    end

  end

end
