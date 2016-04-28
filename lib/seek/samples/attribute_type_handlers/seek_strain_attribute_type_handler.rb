module Seek
  module Samples
    module AttributeTypeHandlers
      class SeekStrainAttributeTypeHandler < BaseAttributeHandler
        def test_value(value)
          fail 'Not a valid SEEK database ID' unless value[:id].to_i > 0
        end

        def convert(value)
          strain = Strain.find_by_id(value)
          hash = { id: value }
          hash[:title] = strain.title if strain
          hash
        end
      end
    end
  end
end
