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
    convert_help_attachments
    convert_help_images
    update_help_image_links
    fix_sample_type_tag_annotations
    sqlite_boolean_update
    delete_orphaned_permissions
    rebuild_sample_templates
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

  task(convert_help_attachments: :environment) do
    count = 0
    HelpAttachment.all.each do |ha|
      next if ha.content_blob
      data = ActiveRecord::Base.connection.select_one("SELECT data FROM db_files WHERE id=#{ha.db_file_id}")['data']
      ContentBlob.create!(data: data,
                          content_type: ha.content_type,
                          original_filename: ha[:filename],
                          asset: ha)
      count += 1
    end

    puts "#{count} HelpAttachments converted"
  end

  task(convert_help_images: :environment) do
    count = 0
    HelpImage.all.each do |hi|
      next if hi.content_blob
      file_path = Rails.root.join('public', 'help_images', *("%08d" % hi.id).scan(/..../), hi[:filename])
      if File.exist?(file_path)
        ContentBlob.create!(tmp_io_object: File.open(file_path),
                            content_type: hi.content_type,
                            original_filename: hi[:filename],
                            asset: hi)
        count += 1
      end
    end

    puts "#{count} HelpImages converted"
  end

  task(update_help_image_links: :environment) do
    count = 0
    re = /!\/help_images((\/\d\d\d\d)(\/\d\d\d\d)+)\/[^!]+!/
    HelpDocument.all.each do |hd|
      body = hd.body
      replacements = {}
      body.scan(re) do |data|
        old_path = Regexp.last_match[0]
        next if replacements[old_path]
        new_path = "!/help_images/#{data[0].tr('/', '').to_i}/view!"
        replacements[old_path] = new_path
      end

      next if replacements.keys.empty?
      replacements.each do |old, new|
        body.gsub!(old, new)
      end

      hd.update_column(:body, body)
      count += 1
    end

    puts "#{count} HelpDocuments updated"
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

  task(sqlite_boolean_update: :environment) do
    if ActiveRecord::Base.connection.instance_values['config'][:adapter] == 'sqlite3'
      print 'Updating booleans for sqlite3 ... '

      class AssayAuthLookup < ActiveRecord::Base
        self.table_name = 'assay_auth_lookup'
      end
      class DataFileAuthLookup < ActiveRecord::Base
        self.table_name = 'data_file_auth_lookup'
      end
      class DocumentAuthLookup < ActiveRecord::Base
        self.table_name = 'document_auth_lookup'
      end
      class EventFileAuthLookup < ActiveRecord::Base
        self.table_name = 'event_auth_lookup'
      end
      class InvestigationAuthLookup < ActiveRecord::Base
        self.table_name = 'investigation_auth_lookup'
      end
      class ModelAuthLookup < ActiveRecord::Base
        self.table_name = 'model_auth_lookup'
      end
      class NodeAuthLookup < ActiveRecord::Base
        self.table_name = 'node_auth_lookup'
      end
      class PresentationAuthLookup < ActiveRecord::Base
        self.table_name = 'presentation_auth_lookup'
      end
      class PublicationAuthLookup < ActiveRecord::Base
        self.table_name = 'publication_auth_lookup'
      end
      class SampleAuthLookup < ActiveRecord::Base
        self.table_name = 'sample_auth_lookup'
      end
      class SopAuthLookup < ActiveRecord::Base
        self.table_name = 'sop_auth_lookup'
      end
      class StrainAuthLookup < ActiveRecord::Base
        self.table_name = 'strain_auth_lookup'
      end
      class StudyAuthLookup < ActiveRecord::Base
        self.table_name = 'study_auth_lookup'
      end
      class WorkflowAuthLookup < ActiveRecord::Base
        self.table_name = 'workflow_auth_lookup'
      end

      auth_lookups = [AssayAuthLookup, DataFileAuthLookup, DocumentAuthLookup, EventFileAuthLookup, InvestigationAuthLookup,
                      ModelAuthLookup, NodeAuthLookup, PresentationAuthLookup, PublicationAuthLookup, SampleAuthLookup,
                      SopAuthLookup, StrainAuthLookup, StudyAuthLookup, WorkflowAuthLookup]
      auth_methods = %w[can_view can_manage can_edit can_download can_delete]
      auth_lookups.each do |type|
        auth_methods.each do |method|
          type.where("#{method} = 't'").update_all(method => 1)
          type.where("#{method} = 'f'").update_all(method => 0)
        end
      end

      ContentBlob.where("is_webpage = 't'").update_all(is_webpage: 1)
      ContentBlob.where("is_webpage = 'f'").update_all(is_webpage: 0)
      ContentBlob.where("external_link = 't'").update_all(external_link: 1)
      ContentBlob.where("external_link = 'f'").update_all(external_link: 0)

      DataFile::Version.where("simulation_data = 't'").update_all(simulation_data: 1)
      DataFile::Version.where("simulation_data = 'f'").update_all(simulation_data: 0)
      DataFile.where("simulation_data = 't'").update_all(simulation_data: 1)
      DataFile.where("simulation_data = 'f'").update_all(simulation_data: 0)

      MeasuredItem.where("factors_studied = 't'").update_all(factors_studied: 1)
      MeasuredItem.where("factors_studied = 'f'").update_all(factors_studied: 0)

      NotifieeInfo.where("receive_notifications = 't'").update_all(receive_notifications: 1)
      NotifieeInfo.where("receive_notifications = 'f'").update_all(receive_notifications: 0)

      Policy.where("use_whitelist = 't'").update_all(use_whitelist: 1)
      Policy.where("use_whitelist = 'f'").update_all(use_whitelist: 0)
      Policy.where("use_blacklist = 't'").update_all(use_blacklist: 1)
      Policy.where("use_blacklist = 'f'").update_all(use_blacklist: 0)

      Programme.where("is_activated = 't'").update_all(is_activated: 1)
      Programme.where("is_activated = 'f'").update_all(is_activated: 0)

      ProjectFolder.where("editable = 't'").update_all(editable: 1)
      ProjectFolder.where("editable = 'f'").update_all(editable: 0)
      ProjectFolder.where("incoming = 't'").update_all(incoming: 1)
      ProjectFolder.where("incoming = 'f'").update_all(incoming: 0)
      ProjectFolder.where("deletable = 't'").update_all(deletable: 1)
      ProjectFolder.where("deletable = 'f'").update_all(deletable: 0)

      Project.where("use_default_policy = 't'").update_all(use_default_policy: 1)
      Project.where("use_default_policy = 'f'").update_all(use_default_policy: 0)

      SampleAttribute.where("required = 't'").update_all(required: 1)
      SampleAttribute.where("required = 'f'").update_all(required: 0)
      SampleAttribute.where("is_title = 't'").update_all(is_title: 1)
      SampleAttribute.where("is_title = 'f'").update_all(is_title: 0)

      SampleType.where("uploaded_template = 't'").update_all(uploaded_template: 1)
      SampleType.where("uploaded_template = 'f'").update_all(uploaded_template: 0)

      SavedSearch.where("include_external_search = 't'").update_all(include_external_search: 1)
      SavedSearch.where("include_external_search = 'f'").update_all(include_external_search: 0)

      SiteAnnouncement.where("is_headline = 't'").update_all(is_headline: 1)
      SiteAnnouncement.where("is_headline = 'f'").update_all(is_headline: 0)
      SiteAnnouncement.where("show_in_feed = 't'").update_all(show_in_feed: 1)
      SiteAnnouncement.where("show_in_feed = 'f'").update_all(show_in_feed: 0)
      SiteAnnouncement.where("email_notification = 't'").update_all(email_notification: 1)
      SiteAnnouncement.where("email_notification = 'f'").update_all(email_notification: 0)

      Strain.where("is_dummy = 't'").update_all(is_dummy: 1)
      Strain.where("is_dummy = 'f'").update_all(is_dummy: 0)

      Unit.where("factors_studied = 't'").update_all(factors_studied: 1)
      Unit.where("factors_studied = 'f'").update_all(factors_studied: 0)

      puts 'done'
    end
  end

  desc('Delete permissions with non-existent contributor')
  task(delete_orphaned_permissions: :environment) do
    count = 0

    Permission.includes(:contributor).find_each do |p|
      if p.contributor.nil?
        p.destroy!
        count += 1
      end
    end

    puts "#{count} orphaned permissions deleted"
  end

  task(rebuild_sample_template: :environment) do
    SampleType.all.reject{|st| st.uploaded_template?}.each do |sample_type|
      sample_type.queue_template_generation
    end
  end
end
