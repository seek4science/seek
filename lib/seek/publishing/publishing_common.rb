module Seek
  module Publishing
    module PublishingCommon
      def self.included(base)
        base.before_action :set_asset, only: [:check_related_items, :publish_related_items, :check_gatekeeper_required, :publish, :published]
        base.before_action :set_assets, only: [:batch_publishing_preview]
        base.before_action :set_items_for_publishing, only: [:check_gatekeeper_required, :publish]
        base.before_action :set_items_for_potential_publishing, only: [:check_related_items, :publish_related_items]
        base.before_action :publish_auth, only: [:batch_publishing_preview, :check_related_items, :publish_related_items, :check_gatekeeper_required, :publish, :waiting_approval_assets]
        # need to put request_publish_approval after log_publishing, so request_publish_approval will get run first.
        base.after_action :log_publishing, :request_publish_approval, only: [:create, :update]
      end

      def batch_publishing_preview
        respond_to do |format|
          format.html { render template: 'assets/publishing/batch_publishing_preview' }
        end
      end

      def check_related_items
        contain_related_items = @items_for_publishing.select(&:contains_publishable_items?).flatten.any?
        if contain_related_items
          respond_to do |format|
            format.html { render template: 'assets/publishing/publish_related_items_confirm' }
          end
        else
          check_gatekeeper_required
        end
      end

      def publish_related_items
        respond_to do |format|
          format.html { render template: 'assets/publishing/publish_related_items' }
        end
      end

      def check_gatekeeper_required
        @waiting_for_publish_items = @items_for_publishing.select { |item| item.gatekeeper_required? && !User.current_user.person.is_asset_gatekeeper_of?(item) }
        @items_for_immediate_publishing = @items_for_publishing - @waiting_for_publish_items
        unless @waiting_for_publish_items.empty?
          respond_to do |format|
            format.html { render template: 'assets/publishing/waiting_approval_list' }
          end
        else
          publish_final_confirmation
        end
      end

      def publish_final_confirmation
        respond_to do |format|
          format.html { render template: 'assets/publishing/publish_final_confirmation' }
        end
      end

      def publish
        publish_requested_items

        respond_to do |format|
          if @asset && request.env['HTTP_REFERER'].try(:normalize_trailing_slash) == polymorphic_url(@asset).normalize_trailing_slash
            flash[:notice] = 'Publishing complete'
            format.html { redirect_to @asset }
          else
            flash[:notice] = 'Publishing complete'
            format.html do
              redirect_to action: :published,
                          published_items: params_for_published_items(@published_items),
                          notified_items: params_for_published_items(@notified_items),
                          waiting_for_publish_items: params_for_published_items(@waiting_for_publish_items)
            end
          end
        end
      end

      def published
        respond_to do |format|
          format.html { render template: 'assets/publishing/published' }
        end
      end

      def waiting_approval_assets
        @waiting_approval_assets = ResourcePublishLog.waiting_approval_assets_for(current_user)
        respond_to do |format|
          format.html { render template: 'assets/publishing/waiting_approval_assets' }
        end
      end

      private

      def publish_auth
        if controller_name == 'people'
          unless User.logged_in_and_registered? && current_user.person.id == params[:id].to_i
            error('You are not permitted to perform this action', 'is invalid (not yourself)')
            return false
          end
        else
          unless @asset.can_publish? || @asset.contains_publishable_items?
            error('You are not permitted to perform this action', 'is invalid')
            return false
          end
        end
      end

      def set_asset
        unless controller_name == 'people'
          @asset = controller_model.find(params[:id])
        end
      rescue ActiveRecord::RecordNotFound
        error('This resource is not found', 'not found resource')
      end

      def set_assets
        # get the assets that current_user can manage, then take the one that can_publish?
        @assets = {}
        publishable_types = Seek::Util.authorized_types.select { |authorized_type| authorized_type.first.try(:is_in_isa_publishable?) }
        publishable_types.each do |klass|
          can_manage_assets = klass.authorized_for 'manage', current_user
          can_manage_assets = can_manage_assets.select(&:can_publish?)
          unless can_manage_assets.empty?
            @assets[klass.name] = can_manage_assets
          end
        end
      end

      # sets the @items_for_publishing based on the :publish param, and filtered by whether than can_publish?
      def set_items_for_publishing
        @items_for_publishing = resolve_publish_params(params[:publish]).select(&:can_publish?)
      end

      # sets the @items_for_publishing based on the :publish param, and filtered by whether than can_publish? OR contains_publishable_items?
      def set_items_for_potential_publishing
        @items_for_publishing = resolve_publish_params(params[:publish]).select { |item| item.can_publish? || item.contains_publishable_items? }
      end

      def log_publishing
        User.with_current_user current_user do
          object = object_for_request

          # don't log if the object is not valid or has not been saved, as this will a validation error on update or create
          return if object_invalid_or_unsaved?(object)

          # waiting for approval
          log_state = determine_state_for_log(object)

          ResourcePublishLog.add_log(log_state, object) if log_state
        end
      end

      def request_publish_approval
        User.with_current_user current_user do
          object = object_for_request

          # don't process if the object is not valid or has not been saved, as this will a validation error on update or create
          return if object_invalid_or_unsaved?(object)

          if is_gatekeeper_approval_required?(object) && !object.is_waiting_approval?(current_user)
            notify_gatekeepers_of_approval_request [object]
          end
        end
      end

      # recipients can be :gatekeepers or :managers
      def deliver_publishing_notification_emails(recipients, items, delivery_method)
        if Seek::Config.email_enabled
          recipient_items = gather_recipients_for_items(items, recipients)

          recipient_items.keys.each do |recipient|
            begin
              Mailer.send(delivery_method, recipient, User.current_user.person, recipient_items[recipient]).deliver_later
            rescue Exception => e
              Rails.logger.error("Error sending notification email to the owner #{gatekeeper.name} - #{e.message}")
            end
          end
        end
      end

      # recipients can be :gatekeepers or :managers
      def gather_recipients_for_items(items, recipients)
        recipient_items = {}
        items.each do |item|
          item.send(recipients).each do |person|
            recipient_items[person] ||= []
            recipient_items[person] << item
          end
        end
        recipient_items
      end

        def grant_gatekeepers_view_permission(items)
        items.each do |item|
          item.asset_gatekeepers.each do |gatekeeper|

            unless item.can_view?(gatekeeper)
              begin

                permission = item.policy.permissions.where(contributor: gatekeeper).first_or_initialize
                permission.update_attributes(contributor: gatekeeper, access_type: Policy::ACCESSIBLE)

              rescue Exception => e
                Rails.logger.error("Error when granting the accessible permission to the owner #{gatekeeper.name} - #{e.message}")
              end
            end
          end
        end
      end

      def notify_gatekeepers_of_approval_request(items)
        deliver_publishing_notification_emails :asset_gatekeepers, items, :request_publish_approval
      end

      def notify_owner_of_publishing_request(items)
        deliver_publishing_notification_emails :managers, items, :request_publish
      end

      # returns an enumeration of assets for publishing based upon the parameters passed
      def resolve_publish_params(param)
        if param.blank?
          [@asset].compact
        else
          assets = []
          param.keys.each do |asset_class|
            klass = asset_class.constantize
            param[asset_class].keys.each do |id|
              assets << klass.find_by_id(id)
            end
          end
          assets.compact.uniq
        end
      end

      def params_for_published_items(published_items)
        published_items.collect { |item| "#{item.class.name},#{item.id}" }
      end

      def publish_requested_items
        @published_items = @items_for_publishing.select(&:publish!)
        @notified_items = (@items_for_publishing - @published_items).select { |item| !item.can_manage? }
        @waiting_for_publish_items = @items_for_publishing - @published_items - @notified_items

        notify_owner_of_publishing_request @notified_items

        @waiting_for_publish_items.each do |item|
          ResourcePublishLog.add_log ResourcePublishLog::WAITING_FOR_APPROVAL, item
        end

        notify_gatekeepers_of_approval_request @waiting_for_publish_items
        grant_gatekeepers_view_permission @waiting_for_publish_items
      end

      def determine_state_for_log(object)
        if is_gatekeeper_approval_required?(object)
          ResourcePublishLog::WAITING_FOR_APPROVAL
          # publish
        elsif was_item_published?(object)
          ResourcePublishLog::PUBLISHED
          # unpublish
        elsif was_item_unpublished?(object)
          ResourcePublishLog::UNPUBLISHED
        end
      end

      def was_item_published?(object)
        object.is_published? && !last_log_state_published?(object)
      end

      def is_gatekeeper_approval_required?(object)
        will_be_published?(object, params[:policy_attributes]) && # Incoming policy change counts as "publishing"
          !object.is_published? && # Not already published
          object.gatekeeper_required? && # Gatekeeper required
          !User.current_user.person.is_asset_gatekeeper_of?(object) # Current user is not the gatekeeper
      end

      def was_item_unpublished?(object)
        !object.is_published? && last_log_state_published?(object)
      end

      def last_log_state_published?(object)
        object.last_publishing_log.try(:publish_state) == ResourcePublishLog::PUBLISHED
      end

      def will_be_published?(object, policy_params)
        policy_params &&
            (policy_params[:access_type].to_i >= (object.is_downloadable? ? Policy::ACCESSIBLE : Policy::VISIBLE))
      end
    end
  end
end
