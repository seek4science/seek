module Seek
  module Publishing
    module PublishingCommon
      def self.included(base)
        #has to be before log_publishing, coz relying on log
        base.after_filter :request_publish_approval, :only=>[:create,:update]
        base.after_filter :log_publishing, :only=>[:create,:update]
      end

      def isa_publishing_preview
        item = params[:item_type].constantize.find_by_id(params[:item_id])
        publish_related_items = params["#{item.class.name}_#{item.id}_related_items_checked"]
        if publish_related_items == 'true'
          render :update do |page|
            page.replace_html "#{item.class.name}_#{item.id}_isa_preview", :partial => "assets/publishing/isa_publishing_preview" ,
                              :object => item

          end
        else
          render :update do |page|
            page.replace_html "#{item.class.name}_#{item.id}_isa_preview", "<div id='#{item.class.name}_#{item.id}_isa_preview'></div>"

          end
        end
      end

      def publish
        if request.post?
          do_publish
          respond_to do |format|
            flash.now[:notice]="Publishing complete"
            format.html { render :template=>"assets/publishing/published" }
          end
        else
          redirect_to :action=>:show
        end
      end

      private

      def do_publish
        items_for_publishing = resolve_publish_params params[:publish]
        items_for_publishing = items_for_publishing.select{|i| !i.is_published?}
        @notified_items = items_for_publishing.select{|i| !i.can_manage?}
        publish_authorized_items = (items_for_publishing - @notified_items).select(&:publish_authorized?)
        @published_items = publish_authorized_items.select(&:can_publish?)
        @waiting_for_publish_items = publish_authorized_items - @published_items

        if Seek::Config.email_enabled && !@notified_items.empty?
          deliver_publishing_notifications @notified_items
        end

        @published_items.each do |item|
          item.publish!
          ResourcePublishLog.add_publish_log ResourcePublishLog::PUBLISHED, item
        end

        @waiting_for_publish_items.each do |item|
          ResourcePublishLog.add_publish_log ResourcePublishLog::WAITING_FOR_APPROVAL, item
          deliver_request_publish_approval item
        end
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

      def deliver_publishing_notifications items_for_notification
        owners_items={}
        items_for_notification.each do |item|
          item.managers.each do |person|
            owners_items[person]||=[]
            owners_items[person] << item
          end
        end

        owners_items.keys.each do |owner|
          begin
            Mailer.deliver_request_publishing User.current_user.person,owner,owners_items[owner],base_host
          rescue Exception => e
            Rails.logger.error("Error sending notification email to the owner #{owner.name} - #{e.message}")
          end
        end
      end

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