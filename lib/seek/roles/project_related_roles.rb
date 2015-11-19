module Seek
  module Roles
    class ProjectRelatedRoles < RelatedRoles
      def self.role_names
        %w(pal project_administrator asset_manager gatekeeper)
      end

      def projects_for_person_with_role(person, role)
        items_for_person_and_role(person, role)
      end

      def people_with_project_and_role(project, role)
        mask = mask_for_role(role)
        AdminDefinedRoleProject.where(role_mask: mask, project_id: project.id).collect(&:person)
      end

      # Methods specific to ProjectRelatedResources required by RelatedResources superclass
      def related_item_class
        Project
      end

      def related_item_join_class
        AdminDefinedRoleProject
      end

      def related_items_association(person)
        person.admin_defined_role_projects
      end

      def filter_allowed_related_item_ids(item_ids, person)
        item_ids & person.projects.collect(&:id)
      end

      ####################################################################

      module PersonClassMethods
        def pals
          Seek::Roles::Roles.instance.people_with_role('pal')
        end

        def project_administrators
          Seek::Roles::Roles.instance.people_with_role('project_administrator')
        end

        def gatekeepers
          Seek::Roles::Roles.instance.people_with_role('gatekeeper')
        end

        def asset_managers
          Seek::Roles::Roles.instance.people_with_role('asset_manager')
        end
      end

      # Project related instance methods that will be injected into the Person model
      module PersonInstanceMethods
        extend ActiveSupport::Concern

        included do
          Seek::Roles::ProjectRelatedRoles.role_names.each do |role|
            class_eval <<-END_EVAL
            def is_#{role}_of_any_project?
              has_role?('#{role}')
            end

            def is_#{role}_of?(asset)
              match = asset.projects.find do |project|
                is_#{role}?(project)
              end
              !match.nil?
            end

            END_EVAL
          end

          has_many(:admin_defined_role_projects, dependent: :destroy)
          after_save(:resolve_admin_defined_role_projects)
        end

        def is_pal?(project)
          has_role?('pal') && check_role_for_item('pal', project)
        end

        def is_project_administrator?(project)
          has_role?('project_administrator') && check_role_for_item('project_administrator', project)
        end

        def is_asset_manager?(project)
          has_role?('asset_manager') && check_role_for_item('asset_manager', project)
        end

        def is_gatekeeper?(project)
          has_role?('gatekeeper') && check_role_for_item('gatekeeper', project)
        end

        def is_pal=(flag_and_items)
          assign_or_remove_roles('pal', flag_and_items)
        end

        def is_project_administrator=(flag_and_items)
          assign_or_remove_roles('project_administrator', flag_and_items)
        end

        def is_asset_manager=(flag_and_items)
          assign_or_remove_roles('asset_manager', flag_and_items)
        end

        def is_gatekeeper=(flag_and_items)
          assign_or_remove_roles('gatekeeper', flag_and_items)
        end

        def projects_for_role(role)
          fail UnknownRoleException.new("Unrecognised project role name #{role}") unless Seek::Roles::ProjectRelatedRoles.role_names.include?(role)
          Seek::Roles::ProjectRelatedRoles.instance.projects_for_person_with_role(self, role)
        end

        def roles_for_project(project)
          Seek::Roles::ProjectRelatedRoles.instance.roles_for_person_and_item(self, project)
        end

        # determines if this person is the member of a project for which the user passed is a project manager,
        # #and the current person is not an admin
        def is_project_administered_by?(user_or_person)
          return false if self.is_admin?
          return false if user_or_person.nil?
          person = user_or_person.person
          match = projects.find do |p|
            person.is_project_administrator?(p)
          end
          !match.nil?
        end

        def is_in_any_gatekept_projects?
          !projects.collect(&:gatekeepers).flatten.empty?
        end

        # called as callback after save, to make sure the role project records are aligned with the current projects, deleting
        # any for projects that have been removed, and resolving the mask
        def resolve_admin_defined_role_projects
          projects =  Seek::Config.project_hierarchy_enabled ? projects_and_descendants : self.projects

          admin_defined_role_projects.each do |role|
            role.destroy unless projects.include?(role.project)
          end
          new_mask = roles_mask
          roles_to_check = roles & ProjectRelatedRoles.role_names
          roles_to_check.collect { |name| Seek::Roles::Roles.instance.mask_for_role(name) }.each do |mask|
            if AdminDefinedRoleProject.where(role_mask: mask, person_id: id).empty?
              new_mask -= mask
            end
          end
          update_column :roles_mask, new_mask
        end
      end
    end
  end
end
