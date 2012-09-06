
# SysMO: lib/acts_as_asset.rb
# Original code borrowed from myExperiment and tailored for SysMO needs.

# ********************************************************************************
# * myExperiment: lib/acts_as_contributable.rb
# *
# * Copyright (c) 2007 University of Manchester and the University of Southampton.
# * See license.txt for details.
# ********************************************************************************
require 'acts_as_authorized'

module Acts #:nodoc:
  module Asset #:nodoc:
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    def is_asset?
      self.class.is_asset?
    end

    def is_downloadable_asset?
      is_asset? && is_downloadable?
    end

    def is_downloadable_pdf?
      is_downloadable_asset? && can_download? && is_pdf? && !content_blob.filesize.nil?
    end

    def is_content_viewable?
      is_downloadable_asset? && can_download? && is_viewable_format? && !content_blob.filesize.nil?
    end

    def is_viewable_format?
      #FIXME: should be updated to use mime_helper, rather than redefining the mime types here. A new module may be required that consolidates format related stuff
      viewable_formats= %w[application/pdf application/msword application/vnd.ms-powerpoint application/vnd.oasis.opendocument.presentation application/vnd.oasis.opendocument.text]
      viewable_formats.include?(content_type)
    end

    def is_pdf?
      #FIXME: should be updated to use mime_helper, rather than redefining the mime types here. A new module may be required that consolidates format related stuff
      content_type == "application/pdf"
    end

    module ClassMethods

      def acts_as_asset
        include Seek::Taggable

        acts_as_authorized
        acts_as_uniquely_identifiable
        acts_as_annotatable :name_field=>:title
        acts_as_favouritable

        attr_writer :original_filename,:content_type
        does_not_require_can_edit :last_used_at

        default_scope :order => "#{self.table_name}.updated_at DESC"

        validates_presence_of :title
        validates_presence_of :projects

        has_many :relationships,
                 :class_name => 'Relationship',
                 :as         => :subject,
                 :dependent  => :destroy

        has_many :attributions,
                 :class_name => 'Relationship',
                 :as         => :subject,
                 :conditions => {:predicate => Relationship::ATTRIBUTED_TO},
                 :dependent  => :destroy

        has_many :inverse_relationships,
                 :class_name => 'Relationship',
                 :as => :object,
                 :dependent => :destroy

        has_many :assay_assets, :dependent => :destroy, :as => :asset, :foreign_key => :asset_id
        has_many :assays, :through => :assay_assets

        has_many :assets_creators, :dependent => :destroy, :as => :asset, :foreign_key => :asset_id
        has_many :creators, :class_name => "Person", :through => :assets_creators, :order=>'assets_creators.id', :after_remove => :update_timestamp, :after_add => :update_timestamp

        has_many :project_folder_assets, :as=>:asset, :dependent=>:destroy

        searchable do
          text :creators do
            creators.compact.map(&:name)
          end
        end if Seek::Config.solr_enabled

        has_many :activity_logs, :as => :activity_loggable

        after_create :add_new_to_folder

        grouped_pagination :default_page => Seek::Config.default_page(self.name.underscore.pluralize)

        class_eval do
          extend Acts::Asset::SingletonMethods
        end
        include Acts::Asset::InstanceMethods
        include BackgroundReindexing
        include Subscribable
      end



      def is_asset?
        include?(Acts::Asset::InstanceMethods)
      end
    end

    module SingletonMethods
    end

    module InstanceMethods

      def studies
        assays.collect{|a| a.study}.uniq
      end


      def related_people
        self.creators
      end
      
      # adapt for moving original_filename,content_type to content_blob

      def original_filename
        try_block {content_blob.original_filename}
      end

      def content_type
        try_block {content_blob.content_type}
      end


      # this method will take attributions' association and return a collection of resources,
      # to which the current resource is attributed
      def attributions
        self.relationships.select { |a| a.predicate == Relationship::ATTRIBUTED_TO }
      end

      def add_new_to_folder
        projects.each do |project|
          pf = ProjectFolder.new_items_folder project
          unless pf.nil?
            pf.add_assets self
          end
        end
      end

      def folders
        project_folder_assets.collect{|pfa| pfa.project_folder}
      end

      def attributions_objects
        self.attributions.collect { |a| a.object }
      end

      def related_publications
        self.relationships.select { |a| a.object_type == "Publication" }.collect { |a| a.object }
      end


      def cache_remote_content_blob
        if self.content_blob && self.content_blob.url && self.projects.first
          begin
            p=self.projects.first
            p.decrypt_credentials
            downloader            =Jerm::DownloaderFactory.create p.name
            resource_type         = self.class.name.split("::")[0] #need to handle versions, e.g. Sop::Version
            data_hash             = downloader.get_remote_data self.content_blob.url, p.site_username, p.site_password, resource_type
            cb = self.content_blob
            cb.tmp_io_object = File.open data_hash[:data_tmp_path],"r"
            cb.content_type     = data_hash[:content_type]
            cb.original_filename = data_hash[:filename]
            cb.save!
            self.save!


          rescue Exception=>e
            puts "Error caching remote data for url=#{self.content_blob.url} #{e.message[0..50]} ..."
          end
        end
      end

      def pdf_contents_for_search obj=self
        content_blob = obj.content_blob
        content = nil
        if content_blob.file_exists?
          if obj.is_viewable_format?
            content = Rails.cache.fetch("#{content_blob.cache_key}-pdf-content-for-search") do
              begin
                output_directory = content_blob.directory_storage_path
                dat_filepath = content_blob.filepath
                pdf_filepath = content_blob.filepath('pdf')
                txt_filepath = content_blob.filepath('txt')
                Docsplit.extract_pdf(dat_filepath, :output => output_directory) unless content_blob.file_exists?(pdf_filepath)
                Docsplit.extract_text(pdf_filepath, :output => output_directory) unless content_blob.file_exists?(txt_filepath)
                file_content = File.open(txt_filepath).read
                unless file_content.blank?
                  filter_text_content file_content
                else
                  file_content
                end
              rescue Exception => e
                Rails.logger.error("Error processing content for content_blob #{obj.content_blob.id} #{e}")
                raise e unless Rails.env=="production"
                nil
              end
            end
          end
        else
          Rails.logger.error("Unable to find file contents for #{obj.class.name} #{obj.id}")
        end
        content
      end

      #filters special characters \n \f
      def filter_text_content content
        special_characters = ['\n', '\f']
        special_characters.each do |sc|
          content.gsub!(/#{sc}/, '')
        end
        content
      end

      def project_assays
        all_assays=Assay.all.select{|assay| assay.can_edit?(User.current_user)}.sort_by &:title
        all_assays = all_assays.select do |assay|
          assay.is_modelling?
        end if self.is_a? Model

        project_assays = all_assays.select { |df| User.current_user.person.projects.include?(df.project) }

        project_assays
      end

      def assay_type_titles
        assays.collect{|a| a.assay_type.try(:title)}.compact
      end

      def technology_type_titles
        assays.collect{|a| a.technology_type.try(:title)}.compact
      end

    end
  end

end


ActiveRecord::Base.class_eval do
  include Acts::Asset
end
