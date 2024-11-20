module Seek
  module Samples
    module AttributeHandlers
      class SeekSopAttributeHandler < SeekResourceAttributeHandler
        def type
          Sop
        end
      end
    end
  end
end