module Seek
  module Samples
    module AttributeTypeHandlers
      class SeekResourceAttributeTypeHandler < BaseAttributeHandler
        def test_value(value)
          raise "Not a valid SEEK #{type.name.humanize} ID" unless value[:id].to_i.positive?
        end

        def type
          raise 'Not implemented'
        end

        def test_blank?(value)
          value.blank? || (value.is_a?(Hash) && value[:id].blank? && value[:title].blank?)
        end

        def convert(value)
          resource = find_resource(value)
          hash = { id: resource ? resource.id : value, type: type.name }.with_indifferent_access
          hash[:title] = resource.title if resource
          hash
        end

        private

        def find_resource(value)
          type.find_by_id(value)
        end
      end
    end
  end
end
