
# SysMO: lib/acts_as_asset.rb
# Original code borrowed from myExperiment and tailored for SysMO needs.

# ********************************************************************************
# * myExperiment: lib/acts_as_contributable.rb
# *
# * Copyright (c) 2007 University of Manchester and the University of Southampton.
# * See license.txt for details.
# ********************************************************************************
require 'seek/permissions/acts_as_authorized'

module Seek
  module ActsAsAsset
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
        attr_accessor :parent_name
        include Seek::Taggable

        acts_as_scalable
        acts_as_authorized
        acts_as_uniquely_identifiable
        acts_as_annotatable name_field: :title
        acts_as_favouritable
        acts_as_trashable

        attr_writer :original_filename, :content_type
        does_not_require_can_edit :last_used_at

        validates_presence_of :title

        # MERGENOTE - this was removed by VLN at some point, possibly needs some configuration setting
        # validates_presence_of :projects

        has_many :relationships,
                 class_name: 'Relationship',
                 as: :subject,
                 dependent: :destroy

        has_many :attributions,
                 class_name: 'Relationship',
                 as: :subject,
                 conditions: { predicate: Relationship::ATTRIBUTED_TO },
                 dependent: :destroy

        has_many :inverse_relationships,
                 class_name: 'Relationship',
                 as: :other_object,
                 dependent: :destroy

        has_many :assay_assets, dependent: :destroy, as: :asset, foreign_key: :asset_id
        has_many :assays, through: :assay_assets

        has_many :assets_creators, dependent: :destroy, as: :asset, foreign_key: :asset_id
        has_many :creators, class_name: 'Person', through: :assets_creators, order: 'assets_creators.id', after_remove: :update_timestamp, after_add: :update_timestamp

        has_many :project_folder_assets, as: :asset, dependent: :destroy

        has_many :activity_logs, as: :activity_loggable

        after_create :add_new_to_folder

        grouped_pagination

        include Seek::Search::CommonFields

        searchable(auto_index: false) do
          text :creators do
            if self.respond_to?(:creators)
              creators.compact.map(&:name)
            end
          end
          text :other_creators do
            if self.respond_to?(:other_creators)
              other_creators
            end
          end
          text :content_blob do
            content_blob_search_terms
          end
          text :assay_type_titles, :technology_type_titles
        end if Seek::Config.solr_enabled

        class_eval do
          extend Seek::ActsAsAsset::SingletonMethods
        end
        include Seek::ActsAsAsset::InstanceMethods
        include BackgroundReindexing
        include Subscribable

        def get_all_as_json(user)
          all = all_authorized_for 'view', user
          with_contributors = all.map{ |d|
            contributor = d.contributor
            { 'id' => d.id,
              'title' => h(d.title),
              'contributor' => contributor.nil? ? '' : 'by ' + h(contributor.person.name),
              'type' => name
            }
          }
          with_contributors.to_json
        end
      end

      def is_asset?
        include?(Seek::ActsAsAsset::InstanceMethods)
      end
    end

    module SingletonMethods
    end

    module InstanceMethods
      include Seek::ActsAsAsset::ContentBlobs
      include Seek::ActsAsAsset::ISA
      include Seek::ActsAsAsset::Dois
      include Seek::ActsAsAsset::Relationships
      include Seek::ActsAsAsset::Folders

      # sets the last_used_at time to the current time
      def just_used
        update_column(:last_used_at, Time.now)
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Seek::ActsAsAsset
end
