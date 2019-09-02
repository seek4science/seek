module Seek
  module ActsAsISA
    module Relationships
      module InstanceMethods
        # includes publications directly related, plus those related to associated assays
        def related_publications
          Publication.where(id: related_publication_ids)
        end

        def related_people
          ids = [contributor_id]
          ids << [person_responsible_id] if respond_to?(:person_responsible)
          Person.where(id: assets_creators.pluck(:creator_id) + ids).distinct
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

          has_many :assets_creators, dependent: :destroy, as: :asset, foreign_key: :asset_id
          has_many :creators, class_name: 'Person', through: :assets_creators, after_remove: :update_timestamp, after_add: :update_timestamp

          has_many :publication_relationships, -> { where(predicate: Relationship::RELATED_TO_PUBLICATION) },
                   class_name: 'Relationship', as: :subject, dependent: :destroy, inverse_of: :subject
          has_many :publications, through: :publication_relationships, source: :other_object, source_type: 'Publication'
        end
      end
    end
  end
end
