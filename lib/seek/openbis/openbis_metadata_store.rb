module Seek
  module Openbis
    class OpenbisMetadataStore
      attr_reader :cache
      delegate :fetch, :delete_matched, :exist?, to: :cache

      def initialize
        @cache = ActiveSupport::Cache::FileStore.new(filestore_path)
      end

      private

      def filestore_path
        Seek::Config.append_filestore_path('openbis-metadata')
      end
    end
  end
end
