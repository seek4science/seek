module Ga4gh
  module Trs
    module V2
      # Decorator for a ROCrate::File to make it appear as a GA4GH TRS File Wrapper.
      class FileWrapper
        include ActiveModel::Serialization
        delegate_missing_to :@ro_crate_file

        def initialize(ro_crate_file)
          @ro_crate_file = ro_crate_file
        end

        def content
          remote? ? nil : source.read
        end

        def url
          remote? ? canonical_id : nil
        end

        def checksums
          [] # [{ type: 'SHA-256', checksum: 'bla' }]
        end
      end
    end
  end
end