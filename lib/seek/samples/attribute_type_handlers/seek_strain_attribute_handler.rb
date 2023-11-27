module Seek
  module Samples
    module AttributeTypeHandlers
      class SeekStrainAttributeHandler < SeekResourceAttributeHandler
        def type
          Strain
        end
      end
    end
  end
end
