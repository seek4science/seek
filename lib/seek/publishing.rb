module Seek
  module Publishing

    def self.included(base)
      base.before_filter :set_asset, :only=>[:preview_publish,:publish,:approve_or_reject_publish,:approve_publish,:reject_publish]
      base.before_filter :publish_auth, :only=>[:preview_publish,:publish]
      base.before_filter :gatekeeper_auth, :uuid_auth, :only => [:approve_or_reject_publish, :approve_publish, :reject_publish]
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
      respond_to do |format|
         if policy.save
           flash[:notice]="Publishing complete"
           format.html{redirect_to @asset}
         else
           flash[:error] = "There is a problem in making this item published"
         end
      end
    end

    def reject_publish
      respond_to do |format|
         flash[:notice]="You rejected to publish this item"
         format.html{redirect_to @asset}
      end
    end

    def preview_publish
      asset_type_name = @template.text_for_resource @asset

      respond_to do |format|
        format.html { render :template=>"assets/publish/preview",:locals=>{:asset_type_name=>asset_type_name} }
      end
    end

    def publish
      items_for_publishing = resolve_publish_params params[:publish]
      items_for_publishing << @asset unless items_for_publishing.include? @asset
      @notified_items = items_for_publishing.select{|i| !i.can_manage?}
      @published_items = items_for_publishing - @notified_items

      @problematic_items = @published_items.select{|item| !item.publish!}

      if Seek::Config.email_enabled && !@notified_items.empty?
        deliver_publishing_notifications @notified_items
      end

      @published_items = @published_items - @problematic_items

      respond_to do |format|
        flash.now[:notice]="Publishing complete"
        format.html { render :template=>"assets/publish/published" }
      end
    end

    def set_asset
      c = self.controller_name.downcase
      @asset = eval("@"+c.singularize) || self.controller_name.classify.constantize.find_by_id(params[:id])
    end

    def publish_auth
      unless Seek::Config.publish_button_enabled
        error("This feature is is not yet currently available","invalid route")
        return false
      end
    end

    def gatekeeper_auth
      unless current_user.try(:person).try(:is_gatekeeper?) && !(@asset.projects & current_user.try(:person).try(:projects)).empty?
        error("You have to login as a gatekeeper to perform this action", "is invalid (insufficient_privileges)")
        return false
      end
    end

    def uuid_auth
        unless @asset.respond_to?(:uuid) and params[:uuid] == @asset.uuid
          error("Invalid route", "is invalid (invalid route)")
          return false
        end
    end

    private

    def deliver_request_publish_approval sharing, item
      if (sharing and sharing[:request_publish_approval]) && Seek::Config.email_enabled && !item.gatekeepers.empty?
        Mailer.deliver_request_publish_approval item.gatekeepers, User.current_user,item,base_host
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
        Mailer.deliver_request_publishing User.current_user.person,owner,owners_items[owner],base_host
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