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
    db:seed:model_formats
    update_stored_orcids
    fix_sample_type_tag_annotations
  ]

  # these are the tasks that are executes for each upgrade as standard, and rarely change
  task standard_upgrade_tasks: %i[
    environment
    clear_filestore_tmp
    repopulate_auth_lookup_tables

  ]

  desc('upgrades SEEK from the last released version to the latest released version')
  task(upgrade: [:environment, 'db:sessions:trim', 'db:migrate', 'tmp:clear']) do
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

  desc('updates stored orcid ids to be stored as https')
  task(update_stored_orcids: :environment) do
    Person.where('orcid is NOT NULL').each do |person|
      person.update_column(:orcid, person.orcid_uri)
    end
  end

  desc('Fix sample type tag annotations')
  task(fix_sample_type_tag_annotations: :environment) do
    plural = AnnotationAttribute.where(name: 'sample_type_tags').first
    if plural
      annotations = plural.annotations
      count = annotations.count
      if count > 0
        singular = AnnotationAttribute.where(name: 'sample_type_tag').first_or_create!
        annotations.update_all(attribute_id: singular.id)
        puts "Fixed #{count} sample type tag"
      end
    end
  end
end
