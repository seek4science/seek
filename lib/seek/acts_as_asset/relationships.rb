module Seek
  module ActsAsAsset
    # Acts as Asset behaviour that provides helper access the the assets related entities
    module Relationships
      def managers_names
        managers.map(&:title).join(', ')
      end

      def related_people
        creators
      end

      def attributions_objects
        attributions.map { |a| a.other_object }
      end

      def related_publications
        relationships.select { |a| a.other_object_type == 'Publication' }.map { |a| a.other_object }
      end
    end
  end
end
