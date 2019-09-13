module Seek
  module BioSchema
    class BioSchemaAttribute

      include ActionView::Helpers::SanitizeHelper

      attr_reader :method
      attr_reader :property

      def initialize(method, property)
        @method = method
        @property = property
      end

      def invoke(decorator)
        value = decorator.try(method)
        if value.is_a?(String)
          sanitize(value)
        else
          value
        end
      end

    end
  end
end