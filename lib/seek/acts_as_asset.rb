
# SysMO: lib/acts_as_asset.rb
# Original code borrowed from myExperiment and tailored for SysMO needs.

# ********************************************************************************
# * myExperiment: lib/acts_as_contributable.rb
# *
# * Copyright (c) 2007 University of Manchester and the University of Southampton.
# * See license.txt for details.
# ********************************************************************************

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

    def have_misc_links?
      self.class.have_misc_links?
    end

    module ClassMethods
      def acts_as_asset
        attr_accessor :parent_name
        include Seek::Taggable

        acts_as_scalable
        acts_as_authorized
        acts_as_uniquely_identifiable
        acts_as_favouritable
        acts_as_discussable
        grouped_pagination
        title_trimmer

        attr_writer :original_filename, :content_type
        does_not_require_can_edit :last_used_at

        validates :title, presence: true
        validates :title, length: { maximum: 255 }, unless: -> { is_a?(Publication) }
        validates :description, length: { maximum: 65_535 }, if: -> { respond_to?(:description) }
        validates :license, license:true, allow_blank: true, if: -> { respond_to?(:license) }


        include Seek::Stats::ActivityCounts

        include Seek::ActsAsAsset::ISA::Associations
        include Seek::ActsAsAsset::Folders::Associations
        include Seek::ActsAsAsset::Relationships::Associations

        include Seek::ActsAsAsset::Searching

        include Seek::ActsAsAsset::InstanceMethods
        include Seek::Search::BackgroundReindexing
        include Seek::Subscribable
        extend SingletonMethods
      end

      def is_asset?
        include?(Seek::ActsAsAsset::InstanceMethods)
      end

      def have_misc_links?
        include?(Seek::ActsAsHavingMiscLinks::InstanceMethods)
      end
    end

    # the class methods that get added when calling acts_as_asset
    module SingletonMethods
      def get_all_as_json(user)
        all = authorized_for 'view', user
        with_contributors = all.map do |d|
          contributor = d.contributor
          { 'id' => d.id,
            'title' => h(d.title),
            'contributor' => contributor.nil? ? '' : 'by ' + h(contributor.name),
            'type' => name
          }
        end
        with_contributors.to_json
      end

      def user_creatable?
        feature_enabled?
      end

      def can_create?
        User.logged_in_and_member?
      end
    end

    module InstanceMethods
      include Seek::ActsAsAsset::ContentBlobs::InstanceMethods
      include Seek::ActsAsAsset::ISA::InstanceMethods
      include Seek::ActsAsAsset::Relationships::InstanceMethods
      include Seek::ActsAsAsset::Folders::InstanceMethods
      include Seek::ResearchObjects::Packaging

      # sets the last_used_at time to the current time
      def just_used
        update_column(:last_used_at, Time.now)
      end

      # whether a new version is allowed for this asset.
      # for example if it has come from openbis or has extracted samples then it is not allowed
      def new_version_supported?
        versioned? &&
          is_downloadable? &&
          !(respond_to?(:extracted_samples) && extracted_samples.any?) &&
          !(respond_to?(:openbis?) && openbis?)
      end
    end
  end
end
