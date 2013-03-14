module Seek
  module Publishing
    module SinglePublishing
      def self.included(base)
        base.before_filter :set_item, :only => [:single_publish]
        base.before_filter :single_publish_auth, :only=>[:single_publish]
      end

      def single_publish
        if @item.publish!
          ResourcePublishLog.add_publish_log ResourcePublishLog::PUBLISHED, @item
        else
          ResourcePublishLog.add_publish_log ResourcePublishLog::WAITING_FOR_APPROVAL, @item
          deliver_request_publish_approval @item
        end    

        respond_to do |format|
          flash[:notice]="Publishing complete"
          format.html { redirect_to @item }
        end
      end
      
      #only for the item that can_publish? or (the item that can_manage? and the publishing request has not been sent by the current user)
      def single_publish_auth
        if @item.is_published? || !@item.publish_authorized?
          error("You are not authorized to publish this item or it is already published", "is invalid")
        end
      end

      def set_item
        begin
          @item = self.controller_name.classify.constantize.find_by_id(params[:id])
        rescue ActiveRecord::RecordNotFound
          error("This resource is not found","not found resource")
        end
      end
    end
  end
end