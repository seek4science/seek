module Seek
  module ActsAsISA
    module Relationships
      extend ActiveSupport::Concern
      included do
        has_many :relationships,
                 class_name: 'Relationship',
                 as: :subject,
                 dependent: :destroy
      end

      def publications
        relationships.select { |a| a.other_object_type == 'Publication' }.collect(&:other_object)
      end

      # includes publications directly related, plus those related to associated assays
      def related_publications
        child_isa.collect(&:related_publications).flatten.uniq | publications
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
