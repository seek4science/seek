# SysMO: lib/acts_as_versioned_resource.rb
# Original code borrowed from myExperiment and tailored for SysMO needs.

# ********************************************************************************
# * myExperiment: lib/acts_as_contributable.rb
# *
# * Copyright (c) 2007 University of Manchester and the University of Southampton.
# * See license.txt for details.
# ********************************************************************************

module Acts #:nodoc:
  module VersionedResource #:nodoc:
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def acts_as_versioned_resource
        belongs_to :contributor, polymorphic: true

        include Seek::ProjectAssociation

        belongs_to :policy, autosave: true

        class_eval do
          extend Acts::VersionedResource::SingletonMethods
        end
        include Acts::VersionedResource::InstanceMethods

        delegate :tag_counts, :scales, :managers, :attributions, :creators, :assets_creators, :is_asset?,
                 :authorization_supported?, :defines_own_avatar?, :use_mime_type_for_avatar?, :avatar_key,
                 :show_contributor_avatars?, :can_see_hidden_item?, :related_people, to: :parent
      end
    end

    module SingletonMethods
    end

    module InstanceMethods
      def content_type
        content_blob.content_type if self.respond_to?(:content_blob)
      end

      def original_filename
        content_blob.original_filename  if self.respond_to?(:content_blob)
      end
      # this method will take attributions' association and return a collection of resources,
      # to which the current resource is attributed
      def attributions_objects
        parent.attributions.collect(&:other_object)
      end

      Seek::Permissions::ActsAsAuthorized::AUTHORIZATION_ACTIONS.each do |action|
        eval <<-END_EVAL
          def can_#{action}? user = User.current_user
            self.parent.can_perform? '#{action}', user
          end
        END_EVAL
      end

      # assumes all versioned resources are also taggable

      def contains_downloadable_items?
        all_content_blobs.compact.any? { |blob| blob.is_downloadable? }
      end

      def all_content_blobs
        blobs = []
        blobs << content_blob if self.respond_to?(:content_blob)
        blobs |= content_blobs if self.respond_to?(:content_blobs)
        blobs
      end

      def single_content_blob
        all_content_blobs.size == 1 ? all_content_blobs.first : nil
      end
      # returns a list of the people that can manage this file
      # which will be the contributor, and those that have manage permissions

      def assays(version_specific = false)
        if version_specific
          assay_assets(true).collect(&:asset)
        else
          parent.assays
        end
      end

      def assay_assets(version_specific = false)
        aa = parent.assay_assets
        aa.select { |a| a.version == version } if version_specific
      end

      def contributing_user
        parent.try(:contributing_user)
      end

      def annotations
        parent.annotations if parent.respond_to? :annotations
      end

      # For acts_as_doi_mintable...
      def doi_target_url
        polymorphic_url(parent, :version => self.version,
                        :host => Seek::Config.host_with_port,
                        :protocol => Seek::Config.host_scheme)
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Acts::VersionedResource
end
