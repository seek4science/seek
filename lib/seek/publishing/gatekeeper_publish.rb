module Seek
  module Publishing
    module GatekeeperPublish
      def self.included(base)
        base.before_filter :set_resource, :only=>[:approve_or_reject_publish,:gatekeeper_decide]
        base.before_filter :gatekeeper_auth, :only => [:approve_or_reject_publish, :gatekeeper_decide]
      end

      def approve_or_reject_publish
        respond_to do |format|
          format.html { render :template=>"assets/publishing/approve_or_reject_publish" }
        end
      end

      def gatekeeper_decide
        gatekeeper_decision = params[:gatekeeper_decision].to_i
        #approve
        if gatekeeper_decision == 1
          respond_to do |format|
            if @resource.publish!
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
          @resource.resource_publish_logs.create(:publish_state=>ResourcePublishLog::REJECTED,:culprit=>current_user,:comment=>extra_comment)

          respond_to do |format|
            flash[:notice]="You rejected to publish this item"
            format.html{redirect_to @resource}
          end
        end
      end

      def set_resource
        begin
          @resource = self.controller_name.classify.constantize.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          error("This resource is not found","not found resource")
          return false
        end
      end

      def gatekeeper_auth
        unless @resource.gatekeepers.include?(current_user.try(:person)) && @resource.is_waiting_approval?
          error("You are not authorized to approve/reject the publishing of this item. You might login as a gatekeeper.", "is invalid (insufficient_privileges)")
          return false
        end
      end

      private

      def process_gatekeeper_feedback result, extra_comment=nil
        latest_unpublished_log =  ResourcePublishLog.last(:conditions => ["resource_type=? AND resource_id=? AND publish_state=?",
                                                                          @resource.class.name, @resource.id, ResourcePublishLog::UNPUBLISHED])
        if latest_unpublished_log.nil?
          requesters = ResourcePublishLog.where(["resource_type=? AND resource_id=? AND publish_state=?",
                                                                     @resource.class.name, @resource.id, ResourcePublishLog::WAITING_FOR_APPROVAL]).collect(&:culprit)
        else
          requesters = ResourcePublishLog.where(["resource_type=? AND resource_id=? AND publish_state=? AND created_at >?",
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
            Mailer.gatekeeper_approval_feedback(requester, current_user.person , @resource, base_host).deliver
          rescue Exception => e
            Rails.logger.error("Error sending gatekeeper approval feedback email to the requester #{requester.name}- #{e.message}")
          end
        end
      end

      def deliver_gatekeeper_reject_feedback requester, extra_comment
        if (Seek::Config.email_enabled)
          begin
            Mailer.gatekeeper_reject_feedback(requester, current_user.person , @resource, extra_comment, base_host).deliver
          rescue Exception => e
            Rails.logger.error("Error sending gatekeeper reject feedback email to the requester #{requester.name}- #{e.message}")
          end
        end
      end
    end
  end
end