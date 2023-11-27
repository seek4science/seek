module Seek
  module Samples
    module AttributeTypeHandlers
      class SeekDataFileAttributeHandler < SeekResourceAttributeHandler
        def type
          DataFile
        end
      end
    end
  end
end
