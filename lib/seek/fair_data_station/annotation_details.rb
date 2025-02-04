module Seek
  module FairDataStation
    class AnnotationDetails
      attr_accessor :property_id, :label, :description, :pattern, :required

      def initialize(attributes = {})
        @property_id = attributes[:property_id]
        @label = attributes[:label]
        @description = attributes[:description]
        @pattern = attributes[:pattern]
        @required = attributes[:required]
      end
    end
  end
end
