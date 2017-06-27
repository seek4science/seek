module Seek
  module ActsAsISA
    module Relationships
      module InstanceMethods
        def publications
          relationships.select { |a| a.other_object_type == 'Publication' }.collect(&:other_object)
        end

        # includes publications directly related, plus those related to associated assays
        def related_publications
          child_isa.collect(&:related_publications).flatten.uniq | publications
        end

        def related_people
          related_people = creators | [contributor.try(:person)]
          related_people << person_responsible if self.respond_to?(:person_responsible)
          related_people.compact.uniq
        end
      end

      module Associations
        extend ActiveSupport::Concern
        included do
          has_many :relationships,
                   class_name: 'Relationship',
                   as: :subject,
                   dependent: :destroy

          has_many :assets_creators, dependent: :destroy, as: :asset, foreign_key: :asset_id
          has_many :creators, -> { order('assets_creators.id') }, class_name: 'Person', through: :assets_creators, after_remove: :update_timestamp, after_add: :update_timestamp
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
