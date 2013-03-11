module Seek
  module Publishing
    module LogPublishing
      def self.included(base)
        base.after_filter :log_publishing, :only=>[:create,:update,:gatekeeper_decide]
      end

      def log_publishing
        User.with_current_user current_user do
          c = self.controller_name.downcase
          a = self.action_name.downcase

          object = eval("@"+c.singularize)
          object = @resource if a == 'gatekeeper_decide'
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

    end
  end
end