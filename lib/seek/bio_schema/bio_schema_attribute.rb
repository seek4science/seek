module Seek
  module BioSchema
    # Object to represent a bioschema attribute, providing the method to call, and the associated property.
    # Handles invoking the method and carrying out any sanitization on the result.
    class BioSchemaAttribute
      include ActionView::Helpers::SanitizeHelper

      attr_reader :method
      attr_reader :property

      def initialize(method, property)
        @method = method
        @property = property
      end

      def invoke(decorator)
        value = nil
        value = decorator.send(method) if decorator.respond_to?(method)
        if value.is_a?(String)
          sanitize(value)
        else
          value
        end
      end
    end
  end
end
