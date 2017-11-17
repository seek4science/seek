module Seek
  module Permissions
    # Handles detecting items with a policy sharing_scope ALL_USERS, and changing the permissions so that
    # the sharing scope is removed, but is shared with with same access type with associated projects. This is to remove
    # the legacy policy, and is part of an upgrade described by: https://jira-bsse.ethz.ch/browse/OPSK-1494
    class AllUsersSharingScopeResolver
      attr_reader :auditor

      def initialize
        @auditor = Auditor.new
      end

      def resolve(authorized_item)
        scope = authorized_item.policy.sharing_scope
        return authorized_item unless scope

        # always set it to nil
        authorized_item.policy.sharing_scope = nil
        if scope == Policy::ALL_USERS
          build_policies_for_projects(authorized_item.policy, authorized_item.projects)
          authorized_item.policy.access_type = Policy::PRIVATE
        end
        authorized_item
      end

      # Removes old Project default policies, that had a sharing scope of ALL USERS. This a legacy from the old SysMO
      # JERM harvesting
      def remove_legacy_default_policies
        policies_to_go = Project.all.collect(&:default_policy).compact.select { |policy| policy.sharing_scope == Policy::ALL_USERS }

        # shouldn't be a case where these policies are used, but just in case set use_default_policy to false
        associated_projects = policies_to_go.collect(&:associated_items).flatten.uniq.compact.select { |item| item.is_a?(Project) }
        associated_projects.select!(&:use_default_policy)
        associated_projects.each do |project|
          disable_authorization_checks do
            project.update_attribute(:use_default_policy, false)
          end
        end

        policies_to_go.each(&:destroy)
      end

      private

      def build_policies_for_projects(policy, projects)
        access_type = policy.access_type
        projects.each do |project|
          project_permissions = filter_permissions_for_project(policy.permissions, project)
          if project_permissions.any?
            resolve_project_permissions(project_permissions, access_type)
          else
            policy.permissions.build(contributor: project, access_type: access_type)
          end
        end
      end

      def filter_permissions_for_project(permissions, project)
        permissions.select { |permission| permission.contributor == project }
      end

      def resolve_project_permissions(permissions, access_type)
        permissions.each do |permission|
          permission.access_type = access_type if permission.access_type < access_type
        end
      end

      class Auditor
        def audit(item); end

        def changed_for_audit?(item)
          return true if item.policy.changes.include?(:access_type)
          return true if item.policy.permissions.detect(&:changed?)
          return true if item.policy.permissions.detect(&:new_record?)
          false
        end
      end
    end # class
  end
end
