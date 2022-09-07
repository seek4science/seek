module Seek
  module ActsAsISA
    module Relationships
      module InstanceMethods
        # includes publications directly related, plus those related to associated assays
        def related_publications
          Publication.where(id: related_publication_ids)
        end

        def related_people
          Person.where(id: related_person_ids)
        end

        def related_person_ids
          ids = creator_ids
          ids << contributor_id
          ids.uniq
        end

        def related_sops
          Sop.where(id: related_sop_ids)
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

          include Seek::Creators

          has_many :publication_relationships, -> { where(predicate: Relationship::RELATED_TO_PUBLICATION) },
                   class_name: 'Relationship', as: :subject, dependent: :destroy, inverse_of: :subject
          has_many :publications, through: :publication_relationships, source: :other_object, source_type: 'Publication'
        end
      end
    end
  end
end
