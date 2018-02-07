# encoding: utf-8

require 'rubygems'
require 'rake'
require 'active_record/fixtures'
require 'colorize'
require 'seek/mime_types'

include Seek::MimeTypes
include SimpleCrypt

namespace :seek do
  # these are the tasks required for this version upgrade
  task upgrade_version_tasks: %i[
    environment
    rebuild_sample_templates
    delete_redundant_subscriptions
    update_sample_resource_links
    move_site_credentials_to_settings
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

  task(rebuild_sample_templates: :environment) do
    SampleType.all.reject{|st| st.uploaded_template?}.each do |sample_type|
      sample_type.queue_template_generation
    end
  end

  task(delete_redundant_subscriptions: :environment) do
    types = ['Specimen', 'Treatment']
    types.each do |type|
      subs = Subscription.where(subscribable_type: 'Specimen')
      if subs.any?
        puts "Deleting #{subs.count} subscriptions linked to #{type}"
        disable_authorization_checks { subs.destroy_all }
      end
    end

    sample_switch_date = Date.parse('2016-09-01')
    samp_subs = Subscription.where(subscribable_type: 'Sample').where('created_at < ?', sample_switch_date)
    if samp_subs.any?
      puts "Deleting #{samp_subs.count} subscriptions linked to old samples (created before #{sample_switch_date})"
      disable_authorization_checks { samp_subs.destroy_all }
    end

    types = ['Strain', 'Sample']
    types.each do |type|
      subs = Subscription.where(subscribable_type: type)
      subs = subs.select { |s| s.subscribable.nil? rescue true }
      if subs.any?
        puts "Deleting #{subs.count} subscriptions linked to non-existent #{type}"
        disable_authorization_checks { subs.each(&:destroy) }
      end
    end
  end

  task(update_sample_resource_links: :environment) do
    pre_count = SampleResourceLink.count
    Sample.all.each do |sample|
      sample.send(:update_sample_resource_links)
    end
    puts "Created #{SampleResourceLink.count - pre_count} SampleResourceLinks"
  end

  task(move_site_credentials_to_settings: :environment) do
    global_passphrase = defined? GLOBAL_PASSPHRASE ? GLOBAL_PASSPHRASE : 'ohx0ipuk2baiXah'
    conversions = 0

    Project.all.each do |project|
      if project.site_credentials.present?
        credentials_hash = decrypt(project.site_credentials, generate_key(global_passphrase))
        project.site_username = credentials_hash[:username]
        project.site_password = credentials_hash[:password]
        project.update_column(:site_credentials, nil)
        conversions += 1
      end
    end

    puts "#{conversions} project site credentials migrated"
  end
end
