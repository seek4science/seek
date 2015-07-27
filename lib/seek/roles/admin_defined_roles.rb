module Seek
  module Roles
    module AdminDefinedRoles
      extend ActiveSupport::Concern

      ROLES = Seek::Roles::Roles.role_names

      included do
        fail 'Only People can have roles' unless self == Person

        requires_can_manage :roles_mask
        has_many :admin_defined_role_projects, dependent: :destroy
        has_many :admin_defined_role_programmes, dependent: :destroy

        after_save :resolve_admin_defined_role_projects

        Roles.define_methods(self)
      end

      def roles=(roles)
        # TODO a bit heavy handed, but works for the moment
        self.roles_mask = 0
        admin_defined_role_projects.destroy_all

        add_roles(roles)
      end

      def projects_for_role(role)
        fail UnknownRoleException.new("Unrecognised role name #{role}") unless ROLES.include?(role)
        Seek::Roles::ProjectDependentRoles.instance.projects_for_person_with_role(self, role)
      end

      def programmes_for_role(role)
        fail UnknownRoleException.new("Unrecognised role name #{role}") unless ROLES.include?(role)
        Seek::Roles::ProgrammeDependentRoles.instance.programmes_for_person_with_role(self, role)
      end

      def roles_for_project(project)
        Seek::Roles::ProjectDependentRoles.instance.roles_for_person_and_item(self, project)
      end

      def roles
        Seek::Roles::Roles.instance.role_names_for_mask(roles_mask)
      end

      def add_roles(role_details)
        add_or_remove_roles(role_details,:add)
      end

      def remove_roles(role_details)
        add_or_remove_roles(role_details,:remove)
      end

      def add_or_remove_roles(role_details,type)
        method = type==:add ? :add_roles : :remove_roles
        role_details.each do |role_detail|
          rolename = role_detail[0]
          associated_items = Array(role_detail[1])
          Seek::Roles::Roles.instance.send(method,self, rolename, associated_items)
        end
      end

      # called as callback after save, to make sure the role project records are aligned with the current projects, deleting
      # any for projects that have been removed, and resolving the mask
      def resolve_admin_defined_role_projects
        projects =  Seek::Config.project_hierarchy_enabled ? projects_and_descendants : self.projects

        admin_defined_role_projects.each do |role|
          role.destroy unless projects.include?(role.project)
        end
        new_mask = roles_mask
        roles_to_check = roles & ProjectDependentRoles.role_names
        roles_to_check.collect { |name| Seek::Roles::Roles.instance.mask_for_role(name) }.each do |mask|
          if AdminDefinedRoleProject.where(role_mask: mask, person_id: id).empty?
            new_mask -= mask
          end
        end
        update_column :roles_mask, new_mask
      end

      def is_in_any_gatekept_projects?
        !projects.collect(&:gatekeepers).flatten.empty?
      end

      def is_admin_or_project_administrator?
        is_admin? || is_project_administrator_of_any_project?
      end

      #determines if this person is the member of a project for which the user passed is a project manager,
      # #and the current person is not an admin
      def is_project_administered_by? user_or_person
        return false if self.is_admin?
        return false if user_or_person.nil?
        person = user_or_person.person
        match = self.projects.find do |p|
          person.is_project_administrator?(p)
        end
        !match.nil?
      end


      include Seek::ProjectHierarchies::AdminDefinedRolesExtension if Seek::Config.project_hierarchy_enabled
    end
  end
end
