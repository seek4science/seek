module Seek
  module ActsAsAsset
    # Acts as Asset behaviour that provides helper access the the assets related entities
    module Relationships
      module InstanceMethods
        def managers_names
          managers.map(&:title).join(', ')
        end

        def related_people
          Person.where(id: creator_ids | contributor_ids).distinct
        end

        def attributions_objects
          attributions.map(&:other_object)
        end

        def record_creators_changed(_assets_creator)
          @creators_changed = true
        end

        def creators_changed?
          @creators_changed
        end

        def source_link_url= url
          (source_link || build_source_link).assign_attributes(url: url)

          source_link.mark_for_destruction if url.blank?

          url
        end

        def source_link_url
          source_link&.url
        end
      end

      module Associations
        extend ActiveSupport::Concern
        included do
          has_many :relationships,
                   class_name: 'Relationship',
                   as: :subject,
                   dependent: :destroy,
                   autosave: true,
                   inverse_of: :subject

          has_many :attributions,
                   -> { where(predicate: Relationship::ATTRIBUTED_TO) },
                   class_name: 'Relationship',
                   as: :subject,
                   dependent: :destroy,
                   inverse_of: :subject

          has_many :inverse_relationships,
                   class_name: 'Relationship',
                   as: :other_object,
                   dependent: :destroy,
                   inverse_of: :other_object

          has_many :assets_creators, dependent: :destroy, as: :asset, foreign_key: :asset_id
          has_many :creators, class_name: 'Person', through: :assets_creators, after_remove: %i[update_timestamp record_creators_changed], after_add: %i[update_timestamp record_creators_changed]

          #has_many :asset_links, dependent: :destroy, as: :asset, foreign_key: :asset_id, inverse_of: :asset
          has_many :discussion_links, -> { where(AssetLink.discussion.where_values_hash) }, class_name: 'AssetLink', as: :asset, dependent: :destroy, inverse_of: :asset
          accepts_nested_attributes_for :discussion_links, allow_destroy:true
	  has_one :source_link, -> { where(link_type: AssetLink::SOURCE) }, class_name: 'AssetLink', as: :asset, dependent: :destroy, inverse_of: :asset, autosave: true

          has_filter :creator

          has_many :publication_relationships, -> { where(predicate: Relationship::RELATED_TO_PUBLICATION) },
                   class_name: 'Relationship', as: :subject, dependent: :destroy, inverse_of: :subject
          has_many :publications, through: :publication_relationships, source: :other_object, source_type: 'Publication'

          has_many :collection_items, as: :asset, dependent: :destroy
          has_many :collections, through: :collection_items
          has_filter collection: Seek::Filtering::Filter.new(
              value_field: 'collections.id',
              label_field: 'collections.title',
              joins: [:collections]
          )
        end
      end
    end
  end
end
