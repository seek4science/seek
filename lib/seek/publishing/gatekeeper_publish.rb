module Seek
  module Publishing
    module GatekeeperPublish
      def self.included(base)
        base.before_filter :set_resource, :only=>[:approve_or_reject_publish,:gatekeeper_decide]
        base.before_filter :gatekeeper_auth, :only => [:approve_or_reject_publish, :gatekeeper_decide]
        base.before_filter :waiting_for_approval_auth, :only => [:gatekeeper_decide]
      end

      def approve_or_reject_publish
        asset_type_name = @template.text_for_resource @resource

        respond_to do |format|
          format.html { render :template=>"assets/publishing/approve_or_reject_publish",:locals=>{:asset_type_name=>asset_type_name} }
        end
      end

      def gatekeeper_decide
        gatekeeper_decision = params[:gatekeeper_decision].to_i
        #approve
        if gatekeeper_decision == 1
          policy = @resource.policy
          policy.access_type=Policy::ACCESSIBLE
          policy.sharing_scope=Policy::EVERYONE
          respond_to do |format|
            if policy.save
              ResourcePublishLog.add_publish_log(ResourcePublishLog::PUBLISHED,@resource)
              process_gatekeeper_feedback 'approve'
              flash[:notice]="Publishing complete"
              format.html{redirect_to @resource}
            else
              flash[:error] = "There is a problem in making this item published"
            end
          end
          #reject
        elsif gatekeeper_decision == 0
          extra_comment = params[:extra_comment]
          process_gatekeeper_feedback 'reject', extra_comment
          respond_to do |format|
            flash[:notice]="You rejected to publish this item"
            format.html{redirect_to @resource}
          end
        end
      end

      def set_resource
        @resource = self.controller_name.classify.constantize.find_by_id(params[:id])
      end

      def gatekeeper_auth
        if @resource.nil?
          error("This #{self.controller_name.humanize.singularize} no longer exists, and may have been deleted since the request to publish was made.", "asset missing")
          return false
        end
        unless @resource.gatekeepers.include?(current_user.try(:person))
          error("You have to login as a gatekeeper to perform this action", "is invalid (insufficient_privileges)")
          return false
        end
      end

      def waiting_for_approval_auth
        latest_publish_state = ResourcePublishLog.find(:last, :conditions => ["resource_type=? AND resource_id=?", @resource.class.name, @resource.id])
        unless latest_publish_state.try(:publish_state).to_i == ResourcePublishLog::WAITING_FOR_APPROVAL
          error("This item is already published or you are not authorized to approve/reject the publishing of this item", "is invalid (insufficient_privileges)")
          return false
        end
      end

      private

      def process_gatekeeper_feedback result, extra_comment=nil
        latest_unpublished_log =  ResourcePublishLog.last(:conditions => ["resource_type=? AND resource_id=? AND publish_state=?",
                                                                          @resource.class.name, @resource.id, ResourcePublishLog::UNPUBLISHED])
        if latest_unpublished_log.nil?
          requesters = ResourcePublishLog.find(:all, :conditions => ["resource_type=? AND resource_id=? AND publish_state=?",
                                                                     @resource.class.name, @resource.id, ResourcePublishLog::WAITING_FOR_APPROVAL]).collect(&:culprit)
        else
          requesters = ResourcePublishLog.find(:all, :conditions => ["resource_type=? AND resource_id=? AND publish_state=? AND created_at >?",
                                                                     @resource.class.name, @resource.id, ResourcePublishLog::WAITING_FOR_APPROVAL,latest_unpublished_log.created_at ]).collect(&:culprit)
        end
        requesters.compact.each do |requester|
          if !requester.kind_of?(Person) && requester.respond_to?(:person)
            requester = requester.person
          end

          if result == "approve"
            deliver_gatekeeper_approval_feedback requester
          elsif result == "reject"
            deliver_gatekeeper_reject_feedback requester, extra_comment
          end
        end
      end

      def deliver_gatekeeper_approval_feedback requester
        if (Seek::Config.email_enabled)
          begin
            Mailer.deliver_gatekeeper_approval_feedback requester, current_user.person , @resource, base_host
          rescue Exception => e
            Rails.logger.error("Error sending gatekeeper approval feedback email to the requester #{requester.name}- #{e.message}")
          end
        end
      end

      def deliver_gatekeeper_reject_feedback requester, extra_comment
        if (Seek::Config.email_enabled)
          begin
            Mailer.deliver_gatekeeper_reject_feedback requester, current_user.person , @resource, extra_comment, base_host
          rescue Exception => e
            Rails.logger.error("Error sending gatekeeper reject feedback email to the requester #{requester.name}- #{e.message}")
          end
        end
      end

      def deliver_request_publish_approval item
        if (Seek::Config.email_enabled)
          begin
            Mailer.deliver_request_publish_approval item.gatekeepers, User.current_user,item,base_host
          rescue Exception => e
            Rails.logger.error("Error sending request publish email to a gatekeeper - #{e.message}")
          end
        end
      end

    end
  end
end