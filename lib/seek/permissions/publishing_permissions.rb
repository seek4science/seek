module Seek
  module Permissions
    module PublishingPermissions
      def self.included(klass)
        klass.class_eval do
          before_validation :temporary_policy_while_waiting_for_publishing_approval
          has_many :resource_publish_logs, as: :resource

          def self.publishing_embargo_period
            5.years # TODO: Make this configurable
          end
        end
      end

      def contains_publishable_items?
        items = %i[studies study assays investigation assets].collect do |accessor|
          send(accessor) if respond_to?(accessor)
        end.flatten
        items.uniq.compact.detect(&:can_publish?).present?
      end

      def can_publish?(user = User.current_user)
        authorized_for_action(user, 'publish') && state_allows_publish?(user)
      end

      def state_allows_publish?(user = User.current_user)
        if new_record?
          return true unless gatekeeper_required?
          !is_waiting_approval?(user) && !is_rejected?
        else
          return false if is_published?
          return true unless gatekeeper_required?
          !is_waiting_approval?(user) && !is_rejected?
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
        if is_downloadable?
          policy.public? && policy.access_type >= Policy::ACCESSIBLE
        else
          policy.public?
        end
      end

      def is_rejected?(time = ResourcePublishLog::CONSIDERING_TIME.ago)
        resource_publish_logs.where(publish_state: ResourcePublishLog::REJECTED).where('created_at > ?', time).any?
      end

      def is_waiting_approval?(user = nil, time = ResourcePublishLog::CONSIDERING_TIME.ago)
        if user
          resource_publish_logs.where(publish_state: ResourcePublishLog::WAITING_FOR_APPROVAL, user_id: user.id).where('created_at > ?', time).any?
        else
          resource_publish_logs.where(publish_state: ResourcePublishLog::WAITING_FOR_APPROVAL).where('created_at > ?', time).any?
        end
      end

      def gatekeeper_required?
        !asset_gatekeepers.empty?
      end

      def asset_gatekeeper_can_publish?
        is_waiting_approval?(nil, self.class.publishing_embargo_period.ago)
      end

      def asset_gatekeepers
        projects.collect(&:asset_gatekeepers).flatten.uniq
      end

      def publish_requesters
        user_requesters = resource_publish_logs.includes(:user).where(publish_state: ResourcePublishLog::WAITING_FOR_APPROVAL).map(&:user)

        user_requesters.uniq.compact.collect(&:person).compact
      end

      # the asset that can be published together with publishing the whole ISA
      def is_in_isa_publishable?
        # currently based upon the naive assumption that downloadable items are publishable, which is currently the case but may change.
        is_downloadable?
      end

      # the last ResourcePublishingLog made
      def last_publishing_log
        resource_publish_logs.last
      end

      # while item is waiting for publishing approval,set the policy of the item to:
      # new item: projects_policy
      # updated item: keep the policy as before
      def temporary_policy_while_waiting_for_publishing_approval
        return true unless authorization_checks_enabled
        if policy.public? && !is_a?(Publication) && gatekeeper_required? && !User.current_user.person.is_asset_gatekeeper_of?(self)
          self.policy = if new_record?
                          Policy.projects_policy(projects)
                        else
                          Policy.find_by_id(policy.id)
                        end
        end
      end
    end
  end
end
