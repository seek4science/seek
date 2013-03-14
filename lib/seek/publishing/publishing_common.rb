module Seek
  module Publishing
    module PublishingCommon
      def self.included(base)
        #has to be before log_publishing, coz relying on log
        base.after_filter :request_publish_approval, :only=>[:create,:update]
        base.after_filter :log_publishing, :only=>[:create,:update]
      end

      def log_publishing
        User.with_current_user current_user do
          c = self.controller_name.downcase
          a = self.action_name.downcase

          object = eval("@"+c.singularize)
          #don't log if the object is not valid or has not been saved, as this will a validation error on update or create
          return if object.nil? || (object.respond_to?("new_record?") && object.new_record?) || (object.respond_to?("errors") && !object.errors.empty?)

          latest_publish_log = ResourcePublishLog.last(:conditions => ["resource_type=? and resource_id=?",object.class.name,object.id])

          #waiting for approval
          if params[:sharing] && params[:sharing][:sharing_scope].to_i == Policy::EVERYONE && !object.can_publish?
            ResourcePublishLog.add_publish_log(ResourcePublishLog::WAITING_FOR_APPROVAL,object)
            #publish
          elsif object.policy.sharing_scope == Policy::EVERYONE && latest_publish_log.try(:publish_state) != ResourcePublishLog::PUBLISHED
            ResourcePublishLog.add_publish_log(ResourcePublishLog::PUBLISHED,object)
            #unpublish
          elsif object.policy.sharing_scope != Policy::EVERYONE && latest_publish_log.try(:publish_state) == ResourcePublishLog::PUBLISHED
            ResourcePublishLog.add_publish_log(ResourcePublishLog::UNPUBLISHED,object)
          end
        end
      end

      def request_publish_approval
        User.with_current_user current_user do
          c = self.controller_name.downcase
          a = self.action_name.downcase

          object = eval("@"+c.singularize)
          #don't process if the object is not valid or has not been saved, as this will a validation error on update or create
          return if object.nil? || (object.respond_to?("new_record?") && object.new_record?) || (object.respond_to?("errors") && !object.errors.empty?)

          if params[:sharing] && params[:sharing][:sharing_scope].to_i == Policy::EVERYONE && !object.can_publish? && ResourcePublishLog.last_waiting_approval_log(object).nil?
            deliver_request_publish_approval object
          end
        end
      end

      def deliver_request_publish_approval item
        if (Seek::Config.email_enabled)
          begin
            Mailer.deliver_request_publish_approval item.gatekeepers, User.current_user,item,base_host
          rescue Exception => e
            Rails.logger.error("Error sending request publish email to a gatekeeper - #{e.message}")
          end
        end
      end

      private

      #returns an enumeration of assets for publishing based upon the parameters passed
      def resolve_publish_params param
        return [] if param.nil?

        assets = []

        param.keys.each do |asset_class|
          param[asset_class].keys.each do |id|
            assets << eval("#{asset_class}.find_by_id(#{id})")
          end
        end
        assets.compact.uniq
      end
    end
  end
end