module Ga4gh
  module Trs
    module V2
      # Decorator for a ROCrate::File to make it appear as a GA4GH TRS File Wrapper.
      class FileWrapper
        include ActiveModel::Serialization
        include Rails.application.routes.url_helpers
        attr_writer :url

        delegate_missing_to :@entry

        def initialize(entry, path: nil, tool_version: nil)
          @entry = entry
          @tool_version = tool_version
          @path = path
        end

        def content
          unless remote?
            s = read
            if s.valid_encoding?
              s
            else
              if @tool_version && @path
                @url = ga4gh_trs_v2_tool_versions_descriptor_url(id: @tool_version.parent.id,
                                                                 version_id: @tool_version.version,
                                                                 type: "PLAIN_#{@tool_version.descriptor_type.first.upcase}",
                                                                 relative_path: @path,
                                                                 host: Seek::Config.host_with_port)
              end
              nil
            end
          end
        end

        def url
          remote? ? uri&.to_s : @url
        end

        def checksum
          [] # [{ type: 'SHA-256', checksum: 'bla' }]
        end
      end
    end
  end
end
