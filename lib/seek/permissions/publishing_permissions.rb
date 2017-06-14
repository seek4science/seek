module Seek
  module Permissions
    module PublishingPermissions
      def self.included(klass)
        klass.class_eval do
          before_validation :temporary_policy_while_waiting_for_publishing_approval
          has_many :resource_publish_logs, as: :resource
        end
      end

      def contains_publishable_items?
        items = [:studies, :study, :assays, :investigation, :assets].collect do |accessor|
          send(accessor) if self.respond_to?(accessor)
        end.flatten
        items.uniq.compact.detect(&:can_publish?).present?
      end

      def can_publish?(user = User.current_user)
        (Ability.new(user).can? :publish, self) || (can_manage?(user) && state_allows_publish?(user))
      end

      def state_allows_publish?(user = User.current_user)
        if self.new_record?
          return true unless self.gatekeeper_required?
          !self.is_waiting_approval?(user) && !self.is_rejected?
        else
          return false if self.is_published?
          return true unless self.gatekeeper_required?
          !self.is_waiting_approval?(user) && !self.is_rejected?
        end
      end

      def publish!(comment = nil, force = false)
        if force || can_publish?
          if gatekeeper_required? && !User.current_user.person.is_asset_gatekeeper_of?(self)
            false
          else
            policy.access_type = Policy::ACCESSIBLE
            policy.save
            # FIXME: may need to add comment
            resource_publish_logs.create(publish_state: ResourcePublishLog::PUBLISHED,
                                         user: User.current_user,
                                         comment: comment)
            touch
          end
        else
          false
        end
      end

      def reject(comment)
        resource_publish_logs.create(publish_state: ResourcePublishLog::REJECTED,
                                     user: User.current_user,
                                     comment: comment)
      end

      def is_published?
        policy = self.policy
        if self.is_downloadable?
          policy.public? && policy.access_type >= Policy::ACCESSIBLE
        else
          policy.public?
        end
      end

      def is_rejected?(time = ResourcePublishLog::CONSIDERING_TIME.ago)
        !ResourcePublishLog.where(['resource_type=? AND resource_id=? AND publish_state=? AND created_at >?',
                                   self.class.name, id, ResourcePublishLog::REJECTED, time]).empty?
      end

      def is_waiting_approval?(user = nil, time = ResourcePublishLog::CONSIDERING_TIME.ago)
        if user
          !ResourcePublishLog.where(['resource_type=? AND resource_id=? AND user_id=? AND publish_state=? AND created_at >?',
                                     self.class.name, id, user.id, ResourcePublishLog::WAITING_FOR_APPROVAL, time]).empty?
        else
          !ResourcePublishLog.where(['resource_type=? AND resource_id=? AND publish_state=? AND created_at >?',
                                     self.class.name, id, ResourcePublishLog::WAITING_FOR_APPROVAL, time]).empty?
        end
      end

      def gatekeeper_required?
        !asset_gatekeepers.empty?
      end

      def asset_gatekeepers
        projects.collect(&:asset_gatekeepers).flatten.uniq
      end

      def publish_requesters
        user_requesters = ResourcePublishLog.where(['resource_type=? AND resource_id=? AND publish_state=?',
                                                    self.class.name, id, ResourcePublishLog::WAITING_FOR_APPROVAL]).collect(&:user)

        person_requesters = user_requesters.compact.collect(&:person)
        person_requesters.compact.uniq
      end

      # the asset that can be published together with publishing the whole ISA
      def is_in_isa_publishable?
        # currently based upon the naive assumption that downloadable items are publishable, which is currently the case but may change.
        is_downloadable?
      end

      # the last ResourcePublishingLog made
      def last_publishing_log
        ResourcePublishLog.where('resource_type=? and resource_id=?', self.class.name, id).last
      end

      # while item is waiting for publishing approval,set the policy of the item to:
      # new item: projects_policy
      # updated item: keep the policy as before
      def temporary_policy_while_waiting_for_publishing_approval
        return true unless authorization_checks_enabled
        if policy.public? && !self.is_a?(Publication) && self.gatekeeper_required? && !User.current_user.person.is_asset_gatekeeper_of?(self)
          if self.new_record?
            self.policy = Policy.projects_policy(projects)
          else
            self.policy = Policy.find_by_id(policy.id)
          end
        end
      end
    end
  end
end
