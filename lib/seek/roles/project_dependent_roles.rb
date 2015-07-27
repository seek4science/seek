module Seek
  module Roles
    class ProjectDependentRoles < DependentRoles
      def self.role_names
        %w(pal project_administrator asset_manager gatekeeper)
      end

      def self.define_extra_methods(base)
        role_names.each do |role|
          base.class_eval <<-END_EVAL
            def is_#{role}_of_any_project?
              is_#{role}?(nil,true)
            end

            def is_#{role}_of?(asset)
              match = asset.projects.find do |project|
                is_#{role}?(project)
              end
              !match.nil?
            end

          END_EVAL
        end
      end

      def add_roles(person, role_name, items)
        return if items.empty?
        project_ids = items.collect { |p| p.is_a?(Project) ? p.id : p.to_i }

        # filter out any projects that the person is not a member of
        project_ids &= person.projects.collect(&:id)
        mask = mask_for_role(role_name)

        current_projects_ids = person.admin_defined_role_projects.where(role_mask: mask).collect { |r| r.project.id }

        (project_ids - current_projects_ids).each do |project_id|
          person.admin_defined_role_projects << AdminDefinedRoleProject.new(project_id: project_id, role_mask: mask)
        end

        person.roles_mask += mask if (person.roles_mask & mask).zero?
      end

      def remove_roles(person, role_name, items)
        project_ids = items.collect { |p| p.is_a?(Project) ? p.id : p.to_i }
        mask = mask_for_role(role_name)

        current_projects_ids = person.admin_defined_role_projects.where(role_mask: mask).collect { |r| r.project.id }
        project_ids.each do |project_id|
          AdminDefinedRoleProject.where(project_id: project_id, role_mask: mask, person_id: person.id).destroy_all
        end
        person.roles_mask -= mask if (current_projects_ids - project_ids).empty?
      end

      def projects_for_person_with_role(person, role)
        if person.roles.include?(role)
          mask = mask_for_role(role)
          AdminDefinedRoleProject.where(role_mask: mask, person_id: person.id).collect(&:project)
        else
          []
        end
      end

      def people_with_project_and_role(project, role)
        mask = mask_for_role(role)
        AdminDefinedRoleProject.where(role_mask: mask, project_id: project.id).collect(&:person)
      end

      def associated_item_class
        Project
      end
    end
  end
end
