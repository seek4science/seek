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
        return false if is_published?
        return true unless gatekeeper_required?
        return true if user.person.is_asset_gatekeeper_of?(self)
        return false if is_waiting_approval?
        return true unless is_rejected?
        return is_updated_since_be_rejected?
      end

      def publish!(comment = nil, force = false)
        if force || can_publish?
          if gatekeeper_required? && !User.current_user.person.is_asset_gatekeeper_of?(self)
            false
          else
            policy.access_type = Policy::ACCESSIBLE
            policy.sharing_scope = Policy::EVERYONE # anything but ALL_USERS
            policy.save

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

      def is_rejected?
        resource_publish_logs.where(publish_state: ResourcePublishLog::REJECTED).any? && resource_publish_logs.last.publish_state == ResourcePublishLog::REJECTED
      end

      def is_waiting_approval?(user = nil)
        resource_publish_logs.where(publish_state: ResourcePublishLog::WAITING_FOR_APPROVAL).any? && resource_publish_logs.last.publish_state == ResourcePublishLog::WAITING_FOR_APPROVAL
      end

      def is_updated_since_be_rejected?
        is_rejected? && resource_publish_logs.where(publish_state: ResourcePublishLog::REJECTED).where('created_at > ?', updated_at).none?
      end

      def gatekeeper_required?
        !asset_gatekeepers.empty?
      end

      def asset_gatekeeper_can_publish?
        is_waiting_approval?(nil)
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
        return true if User.current_user.blank?
        if is_published? && !is_a?(Publication) && gatekeeper_required? && !User.current_user.person.is_asset_gatekeeper_of?(self)
          policy.access_type = if new_record?
                                 Policy::NO_ACCESS
                               else
                                 Policy.find_by_id(policy.id).access_type
                               end
        end
      end
    end
  end
end
