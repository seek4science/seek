module Seek
  module Publishing
    module BatchPublishing
      def self.included(base)
        base.before_filter :set_assets, :only=>[:batch_publishing_preview]
      end

      def batch_publishing_preview
        respond_to do |format|
          format.html { render :template=>"assets/publishing/batch_publishing_preview" }
        end
      end

      def batch_publish
        if request.post?
          items_for_publishing = resolve_publish_params params[:publish]
          items_for_publishing = items_for_publishing.select{|i| !i.is_published? && i.publish_authorized?}
          @published_items = items_for_publishing.select(&:can_publish?)
          @waiting_for_publish_items = items_for_publishing - @published_items
          @problematic_items = @published_items.select{|item| !item.publish!}

          @waiting_for_publish_items.each do |item|
            ResourcePublishLog.add_publish_log ResourcePublishLog::WAITING_FOR_APPROVAL, item
            deliver_request_publish_approval item
          end

          @published_items = @published_items - @problematic_items

          @published_items.each do |item|
             ResourcePublishLog.add_publish_log ResourcePublishLog::PUBLISHED, item
          end

          respond_to do |format|
            flash.now[:notice]="Batch publishing complete"
            format.html { render :template=>"assets/publishing/batch_published" }
          end
        else
          redirect_to :root
        end
      end

      def set_assets
        #get the assets that current_user can manage, then take the one that (is not yet published and is publish_authorized)
        @assets = {}

        publishable_types = Seek::Util.authorized_types.select { |c| c.first.try(:is_publishable?) }
        publishable_types.each do |klass|
          can_manage_assets = klass.all_authorized_for "manage", current_user
          can_manage_assets = can_manage_assets.select{|a| !a.is_published? && a.publish_authorized?}
          unless can_manage_assets.empty?
            @assets[klass.name] = can_manage_assets
          end
        end
      end
    end
  end
end

