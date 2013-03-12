module Seek
  module Publishing
    module BatchPublishing
      def self.included(base)
        base.before_filter :login_required, :only=>[:batch_publishing_preview,:batch_publish]
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
          @waiting_for_publish_items = items_for_publishing.select{|i| i.can_manage? && !i.can_publish?}
          @published_items = items_for_publishing - @waiting_for_publish_items
          @problematic_items = @published_items.select{|item| !item.publish!}

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
            flash.now[:notice]="Batch publishing complete"
            format.html { render :template=>"assets/publishing/batch_published" }
          end
        else
          redirect_to :root
        end
      end

      def set_assets
        #get the assets that current_user can manage  + filture out the one that were aready published or the one that publish request was sent
        @assets = {}

        publishable_types = Seek::Util.authorized_types.select { |c| c.first.try(:is_publishable?) }
        publishable_types.each do |klass|
          can_manage_assets = klass.all_authorized_for "manage", current_user
          can_manage_assets = can_manage_assets.select{|a| !a.is_published?}
          can_manage_assets = can_manage_assets.select{|a| ResourcePublishLog.last_waiting_approval_log(a).nil?}
          unless can_manage_assets.empty?
            @assets[klass.name] = can_manage_assets
          end
        end
      end
    end
  end
end

