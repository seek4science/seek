module Seek
  module Subscriptions
    # handles project subscriptions for a person.
    module PersonProjectSubscriptions
      extend ActiveSupport::Concern

      included do
        # TODO: Replace this. I don't think it is very well supported. Can't find any docs...
        after_add_for_group_memberships << proc { |c, person, gm| person.subscribe_to_project_subscription(gm) }
        after_add_for_group_memberships << proc { |c, person, gm| person.touch_project_for_membership(gm) }
        after_remove_for_group_memberships << proc { |c, person, gm| person.unsubscribe_from_project_subscription(gm) }
        after_remove_for_group_memberships << proc { |c, person, gm| person.touch_project_for_membership(gm) }

        after_add_for_work_groups << proc { |c, person, wg| person.subscribe_to_project_subscription(wg) }
        after_add_for_work_groups << proc { |c, person, wg| person.touch_project_for_membership(wg) }
        after_remove_for_work_groups << proc { |c, person, wg| person.unsubscribe_from_project_subscription(wg) }
        after_remove_for_work_groups << proc { |c, person, wg| person.touch_project_for_membership(wg) }

        has_many :project_subscriptions, before_add: proc { |person, ps| ps.person = person }, dependent: :destroy
        has_many :subscribed_projects, through: :project_subscriptions, class_name: 'Project', source: :project
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
        else
          if workgroup_or_membership.is_a?(WorkGroup)
            pid = workgroup_or_membership.project_id_before_last_save
          else
            pid = workgroup_or_membership.work_group.try(:project_id_before_last_save)
          end

          if pid && (ps = project_subscriptions.find { |ps| ps.project_id == pid })
            # unsunscribe direct project subscriptions
            project_subscriptions.delete ps
          end
        end
      end

      def touch_project_for_membership(workgroup_or_membership)
        project = workgroup_or_membership.project
        project.try(:touch)
      end
    end
  end
end
