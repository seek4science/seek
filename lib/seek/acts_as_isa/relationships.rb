module Seek
  module ActsAsISA
    module Relationships
      module InstanceMethods
        # includes publications directly related, plus those related to associated assays
        def related_publications
          ids = child_isa.inject(publication_ids) { |ids, isa| ids + isa.publication_ids }.uniq
          Publication.where(id: ids).distinct
        end

        def related_people
          ids = [contributor_id]
          ids << [person_responsible_id] if self.respond_to?(:person_responsible)
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

        private

        # the child elements depending on the current type, for example for Investigation is would be studies
        def child_isa
          case self
          when Investigation
            studies
          when Study
            assays
          else
            []
          end
        end
      end
    end
  end
end
