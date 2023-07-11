module Seek
  module Samples
    module AttributeTypeHandlers
      class SeekStrainAttributeTypeHandler < SeekResourceAttributeTypeHandler
        def type
          Strain
        end
      end
    end
  end
end
