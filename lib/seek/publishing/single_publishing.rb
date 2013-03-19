module Seek
  module Publishing
    module SinglePublishing
      def self.included(base)
        base.before_filter :set_asset, :only=>[:single_publishing_preview,:single_publish,:isa_publishing_preview]
      end

      def single_publishing_preview
        respond_to do |format|
          asset_type_name = @template.text_for_resource @asset
          format.html { render :template=>"assets/publishing/single_publishing_preview",:locals=>{:asset_type_name=>asset_type_name} }
        end
      end

      def single_publish
        if request.post?
          publish_related_items = params["related_items_checked"]
          if publish_related_items == 'true'
            do_single_publish

            respond_to do |format|
              flash[:notice]="Publishing complete"
              format.html { redirect_to @asset }
            end
          else
            do_isa_publish

            respond_to do |format|
              flash.now[:notice]="Publishing complete"
              format.html { render :template=>"assets/publishing/single_published" }
            end
          end
        else
          redirect_to @asset
        end
      end

      def isa_publishing_preview
        publish_related_items = params["related_items_checked"]
        if publish_related_items == 'true'
          asset_type_name = @asset.class.name.humanize
          render :update do |page|
            page.replace_html "isa_preview", :partial => "assets/publishing/isa_publishing_preview" ,
                              :locals=>{:asset_type_name=>asset_type_name}

          end
        else
          render :update do |page|
            page.replace_html "isa_preview", "<div id'isa_preview'></div>"

          end
        end
      end

      def do_isa_publish
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

      def do_single_publish
        if @asset.publish!
          ResourcePublishLog.add_publish_log ResourcePublishLog::PUBLISHED, @asset
        else
          ResourcePublishLog.add_publish_log ResourcePublishLog::WAITING_FOR_APPROVAL, @asset
          deliver_request_publish_approval @asset
        end
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

      def set_asset
        begin
          @asset = self.controller_name.classify.constantize.find_by_id(params[:id])
        rescue ActiveRecord::RecordNotFound
          error("This resource is not found","not found resource")
        end
      end
    end
  end
end