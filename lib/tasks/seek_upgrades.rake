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
    ensure_maximum_public_access_type
    update_model_types
  ]

  # these are the tasks that are executes for each upgrade as standard, and rarely change
  task standard_upgrade_tasks: %i[
    environment
    clear_filestore_tmp
    repopulate_auth_lookup_tables
    resynchronise_ontology_types
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

  task(ensure_maximum_public_access_type: :environment) do
    policies = Policy.where('access_type > ?', Policy.max_public_access_type)
    count = policies.count
    policies.each { |p| p.update_column(:access_type, Policy.max_public_access_type) }

    puts "#{count} policies updated"
  end

  task(update_model_types: :environment) do
    Rake::Task['db:seed:model_types'].invoke
  end
end
