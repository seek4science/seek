module Seek
  module Publishing
    module PublishingCommon
      def self.included(base)
        base.before_filter :set_asset, :only=>[:check_related_items,:publish_related_items,:check_gatekeeper_required,:publish]
        base.before_filter :set_assets, :only=>[:batch_publishing_preview]
        base.before_filter :set_items_for_publishing, :only => [:check_related_items,:publish_related_items,:check_gatekeeper_required,:publish]
        base.before_filter :publish_auth, :only=>[:batch_publishing_preview,:check_related_items,:publish_related_items,:check_gatekeeper_required,:publish,:waiting_approval_assets]
        #need to put request_publish_approval after log_publishing, so request_publish_approval will get run first.
        base.after_filter :log_publishing,:request_publish_approval, :only=>[:create,:update]
      end

      def batch_publishing_preview
        respond_to do |format|
          format.html { render :template=>"assets/publishing/batch_publishing_preview" }
        end
      end

      def check_related_items
        contain_related_items = !@items_for_publishing.collect(&:assays).flatten.empty?
        if contain_related_items
          respond_to do |format|
            format.html { render :template => "assets/publishing/publish_related_items_confirm"}
          end
        else
          check_gatekeeper_required
        end
      end

      def publish_related_items
        respond_to do |format|
          format.html { render :template => "assets/publishing/publish_related_items"}
        end
      end

      def check_gatekeeper_required
        @waiting_for_publish_items = @items_for_publishing.select { |item| item.gatekeeper_required? && !User.current_user.person.is_gatekeeper_of?(item) }
        @items_for_immediate_publishing = @items_for_publishing - @waiting_for_publish_items
        if !@waiting_for_publish_items.empty?
          respond_to do |format|
            format.html { render :template => "assets/publishing/waiting_approval_list" }
          end
        else
          publish_final_confirmation
        end
      end

      def publish_final_confirmation
        respond_to do |format|
          format.html { render :template => "assets/publishing/publish_final_confirmation"}
        end
      end

      def publish
        @published_items = @items_for_publishing.select(&:publish!)
        @notified_items = (@items_for_publishing - @published_items).select{|item| !item.can_manage?}
        @waiting_for_publish_items = @items_for_publishing - @published_items - @notified_items

        if Seek::Config.email_enabled && !@notified_items.empty?
          deliver_publishing_notifications @notified_items
        end

        @waiting_for_publish_items.each do |item|
          ResourcePublishLog.add_log ResourcePublishLog::WAITING_FOR_APPROVAL, item
        end
        deliver_request_publish_approval @waiting_for_publish_items

        respond_to do |format|
          if @asset && request.env['HTTP_REFERER'].try(:normalize_trailing_slash) == polymorphic_url(@asset).normalize_trailing_slash
            flash[:notice]="Publishing complete"
            format.html { redirect_to @asset }
          else
            flash[:notice]="Publishing complete"
            format.html { redirect_to :action => :published,
                                      :published_items => @published_items.collect{|item| "#{item.class.name},#{item.id}"},
                                      :notified_items => @notified_items.collect{|item| "#{item.class.name},#{item.id}"},
                                      :waiting_for_publish_items => @waiting_for_publish_items.collect{|item| "#{item.class.name},#{item.id}"} }
          end
        end
      end

      def published
        respond_to do |format|
          format.html { render :template => "assets/publishing/published"}
        end
      end

      def waiting_approval_assets
        @waiting_approval_assets = ResourcePublishLog.waiting_approval_assets_for(current_user)
        respond_to do |format|
          format.html {render :template => "assets/publishing/waiting_approval_assets"}
        end
      end

      private

      def publish_auth
        if self.controller_name=='people'
          if !(User.logged_in_and_registered? && current_user.person.id == params[:id].to_i)
            error("You are not permitted to perform this action", "is invalid (not yourself)")
            return false
          end
        else
          if !@asset.can_publish?
            error("You are not permitted to perform this action", "is invalid")
            return false
          end
        end
      end

      def set_asset
        begin
          if !(self.controller_name=='people')
            @asset = self.controller_name.classify.constantize.find(params[:id])
          end
        rescue ActiveRecord::RecordNotFound
          error("This resource is not found","not found resource")
        end
      end

      def set_assets
        #get the assets that current_user can manage, then take the one that can_publish?
        @assets = {}
        publishable_types = Seek::Util.authorized_types.select {|c| c.first.try(:is_in_isa_publishable?)}
        publishable_types.each do |klass|
          can_manage_assets = klass.all_authorized_for "manage", current_user
          can_manage_assets = can_manage_assets.select{|a| a.can_publish?}
          unless can_manage_assets.empty?
            @assets[klass.name] = can_manage_assets
          end
        end
      end

      def set_items_for_publishing
        @items_for_publishing = resolve_publish_params(params[:publish]).select(&:can_publish?)
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
          if params[:sharing] && params[:sharing][:sharing_scope].to_i == Policy::EVERYONE && object.gatekeeper_required? && !User.current_user.person.is_gatekeeper_of?(object)
            ResourcePublishLog.add_log(ResourcePublishLog::WAITING_FOR_APPROVAL,object)
            #publish
          elsif object.policy.sharing_scope == Policy::EVERYONE && latest_publish_log.try(:publish_state) != ResourcePublishLog::PUBLISHED
            ResourcePublishLog.add_log(ResourcePublishLog::PUBLISHED,object)
            #unpublish
          elsif object.policy.sharing_scope != Policy::EVERYONE && latest_publish_log.try(:publish_state) == ResourcePublishLog::PUBLISHED
            ResourcePublishLog.add_log(ResourcePublishLog::UNPUBLISHED,object)
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

          if params[:sharing] && params[:sharing][:sharing_scope].to_i == Policy::EVERYONE && object.gatekeeper_required? && !User.current_user.person.is_gatekeeper_of?(object) && !object.is_waiting_approval?(current_user)
            deliver_request_publish_approval [object]
          end
        end
      end

      def deliver_request_publish_approval items
        if (Seek::Config.email_enabled)
          gatekeepers_items={}
          items.each do |item|
            item.gatekeepers.each do |person|
              gatekeepers_items[person]||=[]
              gatekeepers_items[person] << item
            end
          end

          gatekeepers_items.keys.each do |gatekeeper|
            begin
              Mailer.request_publish_approval(gatekeeper, User.current_user, gatekeepers_items[gatekeeper],base_host).deliver
            rescue Exception => e
              Rails.logger.error("Error sending notification email to the owner #{gatekeeper.name} - #{e.message}")
            end
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
            Mailer.request_publishing(User.current_user.person,owner,owners_items[owner],base_host).deliver
          rescue Exception => e
            Rails.logger.error("Error sending notification email to the owner #{owner.name} - #{e.message}")
          end
        end
      end

      #returns an enumeration of assets for publishing based upon the parameters passed
      def resolve_publish_params param
        assets = []
        assets << @asset if @asset

        return assets if param.nil?

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