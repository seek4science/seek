module Seek
  module Sharing
    module SharingCommon

      def self.included(base)
        base.before_action :sharing_auth, only: [:batch_sharing_permission_preview, :batch_change_permission_for_selected_items, :batch_sharing_permission_changed]
      end

      def batch_change_permission_for_selected_items
        @items_for_sharing = resolve_sharing_params(params)
        if @items_for_sharing.empty?
          flash[:error] = "Please choose at least one item!"
          if params[:single_page]
            redirect_to batch_sharing_permission_preview_person_url(current_user.person, { single_page: true })
          else
            redirect_to batch_sharing_permission_preview_person_url(current_user.person)
          end
        else
          respond_to do |format|
            if params[:single_page]
              format.html { render 'single_pages/sample_sharing_bulk_change_preview', { layout: false } }
            else
              format.html { render 'assets/sharing/sharing_bulk_change_preview' }
            end
          end
        end
      end

      def batch_sharing_permission_preview
        @batch_sharing_permission_changed = false
        flash[:notice] = nil
        respond_to do |format|
          if params[:single_page]
            format.html { render 'single_pages/sample_batch_sharing_permission_preview', { layout: false } }
          else
            format.html { render 'assets/sharing/batch_sharing_permission_preview' }
          end
        end
      end

      def batch_sharing_permission_changed

        @items_for_sharing = resolve_sharing_params(params)
        @batch_sharing_permission_changed = true
        notice_count = 0
        gatekeeper_count = 0
        error_count = 0
        flash[:notice] = "The sharing policies for your selected #{"item".pluralize(@items_for_sharing.size)} were successfully updated:<ul id=\"ok\"> "
        gatekeeper_flash = "Publishing the following #{"item".pluralize(@items_for_sharing.size)} requires approval from a gatekeeper:<ul id=\"gk\"> "
        flash[:error] = "The sharing policies for your selected #{"item".pluralize(@items_for_sharing.size)} were not successfully updated:<ul> "
        @items_for_sharing.each do |item|
          item.policy.update_with_bulk_sharing_policy(policy_params) if policy_params.present?
          begin
            item.save!
            request_publish_approval_batch_sharing(item)  # Has to go before log_publishing_batch_sharing(item)
            log_publishing_batch_sharing(item)
            if item.is_waiting_approval? && is_gatekeeper_approval_required?(item)
              gatekeeper_count += 1
              gatekeeper_flash += "<li>#{item.title}</li>"
            else
              notice_count += 1
              flash[:notice] += "<li>#{item.title}</li>"
            end
          rescue Exception => e
            error_count += 1
            flash[:error] += "<li>#{item.title}<br>"
            flash[:error] += "The reason:  #{e.message}</li>"
          end
        end
        flash[:notice] = notice_count == 0 ? "": (flash[:notice]+"</ul>").html_safe
        flash[:notice] += gatekeeper_count == 0 ? "": (gatekeeper_flash+"</ul>"+"The #{"item".pluralize(gatekeeper_count)} will not be published until approved.").html_safe
        flash.now[:notice] = (notice_count+gatekeeper_count) == 0 ? nil: flash[:notice].html_safe
        flash.now[:error] = error_count == 0 ? nil: (flash[:error]+"</ul>").html_safe
        respond_to do |format|
          if params[:single_page]
            format.html { render 'single_pages/sample_batch_sharing_permission_preview', { layout: false } }
          else
            format.html { render 'assets/sharing/batch_sharing_permission_preview' }
          end
        end
      end

      def log_publishing_batch_sharing(object)
        User.with_current_user current_user do
          return if object_invalid_or_unsaved?(object)

          log_state = determine_state_for_log(object)
          ResourcePublishLog.add_log(log_state, object) if log_state
        end
      end

      # request_publish_approval_batch_sharing has to be called *before* log_publishing_batch_sharing to work!
      def request_publish_approval_batch_sharing(object)
        User.with_current_user current_user do
          return if object_invalid_or_unsaved?(object)

          if is_gatekeeper_approval_required?(object) && !object.is_waiting_approval?(current_user)
            notify_gatekeepers_of_approval_request [object]
          end
        end
      end

      private

      # returns an enumeration of assets for bulk sharing change based upon the parameters passed
      def resolve_sharing_params(params)
        param_not_isa = params[:share_not_isa] || {}
        param_isa = params[:share_isa] || {}

        if param_not_isa.blank? && param_isa.blank?
          [@asset].compact
        else
          assets = []
          Seek::Util.authorized_types.each do |klass|
            ids = (param_not_isa[klass.name]&.keys || []) | (param_isa[klass.name]&.keys || [])
            assets += klass.where(id: ids).to_a if ids.any?
          end
          assets.compact.uniq
        end
      end

      def sharing_auth
        if controller_name == 'people'
          unless User.logged_in_and_registered? && current_user.person.id == params[:id].to_i
            error('You are not permitted to perform this action.', 'is invalid (not yourself)')
            return false
          end
        end
      end
    end
  end
end
