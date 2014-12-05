module Seek
  module Subscriptions
    # handles project subscriptions for a person.
    module PersonProjectSubscriptions
      extend ActiveSupport::Concern

      included do
        after_add_for_group_memberships << :subscribe_to_project_subscription
        after_add_for_group_memberships << :touch_project_for_membership
        after_remove_for_group_memberships << :unsubscribe_from_project_subscription
        after_remove_for_group_memberships << :touch_project_for_membership

        after_add_for_work_groups << :subscribe_to_project_subscription
        after_add_for_work_groups << :touch_project_for_membership
        after_remove_for_work_groups << :unsubscribe_from_project_subscription
        after_remove_for_work_groups << :touch_project_for_membership

        has_many :project_subscriptions, before_add: proc { |person, ps| ps.person = person }, uniq: true, dependent: :destroy
        accepts_nested_attributes_for :project_subscriptions, allow_destroy: true

        has_many :subscriptions, dependent: :destroy
      end

      def subscribe_to_project_subscription(workgroup_or_membership)
        project = workgroup_or_membership.project
        if project
          project_subscriptions.build project: project unless project_subscriptions.find { |ps| ps.project_id == project.id }
        end
      end

      def unsubscribe_from_project_subscription(workgroup_or_membership)
        if work_groups.empty?
          project_subscriptions.delete_all
          subscriptions.delete_all
        elsif ps = project_subscriptions.find { |ps| ps.project_id == workgroup_or_membership.project.id }
          # unsunscribe direct project subscriptions
          project_subscriptions.delete ps
        end
      end

      def touch_project_for_membership(workgroup_or_membership)
        project = workgroup_or_membership.project
        project.try(:touch)
      end
    end
  end
end
