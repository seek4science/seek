module Seek
  module Roles
    module AdminDefinedRoles
      extend ActiveSupport::Concern

      included do
        fail 'Only People can have roles' unless self == Person
        requires_can_manage :roles_mask

        include StandAloneRoles::PersonInstanceMethods
        extend StandAloneRoles::PersonClassMethods

        include ProjectRelatedRoles::PersonInstanceMethods
        extend ProjectRelatedRoles::PersonClassMethods

        include ProgrammeRelatedRoles::PersonInstanceMethods
        extend ProgrammeRelatedRoles::PersonClassMethods
      end

      def roles
        Seek::Roles::Roles.instance.role_names_for_mask(roles_mask)
      end

      def has_role?(role_name)
        roles_mask != 0 && (roles_mask & Seek::Roles::Roles.instance.mask_for_role(role_name) != 0)
      end

      def assign_or_remove_roles(rolename, flag_and_items)
        flag_and_items = Array(flag_and_items)
        flag = flag_and_items[0]
        items = flag_and_items[1]
        if flag
          add_roles(Seek::Roles::RoleInfo.new(role_name: rolename, items: items))
        else
          remove_roles(Seek::Roles::RoleInfo.new(role_name: rolename, items: items))
        end
      end

      def add_roles(role_infos)
        self.roles_mask ||= 0
        Array(role_infos).each do |role_info|
          select_handler(role_info.role_name).instance.add_roles(self, role_info)
        end
      end

      def remove_roles(role_infos)
        Array(role_infos).each do |role_info|
          select_handler(role_info.role_name).instance.remove_roles(self, role_info)
        end
      end

      def select_handler(role_name)
        handler = Seek::Roles::Roles.descendants.detect do |subclass|
          subclass.role_names.include?(role_name)
        end
        fail Seek::Roles::UnknownRoleException.new("Unknown role '#{role_name.inspect}'") if handler.nil?
        handler
      end

      def check_role_for_item(role_name, item)
        select_handler(role_name).instance.check_role_for_item(self, role_name, item)
      end

      def is_admin_or_project_administrator?
        is_admin? || is_project_administrator_of_any_project?
      end

      include Seek::ProjectHierarchies::AdminDefinedRolesExtension if Seek::Config.project_hierarchy_enabled
    end
  end
end
