module Seek
  module ActsAsAsset
    # Acts as Asset behaviour that provides helper access the the assets related entities
    module Relationships
      module InstanceMethods
        def managers_names
          managers.map(&:title).join(', ')
        end

        def related_people
          (creators | [contributor.try(:person)]).compact.uniq
        end

        def attributions_objects
          attributions.map(&:other_object)
        end

        def publications
          relationships.select { |a| a.other_object_type == 'Publication' }.map(&:other_object)
        end
      end

      module Associations
        extend ActiveSupport::Concern
        included do
          has_many :relationships,
                   class_name: 'Relationship',
                   as: :subject,
                   dependent: :destroy

          has_many :attributions,
                   -> { where(predicate: Relationship::ATTRIBUTED_TO) },
                   class_name: 'Relationship',
                   as: :subject,
                   dependent: :destroy

          has_many :inverse_relationships,
                   class_name: 'Relationship',
                   as: :other_object,
                   dependent: :destroy

          has_many :assets_creators, dependent: :destroy, as: :asset, foreign_key: :asset_id
          has_many :creators, -> { order('assets_creators.id') }, class_name: 'Person', through: :assets_creators, after_remove: :update_timestamp, after_add: :update_timestamp
        end
      end
    end
  end
end
