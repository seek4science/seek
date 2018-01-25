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
    rebuild_sample_templates
    delete_redundant_subscriptions
    update_sample_resource_links
    update_content_blob_timestamps
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

  task(update_content_blob_timestamps: :environment) do
    bar = ProgressBar.new(ContentBlob.where('created_at IS NULL').count)
    puts "Collecting content blobs with assets ..."
    bar = ProgressBar.new(ContentBlob.where('created_at IS NULL').count)
    blobs_with_assets = ContentBlob.where('created_at IS NULL').find_each.select do |blob|
      bar.increment!
      blob.asset.present?
    end
    puts " ... transferring timestamps from assets ..."
    bar = ProgressBar.new(blobs_with_assets.count)
    blobs_with_assets.each do |blob|
      blob.update_attribute(:created_at,blob.asset.created_at)
      blob.update_attribute(:updated_at,blob.asset.updated_at)
      bar.increment!
    end

    #clean up the remaining ones.
    puts "Removing content blobs without assets ..."
    bar = ProgressBar.new(ContentBlob.where('created_at IS NULL AND updated_at IS NULL').count)
    ContentBlob.where('created_at IS NULL AND updated_at IS NULL').find_each do |blob|
      blob.destroy
      bar.increment!
    end

  end
end
