
# SysMO: lib/acts_as_asset.rb
# Original code borrowed from myExperiment and tailored for SysMO needs.

# ********************************************************************************
# * myExperiment: lib/acts_as_contributable.rb
# *
# * Copyright (c) 2007 University of Manchester and the University of Southampton.
# * See license.txt for details.
# ********************************************************************************
require 'seek/permissions/acts_as_authorized'
#require 'grouped_pagination'

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

    module ClassMethods

      def acts_as_asset
        include Seek::Taggable

        acts_as_scalable
        acts_as_authorized
        acts_as_uniquely_identifiable
        acts_as_annotatable :name_field=>:title
        acts_as_favouritable

        attr_writer :original_filename,:content_type
        does_not_require_can_edit :last_used_at

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
                 :as => :other_object,
                 :dependent => :destroy

        has_many :assay_assets, :dependent => :destroy, :as => :asset, :foreign_key => :asset_id
        has_many :assays, :through => :assay_assets

        has_many :assets_creators, :dependent => :destroy, :as => :asset, :foreign_key => :asset_id
        has_many :creators, :class_name => "Person", :through => :assets_creators, :order=>'assets_creators.id', :after_remove => :update_timestamp, :after_add => :update_timestamp

        has_many :project_folder_assets, :as=>:asset, :dependent=>:destroy

        has_many :activity_logs, :as => :activity_loggable

        after_create :add_new_to_folder

        grouped_pagination

        searchable do
          text :title, :description, :searchable_tags
          text :creators do
            creators.compact.map(&:name)
          end
          text :content_blob do
            content_blob_search_terms
          end
        end if Seek::Config.solr_enabled

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

      def contains_downloadable_items?
        blobs = []
        blobs << self.content_blob if self.respond_to?(:content_blob)
        blobs = blobs | self.content_blobs if self.respond_to?(:content_blobs)
        !blobs.compact.select{|blob| !blob.is_webpage?}.empty?
      end

      def studies
        assays.collect{|a| a.study}.uniq
      end

      def related_people
        self.creators
      end

      def add_new_to_folder
        projects.each do |project|
          pf = ProjectFolder.new_items_folder project
          unless pf.nil?
            pf.add_assets self
          end
        end
      end

      #sets the last_used_at time to the current time
      def just_used
        update_column(:last_used_at, Time.now)
      end

      def folders
        project_folder_assets.collect{|pfa| pfa.project_folder}
      end

      def attributions_objects
        self.attributions.collect { |a| a.other_object }
      end

      def related_publications
        self.relationships.select { |a| a.other_object_type == "Publication" }.collect { |a| a.other_object }
      end

      def cache_remote_content_blob
        blobs = []
        blobs << self.content_blob if self.respond_to?(:content_blob)
        blobs = blobs | self.content_blobs if self.respond_to?(:content_blobs)
        blobs.compact!
        blobs.each do |blob|
          if blob.url && self.projects.first
            begin
              p=self.projects.first
              p.decrypt_credentials
              downloader            =Jerm::DownloaderFactory.create p.name
              resource_type         = self.class.name.split("::")[0] #need to handle versions, e.g. Sop::Version
              data_hash             = downloader.get_remote_data blob.url, p.site_username, p.site_password, resource_type
              blob.tmp_io_object = File.open data_hash[:data_tmp_path],"r"
              blob.content_type     = data_hash[:content_type]
              blob.original_filename = data_hash[:filename]
              blob.save!
            rescue Exception=>e
              puts "Error caching remote data for url=#{self.content_blob.url} #{e.message[0..50]} ..."
            end
          end
          self.save!
        end

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
        assays.collect{|at| at.try(:assay_type_label)}.compact
      end

      def technology_type_titles
        assays.collect{|tt| tt.try(:technology_type_label)}.compact
      end

      #the search terms coming from the content-blob(s)
      def content_blob_search_terms
        if self.respond_to?(:content_blob) || self.respond_to?(:content_blobs)
          blobs = self.respond_to?(:content_blobs) ? content_blobs : [content_blob]
          blobs.compact.collect do |blob|
            [blob.original_filename] | [blob.pdf_contents_for_search]
          end.flatten.compact.uniq
        else
          #for assets with no content-blobs, e.g. Publication
          []
        end
      end

    end
  end

end


ActiveRecord::Base.class_eval do
  include Acts::Asset
end
