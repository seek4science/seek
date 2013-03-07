module Seek
  module Publishing

    def self.included(base)
      base.before_filter :set_asset, :only=>[:preview_publish,:publish,:approve_or_reject_publish,:approve_publish,:reject_publish]
      base.before_filter :publish_auth, :only=>[:preview_publish,:publish]
      base.before_filter :gatekeeper_auth, :only => [:approve_or_reject_publish, :approve_publish, :reject_publish]
      base.before_filter :waiting_for_approval_auth, :only => [:approve_publish, :reject_publish]
      base.after_filter :log_publishing, :only => [:create, :update, :approve_publish]
    end

    def approve_or_reject_publish
      asset_type_name = @template.text_for_resource @asset

      respond_to do |format|
        format.html { render :template=>"assets/publish/approve_or_reject_publish",:locals=>{:asset_type_name=>asset_type_name} }
      end
    end

    def approve_publish
      policy = @asset.policy
      policy.access_type=Policy::ACCESSIBLE
      policy.sharing_scope=Policy::EVERYONE
      if @asset.kind_of?(Strain)
        policy.permissions = []
      end
      respond_to do |format|
         if policy.save
           flash[:notice]="Publishing complete"
           format.html{redirect_to @asset.kind_of?(Strain) ? biosamples_path : @asset}
         else
           flash[:error] = "There is a problem in making this item published"
         end
      end
    end

    def reject_publish
      respond_to do |format|
         flash[:notice]="You rejected to publish this item"
         format.html{redirect_to @asset.kind_of?(Strain) ? biosamples_path : @asset}
      end
    end

    def preview_publish
      asset_type_name = @template.text_for_resource @asset

      respond_to do |format|
        format.html { render :template=>"assets/publish/preview",:locals=>{:asset_type_name=>asset_type_name} }
      end
    end

    def publish
      if request.post?
        items_for_publishing = resolve_publish_params params[:publish]
        @notified_items = items_for_publishing.select{|i| !i.can_manage?}
        @waiting_for_publish_items = items_for_publishing.select{|i| i.can_manage? && !i.can_publish?}
        @published_items = items_for_publishing - @waiting_for_publish_items - @notified_items

        @problematic_items = @published_items.select{|item| !item.publish!}

        if Seek::Config.email_enabled && !@notified_items.empty?
          deliver_publishing_notifications @notified_items
        end

        @waiting_for_publish_items.each do |item|
          ResourcePublishLog.add_publish_log ResourcePublishLog::WAITING_FOR_APPROVAL, item
          deliver_request_publish_approval item
        end

        @published_items = @published_items - @problematic_items

        @published_items.each do |item|
          latest_publish_log = ResourcePublishLog.last(:conditions => ["resource_type=? and resource_id=?",item.class.name,item.id])
          if item.policy.sharing_scope == Policy::EVERYONE && latest_publish_log.try(:publish_state) != ResourcePublishLog::PUBLISHED
            ResourcePublishLog.add_publish_log ResourcePublishLog::PUBLISHED, item
          end
        end

        respond_to do |format|
          flash.now[:notice]="Publishing complete"
          format.html { render :template=>"assets/publish/published" }
        end
      else
        redirect_to @asset
      end
    end

    def set_asset
      @asset = self.controller_name.classify.constantize.find_by_id(params[:id])
    end

    def publish_auth
      unless Seek::Config.publish_button_enabled
        error("This feature is is not yet currently available","invalid route")
        return false
      end
    end

    def gatekeeper_auth
      if @asset.nil?
         error("This #{self.controller_name.humanize.singularize} no longer exists, and may have been deleted since the request to publish was made.", "asset missing")
        return false
      end
      unless @asset.gatekeepers.include?(current_user.try(:person))
        error("You have to login as a gatekeeper to perform this action", "is invalid (insufficient_privileges)")
        return false
      end
    end

    def waiting_for_approval_auth
      latest_publish_state = ResourcePublishLog.find(:last, :conditions => ["resource_type=? AND resource_id=?", @asset.class.name, @asset.id])
      unless latest_publish_state.try(:publish_state).to_i == ResourcePublishLog::WAITING_FOR_APPROVAL
              error("This item is already published or you are not authorized to approve/reject the publishing of this item", "is invalid (insufficient_privileges)")
              return false
      end
    end

    private

    def log_publishing
      User.with_current_user current_user do
            c = self.controller_name.downcase
            a = self.action_name.downcase

            object = eval("@"+c.singularize)
            object = @asset if a == 'approve_publish'

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

    #returns an enumeration of assets, or ISA elements, for publishing based upon the parameters passed

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