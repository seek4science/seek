module Seek
  module Samples
    module AttributeTypeHandlers
      class SeekDataFileAttributeTypeHandler < SeekResourceAttributeTypeHandler
        def type
          DataFile
        end
      end
    end
  end
end
