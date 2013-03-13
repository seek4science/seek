module Seek
  module Publishing
    module IsaPublishing

      def self.included(base)
        base.before_filter :set_asset, :only=>[:isa_publishing_preview,:isa_publish]
      end

      def isa_publishing_preview
        asset_type_name = @template.text_for_resource @asset

        respond_to do |format|
          format.html { render :template=>"assets/publishing/isa_publishing_preview",:locals=>{:asset_type_name=>asset_type_name} }
        end
      end

      def isa_publish
        if request.post?
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

          respond_to do |format|
            flash.now[:notice]="Publishing complete"
            format.html { render :template=>"assets/publishing/isa_published" }
          end
        else
          redirect_to @asset
        end
      end

      def set_asset
        @asset = self.controller_name.classify.constantize.find_by_id(params[:id])
      end

      private

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

    end
  end
end