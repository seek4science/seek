# encoding: utf-8
# frozen_string_literal: true

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
    convert_organism_concept_uris
    update_deleted_contributors
    set_sample_type_contributors
    update_matlab_mimetypes
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

    begin
      Rake::Task['seek:standard_upgrade_tasks'].invoke
      Rake::Task['seek:upgrade_version_tasks'].invoke

      Seek::Config.solr_enabled = solr
      Rake::Task['seek:reindex_all'].invoke if solr

      puts 'Upgrade completed successfully'
    ensure
      Seek::Config.solr_enabled = solr
    end
  end

  task(convert_organism_concept_uris: :environment) do
    Organism.all.each do |organism|
      organism.convert_concept_uri
      if organism.bioportal_concept && organism.bioportal_concept.changed?
        organism.save(validate: false)
      end
    end
  end

  task(update_deleted_contributors: :environment) do
    types = [Assay, DataFile, Document, Event, Investigation, Model, Presentation, Publication, Sample, Sop, Strain, Study,
             DataFile::Version, Document::Version, Model::Version, Presentation::Version, Sop::Version]
    types.each do |type|
      puts "processing deleted contributors for #{type.table_name}"
      # items where the deleted_contributor hasn't been set, the contributor id can be found, but the contributor doesn't exist
      items = type.where('deleted_contributor IS NULL AND contributor_id IS NOT NULL').select { |i| i.contributor.nil? }
      bar = ProgressBar.new(items.count)
      items.each do |item|
        item.update_column(:deleted_contributor, "Person:#{item.contributor_id}")
        item.update_column(:contributor_id, nil)
        bar.increment!
      end
    end
  end

  task(set_sample_type_contributors: :environment) do
    SampleType.where('contributor_id IS NULL AND deleted_contributor IS NULL').each do |sample_type|
      project_admins = sample_type.projects.collect(&:project_administrators).flatten.uniq
      unless project_admins.empty?
        #just take the first
        contributor = project_admins.first
        puts "setting #{contributor.name} as the contributor for sample type #{sample_type.id}"
        sample_type.update_column(:contributor_id,project_admins.first.id)
      else
        puts "no project admins found for sample_type #{sample_type.id}, leaving contributor nil, marking as deleted_contributor".red
        sample_type.update_column(:deleted_contributor,'cannot be determined')
      end
    end
  end

  task(update_matlab_mimetypes: :environment) do
    ContentBlob.where('original_filename LIKE "%.m" OR original_filename LIKE "%.mat"').each do |blob|
      blob.send(:update_content_mime_type)
      blob.update_column(:content_type,blob.content_type)
    end
  end
end
