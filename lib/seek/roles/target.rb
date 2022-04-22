module Seek
  module Roles
    module Target
      extend ActiveSupport::Concern

      included do
        has_many :roles, dependent: :destroy, inverse_of: :person
        after_save :remove_dangling_project_roles

        include Seek::Roles::Accessors
      end

      class_methods do
        def with_role(key)
          joins(:roles).where(roles: { role_type_id: RoleType.find_by_key!(key) }).distinct
        end
      end

      def role_names
        roles.select(:role_type_id).distinct.map(&:key)
      end

      # Scope can be a single object or array/collection of objects (of the same type).
      # Can also be nil to fetch system roles.
      def scoped_roles(scope)
        scope_type = nil
        scope_type = scope.model_name.to_str if scope.respond_to?(:model_name)
        scope_type = scope.first.model_name.to_str if scope.respond_to?(:first) && scope.first.respond_to?(:model_name)
        roles.where(scope_id: scope, scope_type: scope_type)
      end

      def has_role?(key)
        roles.with_role_key(key).any?
      end

      def has_role_in?(key, scope)
        # This is to allow unsaved records (and thus unsaved roles) to be picked up
        # otherwise permission errors can occur when creating a resource + associated roles at the same time
        if scope && scope.is_a?(ApplicationRecord)
          return scope.send(key.to_s.pluralize).include?(self)
        end
        scoped_roles(scope).with_role_key(key).any?
      end

      def assign_or_remove_roles(key, flag_and_items)
        flag_and_items = Array(flag_and_items)
        flag = flag_and_items[0]
        items = flag_and_items[1]
        if flag
          assign_role(key, items)
        else
          unassign_role(key, items)
        end
      end

      def assign_role(key, scopes = nil)
        # Can't use Array(items) here because it turns `nil` into `[]` instead of `[nil]`
        scopes = [scopes] unless scopes.respond_to?(:each)
        scopes.map do |scope|
          next if has_role_in?(key, scope)
          scoped_roles(scope).with_role_key(key).build&.save
        end
      end

      def unassign_role(key, scopes = nil)
        scoped_roles(scopes).with_role_key(key).destroy_all
      end

      # called as callback after save, to make sure the role project records are aligned with the current projects, deleting
      # any for projects that have been removed
      def remove_dangling_project_roles
        roles.where(scope_type: 'Project').where.not(scope_id: current_project_ids).each do |role|
          unassign_role(role.key, role.scope)
        end
      end
    end
  end
end
