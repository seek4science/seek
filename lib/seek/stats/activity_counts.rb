module Seek
  module Stats
    #mixin for a model to add methods to get some activity stats
    module ActivityCounts
      extend ActiveSupport::Concern

      included do
        has_many :activity_logs, as: :activity_loggable
      end

      def download_count
        count_actions("download")
      end

      def view_count
        count_actions("show")
      end

      private

      def count_actions(actions=nil)
        if actions
          ActivityLog.no_spider.count(:conditions => {:action => actions, :activity_loggable_type => self.class.name, :activity_loggable_id => self.id})
        else
          ActivityLog.count(:conditions => {:activity_loggable_type => self.class.name, :activity_loggable_id => self.id})
        end
      end
    end
  end
end