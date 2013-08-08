module Seek
  module Permissions
    module PublishingPermissions

      def self.included klass
        klass.class_eval do
          before_validation :temporary_policy_while_waiting_for_publishing_approval
          has_many :resource_publish_logs, :as => :resource
        end
      end

      def can_publish? user=User.current_user
        (Ability.new(user).can? :publish, self) || (can_manage?(user) && state_allows_publish?(user))
      end

      def state_allows_publish? user=User.current_user
        if self.new_record?
          return true if !self.gatekeeper_required?
          !self.is_waiting_approval?(user) && !self.is_rejected?
        else
          return false if self.is_published?
          return true if !self.gatekeeper_required?
          !self.is_waiting_approval?(user) && !self.is_rejected?
        end
      end

      def publish!
        if can_publish?
          if gatekeeper_required? && !User.current_user.person.is_gatekeeper_of?(self)
            false
          else
            policy.access_type=Policy::ACCESSIBLE
            policy.sharing_scope=Policy::EVERYONE
            policy.save
            self.resource_publish_logs.create(:publish_state=>ResourcePublishLog::PUBLISHED,:culprit=>User.current_user)
            touch
          end
        else
          false
        end
      end

      def is_published?
        policy = self.policy
        if self.is_downloadable?
           policy.public? && policy.access_type >= Policy::ACCESSIBLE
        else
          policy.public?
        end
      end

      def is_rejected? time=3.months.ago
        !ResourcePublishLog.where(["resource_type=? AND resource_id=? AND publish_state=? AND created_at >?",
                                                self.class.name,self.id,ResourcePublishLog::REJECTED, time]).empty?
      end

      def is_waiting_approval? user=nil,time=3.months.ago
        if user
          !ResourcePublishLog.where(["resource_type=? AND resource_id=? AND culprit_type=? AND culprit_id=? AND publish_state=? AND created_at >?",
                                                      self.class.name,self.id, user.class.name, user.id,ResourcePublishLog::WAITING_FOR_APPROVAL,time]).empty?
        else
          !ResourcePublishLog.where(["resource_type=? AND resource_id=? AND publish_state=? AND created_at >?",
                                                         self.class.name,self.id,ResourcePublishLog::WAITING_FOR_APPROVAL,time]).empty?
        end
      end

      def gatekeeper_required?
        !self.gatekeepers.empty?
      end

      def gatekeepers
        self.projects.collect(&:gatekeepers).flatten.uniq
      end

      #the asset that can be published together with publishing the whole ISA
      def is_in_isa_publishable?
        #currently based upon the naive assumption that downloadable items are publishable, which is currently the case but may change.
        is_downloadable?
      end

      #while item is waiting for publishing approval,set the policy of the item to:
      #new item: sysmo_and_project_policy
      #updated item: keep the policy as before
      def temporary_policy_while_waiting_for_publishing_approval
        return true if $authorization_checks_disabled
        if self.new_record? && self.policy.sharing_scope == Policy::EVERYONE && !self.kind_of?(Publication) && self.gatekeeper_required? && !User.current_user.person.is_gatekeeper_of?(self)
          self.policy = Policy.sysmo_and_projects_policy self.projects
        elsif !self.new_record? && self.policy.sharing_scope == Policy::EVERYONE && !self.kind_of?(Publication) && self.gatekeeper_required? && !User.current_user.person.is_gatekeeper_of?(self)
          self.policy = Policy.find_by_id(self.policy.id)
        end
      end

    end
  end
end
