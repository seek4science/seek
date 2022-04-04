module Seek
  module Roles
    ADMIN = 'admin'
    PAL = 'pal'
    PROJECT_ADMINISTRATOR = 'project_administrator'
    ASSET_HOUSEKEEPER = 'asset_housekeeper'
    ASSET_GATEKEEPER = 'asset_gatekeeper'
    PROGRAMME_ADMINISTRATOR = 'programme_administrator'
    class UnknownRoleException < Exception; end
    module Refactor
      extend ActiveSupport::Concern

      included do
        has_many :roles, dependent: :destroy
        after_save :remove_dangling_project_roles
        after_commit :clear_role_cache
        enforce_required_access_for_owner :roles, :manage

        include Seek::Roles::Accessors
      end

      class_methods do
        def with_role(key)
          role_type = RoleType.find_by_key(key)
          joins(:roles).where(roles: { role_type_id: role_type.id }).distinct
        end
      end

      def role_names
        roles.map(&:key).uniq
      end

      def scoped_roles(scope)
        roles.where(scope_id: scope&.id, scope_type: scope&.class&.name)
      end

      def has_role?(key)
        role_type = RoleType.find_by_key(key)
        has_cached_role?(key, :any) || roles.where(role_type_id: role_type.id).any?
      end

      def check_for_role(key, scope)
        has_cached_role?(key, scope) || scoped_roles(scope).with_role_key(key).exists?
      end

      def is_admin_or_project_administrator?
        is_admin? || is_project_administrator_of_any_project?
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
        cache_role(key, scope) if role.valid?
        role
      end

      def unassign_role(key, scope = nil)
        scoped_roles(scope).with_role_key(key).destroy_all
        uncache_role(key, scope)
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
      # any for projects that have been removed, and resolving the mask
      def remove_dangling_project_roles
        projects = current_group_memberships.collect(&:project)
        roles.where(scope_type: 'Project').where.not(scope_id: projects).destroy_all
      end

      private

      def role_cache
        @_role_cache ||= { any: {} }
      end

      def cache_role(key, scope)
        role_cache[scope] ||= Set.new
        role_cache[scope].add(key)
        role_cache[:any][key] = (role_cache[:any][key] || 0) + 1
      end

      def uncache_role(key, scope)
        role_cache[scope].delete(key) if role_cache[scope]
        if role_cache[:any][key]
          role_cache[:any][key] -= 1
          role_cache[:any].delete(key) if role_cache[:any][key]
        end
      end

      def has_cached_role?(key, scope)
        role_cache[scope] && role_cache[scope].include?(key)
      end

      def clear_role_cache
        @_role_cache = nil
      end
    end
  end
end