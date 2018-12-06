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
    convert_help_attachments
    convert_help_images
    update_help_image_links
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

  task(convert_help_attachments: :environment) do
    count = 0
    HelpAttachment.all.each do |ha|
      next if ha.content_blob
      convert_db_files_to_content_blobs(ha)
      count += 1
    end

    puts "#{count} HelpAttachments converted"
  end

  task(convert_help_images: :environment) do
    count = 0
    HelpImage.all.each do |ha|
      next if ha.content_blob
      convert_db_files_to_content_blobs(ha)
      count += 1
    end

    puts "#{count} HelpImages converted"
  end

  task(update_help_image_links: :environment) do
    count = 0
    re = /!\/help_images((\/\d\d\d\d)+)\/[^!]+!/
    HelpDocument.all.each do |hd|
      body = hd.body
      replacements = {}
      body.scan(re) do |data|
        old_path = Regexp.last_match[0]
        next if replacements[old_path]
        new_path = "!/help_images/#{data[0].tr('/', '').to_i}/view!"
        replacements[old_path] = new_path
      end

      if replacements.keys.length > 0
        replacements.each do |old, new|
          body.gsub!(old, new)
        end

        hd.update_column(:body, body)
        count += 1
      end
    end

    puts "#{count} HelpDocuments updated"
  end
end

def convert_db_files_to_content_blobs(resource)
  data = ActiveRecord::Base.connection.select_one("SELECT data FROM db_files WHERE id=#{resource.db_file_id}")['data']
  ContentBlob.create!(data: data,
                      content_type: resource.content_type,
                      original_filename: resource.filename,
                      asset: resource)
end
