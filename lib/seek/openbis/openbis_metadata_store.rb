module Seek
  module Openbis
    class OpenbisMetadataStore
      attr_reader :cache
      delegate :fetch, :exist?, to: :cache

      def initialize(endpoint)
        @endpoint=endpoint
        @cache = ActiveSupport::Cache::FileStore.new(filestore_path)
      end

      def clear
        #TODO: this is rather brutal, in the future a counter will form a new path which can be reverted to if things fail
        Rails.logger.info("Clearing OpenbisMedataStore at #{filestore_path}")
        cache.delete_matched(/.*/)
      end

      private

      attr_reader :endpoint

      def filestore_path
        File.join(Seek::Config.append_filestore_path('openbis-metadata'),endpoint_key)
      end

      def endpoint_key
        if endpoint.new_record? #TODO: double check why previous code needed to handle new_record?
          str="#{endpoint.cache_key}-#{endpoint.space_perm_id}-#{endpoint.as_endpoint}-#{endpoint.dss_endpoint}-#{endpoint.username}"
          Digest::SHA2.hexdigest(str)
        else
          endpoint.cache_key
        end
      end


    end
  end
end
