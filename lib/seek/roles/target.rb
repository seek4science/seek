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
          role_type = RoleType.find_by_key!(key)
          joins(:roles).where(roles: { role_type_id: role_type.id }).distinct
        end
      end

      def role_names
        roles.select(:role_type_id).distinct.map(&:key)
      end

      def scoped_roles(scope)
        roles.where(scope_id: scope&.id, scope_type: scope&.class&.name)
      end

      def has_role?(key)
        role_type = RoleType.find_by_key!(key)
        roles.where(role_type_id: role_type.id).any?
      end

      def check_for_role(key, scope)
        scoped_roles(scope).with_role_key(key).exists?
      end

      def assign_or_remove_roles(key, flag_and_items)
        flag_and_items = Array(flag_and_items)
        flag = flag_and_items[0]
        items = flag_and_items[1]
        if flag
          add_role(key, items: items)
        else
          remove_role(key, items: items)
        end
      end

      def assign_role(key, scope = nil)
        return if check_for_role(key, scope)
        role = scoped_roles(scope).with_role_key(key).build
        role
      end

      def unassign_role(key, scope = nil)
        scoped_roles(scope).with_role_key(key).destroy_all
      end

      def add_role(key, items: nil)
        # Can't use Array(items) here because it turns `nil` into `[]` instead of `[nil]`
        items = [items] unless items.respond_to?(:each)
        items.map { |item| assign_role(key, item)&.save }
      end

      def remove_role(key, items: nil)
        items = [items] unless items.respond_to?(:each)
        items.map { |item| unassign_role(key, item) }
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
