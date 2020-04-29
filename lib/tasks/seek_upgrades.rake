# frozen_string_literal: true

require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'seek/mime_types'

include Seek::MimeTypes

namespace :seek do
  # these are the tasks required for this version upgrade
  task upgrade_version_tasks: %i[
    environment
    convert_old_pagination_settings
    set_assay_and_technology_type_uris
    db:seed:publication_types
    convert_old_ldap_settings
    convert_old_elixir_aai_settings
    refix_country_codes
    fix_missing_dois
  ]

  # these are the tasks that are executes for each upgrade as standard, and rarely change
  task standard_upgrade_tasks: %i[
    environment
    clear_filestore_tmp
    repopulate_auth_lookup_tables
  ]

  desc('upgrades SEEK from the last released version to the latest released version')
  task(upgrade: [:environment]) do
    puts "Starting upgrade ..."
    puts "... trimming old session data ..."
    Rake::Task['db:sessions:trim'].invoke
    puts "... migrating database ..."
    Rake::Task['db:migrate'].invoke
    Rake::Task['tmp:clear'].invoke

    solr = Seek::Config.solr_enabled
    Seek::Config.solr_enabled = false

    begin
      puts "... performing upgrade tasks ..."
      Rake::Task['seek:standard_upgrade_tasks'].invoke
      Rake::Task['seek:upgrade_version_tasks'].invoke

      Seek::Config.solr_enabled = solr
      puts "... queuing search reindexing jobs ..."
      Rake::Task['seek:reindex_all'].invoke if solr

      puts 'Upgrade completed successfully'
    ensure
      Seek::Config.solr_enabled = solr
    end
  end

  task(convert_old_pagination_settings: :environment) do
    puts "..... converting old pagination settings ..."
    limit_latest = Settings.where(var: 'limit_latest').first
    if limit_latest&.value
      puts "Setting 'results_per_page_default' to #{limit_latest.value}"
      Seek::Config.results_per_page_default = limit_latest.value
      limit_latest.destroy!
    end

    default_pages = Settings.where(var: 'default_pages').first
    if default_pages&.value
      default_pages.value.each do |controller, default_page|
        if default_page == 'all'
          puts "Setting 'results_per_page' for #{controller} to 999999"
          Seek::Config.set_results_per_page_for(controller.to_s, 999999)
        end
      end
      default_pages.destroy!
    end
  end

  task(set_assay_and_technology_type_uris: :environment) do
    puts "..... updating assay and technology type uris ..."
    assays = Assay.where('suggested_assay_type_id IS NOT NULL OR suggested_technology_type_id IS NOT NULL')
    count = 0

    assays.each do |assay|
      needs_assay_type_update = assay.suggested_assay_type&.ontology_uri && assay[:assay_type_uri] != assay.suggested_assay_type.ontology_uri
      needs_tech_type_update = assay.suggested_technology_type&.ontology_uri && assay[:technology_type_uri] != assay.suggested_technology_type.ontology_uri
      if needs_assay_type_update || needs_tech_type_update
        count += 1
        assay.update_column(:assay_type_uri, assay.suggested_assay_type.ontology_uri) if needs_assay_type_update
        assay.update_column(:technology_type_uri, assay.suggested_technology_type.ontology_uri) if needs_tech_type_update
      end
    end

    puts "Updated #{count} assays' technology/assay type URIs" if count > 0
  end

  task(convert_old_ldap_settings: :environment) do
    puts "..... converting ldap settings ..."
    providers_setting = Settings.where(var: 'omniauth_providers').first
    if providers_setting
      unless providers_setting.value.blank?
        puts "Found existing 'omniauth_providers' setting:\n #{providers_setting.value.inspect}"
        ldap_setting = providers_setting.value[:ldap] || providers_setting.value['ldap']
        if ldap_setting
          puts "Setting 'omniauth_ldap_config' to:\n #{ldap_setting.inspect}"
          Seek::Config.omniauth_ldap_config = ldap_setting
          puts "Setting 'omniauth_ldap_enabled' to: #{Seek::Config.omniauth_enabled }"
          Seek::Config.omniauth_ldap_enabled = Seek::Config.omniauth_enabled
        else
          puts "No relevant LDAP settings found."
        end
      end
      puts "Destroying old 'omniauth_providers' setting."
      providers_setting.destroy!
    end
  end

  task(convert_old_elixir_aai_settings: :environment) do
    puts "..... converting elixir aai settings ..."
    client_id_setting = Settings.where(var: 'elixir_aai_client_id').first
    client_id = nil

    if client_id_setting
      client_id = client_id_setting.value
      unless client_id.blank?
        puts "Setting 'omniauth_elixir_aai_client_id' to: #{client_id}"
        Seek::Config.omniauth_elixir_aai_client_id = client_id
      end
      puts "Destroying old 'elixir_aai_client_id' setting."
      client_id_setting.destroy!
    end

    elixir_aai_secret_dir_path = File.join(Rails.root, Seek::Config.filestore_path, 'elixir_aai')
    elixir_aai_secret_path = File.join(elixir_aai_secret_dir_path, 'secret')
    if File.exists?(elixir_aai_secret_path)
      secret = File.read(elixir_aai_secret_path)
      unless secret.blank?
        puts "Setting 'omniauth_elixir_aai_secret'"
        Seek::Config.omniauth_elixir_aai_secret = secret
      end
      puts "Deleting old file: #{elixir_aai_secret_path}"
      FileUtils.rm(elixir_aai_secret_path)
      puts "Deleting directory: #{elixir_aai_secret_dir_path}"
      FileUtils.rmdir(elixir_aai_secret_dir_path)

      unless secret.blank? || client_id.blank? # If there was both a client ID and secret, enable ELIXIR AAI
        puts "Setting 'omniauth_elixir_aai_enabled' to: true"
        Seek::Config.omniauth_elixir_aai_enabled = true
      end
    end
  end

  task(refix_country_codes: :environment) do
    [Institution, Event].each do |type|
      count = 0
      type.where('length(country) > 2').each do |item|
        item.update_column(:country, CountryCodes.code(item.country))
        count += 1
      end
      puts "Fixed #{count} #{type.name}s' country codes" if count > 0
    end
  end

  task(fix_missing_dois: :environment) do
    puts "Looking for broken DOIs..."
    AssetDoiLog.where(action: AssetDoiLog::MINT).each do |log|
      asset = log.asset
      if asset && asset.respond_to?(:find_version)
        version = asset.find_version(log.asset_version)
        if version
          if version.doi.nil? && log.doi.present?
            puts "  Restoring DOI: #{log.doi}"
            version.update_column(:doi, log.doi)
          end
        end
      end
    end
    puts "Done"
  end
end
