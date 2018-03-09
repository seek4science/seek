module Seek
  module Openbis
    # Handles the storage and caching of the OpenBIS metadata. Delegates and operates around a rails filestore cache,
    # configured to point to a non-temporary filestore location based upon the endpoint
    class OpenbisMetadataStore
      delegate :fetch, :exist?, to: :cache

      def initialize(endpoint)
        @endpoint = endpoint
        @cache = ActiveSupport::Cache::FileStore.new(filestore_path)
      end

      # clears all stored metadata for this endpoint
      def clear
        # TODO: this is rather brutal, in future need to be able to revert
        Rails.logger.info("Clearing OpenbisMedataStore at #{filestore_path}")
        cache.delete_matched(/.*/)
      end

      private

      attr_reader :endpoint
      attr_reader :cache

      def filestore_path
        File.join(Seek::Config.append_filestore_path('openbis-metadata'), endpoint_key)
      end

      def endpoint_key
        if endpoint.new_record? # required to handle fetching spaces during the endpoint creation
          str="#{endpoint.cache_key}-#{endpoint.space_perm_id}"
          str << "-#{endpoint.as_endpoint}-#{endpoint.dss_endpoint}-#{endpoint.username}"
          "new/#{Digest::SHA2.hexdigest(str)}"
        else
          "#{endpoint.id}/#{endpoint.updated_at.utc}"
        end
      end
    end
  end
end
