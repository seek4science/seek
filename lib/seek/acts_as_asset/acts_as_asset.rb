
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
        grouped_pagination

        attr_writer :original_filename, :content_type
        does_not_require_can_edit :last_used_at

        validates_presence_of :title

        include Seek::Stats::ActivityCounts

        include Seek::ActsAsAsset::ISA::Associations
        include Seek::ActsAsAsset::Folders::Associations
        include Seek::ActsAsAsset::Relationships::Associations

        include Seek::ActsAsAsset::Search

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

    module InstanceMethods
      include Seek::ActsAsAsset::ContentBlobs::InstanceMethods
      include Seek::ActsAsAsset::ISA::InstanceMethods
      include Seek::ActsAsAsset::Relationships::InstanceMethods
      include Seek::ActsAsAsset::Folders::InstanceMethods

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
