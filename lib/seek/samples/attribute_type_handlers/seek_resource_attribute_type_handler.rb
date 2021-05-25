module Seek
  module Samples
    module AttributeTypeHandlers
      class SeekResourceAttributeTypeHandler < BaseAttributeHandler

        def test_value(value)
          fail "Not a valid SEEK #{type.humanize} ID" unless value[:id].to_i > 0
        end

        def type
          raise 'Not implemented'
        end

        def convert(value)
          resource = find_resource(value)
          hash = { id: resource ? resource.id : value, type: type }.with_indifferent_access
          hash[:title] = resource.title if resource
          hash
        end

        private

        def find_resource(value)
          type.constantize.find_by_id(value)
        end

      end
    end
  end
end