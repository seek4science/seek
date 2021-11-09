module Ga4gh
  module Trs
    module V2
      # Decorator for a ROCrate::File to make it appear as a GA4GH TRS File Wrapper.
      class FileWrapper
        include ActiveModel::Serialization
        delegate_missing_to :@entry

        def initialize(entry)
          @entry = entry
        end

        def content
          remote? ? nil : read
        end

        def url
          remote? ? uri&.to_s : nil
        end

        def checksum
          [] # [{ type: 'SHA-256', checksum: 'bla' }]
        end
      end
    end
  end
end
