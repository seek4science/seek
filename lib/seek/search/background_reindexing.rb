module Seek
  module Search
    module BackgroundReindexing
      def self.included(mod)
        mod.after_save(:queue_background_reindexing)
      end

      module InstanceMethods
        def queue_background_reindexing
          return unless Seek::Config.solr_enabled
          unless (saved_changes.keys - %w(updated_at last_used_at)).empty?
            Rails.logger.info("About to reindex #{self.class.name} #{id}")
            ReindexingQueue.enqueue(self)
          end
        end
      end

      include InstanceMethods
    end
  end
end
