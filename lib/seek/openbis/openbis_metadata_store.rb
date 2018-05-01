module Seek
  module Openbis
    # Handles the storage and caching of the OpenBIS metadata. Delegates and operates around a rails filestore cache,
    # configured to point to a non-temporary filestore location based upon the endpoint
    # but it automatically expires the queries as metadata are now stored permanently in ExternalAssets
    class OpenbisMetadataStore
      delegate :fetch, :exist?, to: :cache

      def initialize(endpoint)
        @endpoint = endpoint
        options = { expires_in: endpoint.refresh_period_mins.minutes }
        @cache = ActiveSupport::Cache::FileStore.new(filestore_path, options)
      end

      # clears all stored metadata for this endpoint
      def clear
        # TODO: this is rather brutal, in future need to be able to revert
        Rails.logger.info("Clearing OpenbisMedataStore at #{filestore_path}")
        # cache.delete_matched(/.*/)
        # need to add an entry to empty cache otherwise the clear failes on unexisting deak
        cache.fetch('fake') { '' } unless File.exist?(cache.cache_path)
        cache.clear
      end

      # cleanups expired entries
      def cleanup
        Rails.logger.info("Clearing expired in OpenbisMedataStore at #{filestore_path}")
        cache.cleanup
      end

      private

      attr_reader :endpoint
      attr_reader :cache

      def filestore_path
        File.join(Seek::Config.append_filestore_path('openbis-metadata'), endpoint_key)
      end

      def endpoint_key
        if endpoint.new_record? # required to handle fetching spaces during the endpoint creation
          str = "#{endpoint.cache_key}-#{endpoint.space_perm_id}"
          str << "-#{endpoint.as_endpoint}-#{endpoint.dss_endpoint}-#{endpoint.username}"
          "new/#{Digest::SHA2.hexdigest(str)}"
        else
          # Update stamp removed as otherwise the previous caches stays after each update
          # "#{endpoint.id}/#{endpoint.updated_at.utc}"
          "#{endpoint.id}/cache"
        end
      end
    end
  end
end
