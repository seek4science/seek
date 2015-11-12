module Seek
  module Roles
    module AdminDefinedRoles
      extend ActiveSupport::Concern

      included do
        fail 'Only People can have roles' unless self == Person
        requires_can_manage :roles_mask

        Seek::Roles::Roles.define_methods(self)
      end

      def roles
        Seek::Roles::Roles.instance.role_names_for_mask(roles_mask)
      end

      def has_role?(role_name)
        roles_mask != 0 && (roles_mask & Seek::Roles::Roles.instance.mask_for_role(role_name) != 0)
      end

      def add_roles(role_infos)
        add_or_remove_roles(role_infos, :add)
      end

      def remove_roles(role_infos)
        add_or_remove_roles(role_infos, :remove)
      end

      def add_or_remove_roles(role_infos, type)
        role_infos = Array(role_infos)
        method = type == :add ? :add_roles : :remove_roles
        role_infos.each do |role_info|
          Seek::Roles::Roles.instance.send(method, self, role_info.role_name, role_info.items)
        end
      end

      def is_admin_or_project_administrator?
        is_admin? || is_project_administrator_of_any_project?
      end

      include Seek::ProjectHierarchies::AdminDefinedRolesExtension if Seek::Config.project_hierarchy_enabled
    end
  end
end
