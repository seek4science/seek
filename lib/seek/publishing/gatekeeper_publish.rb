module Seek
  module Publishing
    module GatekeeperPublish
      def self.included(base)
        base.before_filter :set_gatekeeper, :only=>[:requested_approval_assets,:gatekeeper_decide]
        base.before_filter :gatekeeper_auth, :only => [:requested_approval_assets, :gatekeeper_decide]
      end

      def requested_approval_assets
        @requested_approval_assets = ResourcePublishLog.requested_approval_assets_for(current_user.person)
        respond_to do |format|
          format.html {render :template => "assets/publishing/requested_approval_assets"}
        end
      end

      def gatekeeper_decide
        resolve_items_params params[:gatekeeper_decide]
        @problematic_items = @approve_items.select{|item| !item.publish!}

        deliver_gatekeeper_approval_feedback(@approve_items - @problematic_items)
        deliver_gatekeeper_reject_feedback(@reject_items)

        @reject_items.each do |item|
          item.reject params[:gatekeeper_decide]["#{item.class.name}"]["#{item.id}"]["comment"]
        end

        respond_to do |format|
          flash[:notice]="Publishing complete"
          format.html {render :template => "assets/publishing/gatekeeper_decision_result"}
        end
      end

      private

      def set_gatekeeper
        @gatekeeper = current_user.try(:person)
      end

      def gatekeeper_auth
        unless @gatekeeper.try(:is_gatekeeper?)
          error("You are not authorized to approve/reject the publishing of items. You might login as a gatekeeper.", "is invalid (insufficient_privileges)")
          return false
        end
      end

      def deliver_gatekeeper_approval_feedback items
        if (Seek::Config.email_enabled)
          requesters_items(items).keys.each do |requester|
            begin
              Mailer.gatekeeper_approval_feedback(requester, current_user.person , requesters_items[requester], base_host).deliver
            rescue Exception => e
              Rails.logger.error("Error sending gatekeeper approval feedback email to the requester #{requester.name}- #{e.message}")
            end
          end
        end
      end

      def deliver_gatekeeper_reject_feedback items
        if (Seek::Config.email_enabled)
          requesters_items(items).keys.each do |requester|
            begin
              #FIXME: add extra_comment.
              items_with_comment =[]
              requesters_items[requester].each do |item|
                items_with_comment << [item, params[:gatekeeper_decide]["#{item.class.name}"]["#{item.id}"]["comment"]]
              end
              Mailer.gatekeeper_reject_feedback(requester, current_user.person, items_with_comment, base_host).deliver
            rescue Exception => e
              Rails.logger.error("Error sending gatekeeper reject feedback email to the requester #{requester.name}- #{e.message}")
            end
          end
        end
      end

      def requesters_items items
        requesters_items={}
        items.each do |item|
          item.publish_requesters.each do |requester|
            requesters_items[requester]||=[]
            requesters_items[requester] << item
          end
        end
        requesters_items
      end

      def resolve_items_params param
        @approve_items = []
        @reject_items = []
        @decide_later_items = []

        return if param.nil?

        param.keys.each do |asset_class|
          param[asset_class].keys.each do |id|
            asset = eval("#{asset_class}.find_by_id(#{id})")
            decision = param[asset_class][id]['decision']
            case decision.to_i
              when 1
                @approve_items << asset
              when 0
                @reject_items << asset
              when -1
                @decide_later_items << asset
            end
          end
        end
        @approve_items.uniq!
        @reject_items.uniq!
        @decide_later_items.uniq!
      end

    end
  end
end