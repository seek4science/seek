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
        error_count = 0
          flash[:notice] = "The sharing policies for your selected #{"item".pluralize(@items_for_sharing.size)} were successfully updated:<ul> "
          flash[:error] = "The sharing policies for your selected #{"item".pluralize(@items_for_sharing.size)} were not successfully updated:<ul> "
          @items_for_sharing.each do |item|
            item.policy.update_with_bulk_sharing_policy(policy_params) if policy_params.present?
            begin
              item.save!
              notice_count +=1
              flash[:notice] += "<li>#{item.title}</li>"
            rescue Exception => e
              error_count += 1
              flash[:error] += "<li>#{item.title}<br>"
              flash[:error] += "The reason:  #{e.message}</li>"
            end
          end
              flash.now[:notice] = notice_count==0 ? nil: (flash[:notice]+"</ul>").html_safe
              flash.now[:error] = error_count==0 ? nil: (flash[:error]+"</ul>").html_safe
          respond_to do |format|
            if params[:single_page]
              format.html { render 'single_pages/sample_batch_sharing_permission_preview', { layout: false } }
            else
              format.html { render 'assets/sharing/batch_sharing_permission_preview' }
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
