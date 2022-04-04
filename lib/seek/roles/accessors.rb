module Seek
  module Roles
    module Accessors
      extend ActiveSupport::Concern

      class_methods do
        def admins
          with_role(Seek::Roles::ADMIN)
        end

        def pals
          with_role(Seek::Roles::PAL)
        end

        def project_administrators
          with_role(Seek::Roles::PROJECT_ADMINISTRATOR)
        end

        def asset_gatekeepers
          with_role(Seek::Roles::ASSET_GATEKEEPER)
        end

        def asset_housekeepers
          with_role(Seek::Roles::ASSET_HOUSEKEEPER)
        end

        def programme_administrators
          with_role(Seek::Roles::PROGRAMME_ADMINISTRATOR)
        end
      end

      def is_admin?
        has_role?(Seek::Roles::ADMIN)
      end

      def is_admin=(flag_and_items)
        assign_or_remove_roles(Seek::Roles::ADMIN, flag_and_items)
      end

      def is_admin_or_project_administrator?
        is_admin? || is_project_administrator_of_any_project?
      end

      def is_pal_of_any_project?
        has_role?(Seek::Roles::PAL)
      end

      def is_project_administrator_of_any_project?
        has_role?(Seek::Roles::PROJECT_ADMINISTRATOR)
      end

      def is_asset_housekeeper_of_any_project?
        has_role?(Seek::Roles::ASSET_HOUSEKEEPER)
      end

      def is_asset_gatekeeper_of_any_project?
        has_role?(Seek::Roles::ASSET_GATEKEEPER)
      end

      def is_pal?(project)
        check_for_role Seek::Roles::PAL, project
      end

      def is_project_administrator?(project)
        check_for_role Seek::Roles::PROJECT_ADMINISTRATOR, project
      end

      def is_asset_housekeeper?(project)
        check_for_role Seek::Roles::ASSET_HOUSEKEEPER, project
      end

      def is_asset_gatekeeper?(project)
        check_for_role Seek::Roles::ASSET_GATEKEEPER, project
      end

      def is_pal_of?(asset)
        asset.projects.any? { |project| check_for_role(Seek::Roles::PAL, project) }
      end

      def is_project_administrator_of?(asset)
        asset.projects.any? { |project| check_for_role(Seek::Roles::PROJECT_ADMINISTRATOR, project) }
      end

      def is_asset_housekeeper_of?(asset)
        asset.projects.any? { |project| check_for_role(Seek::Roles::ASSET_HOUSEKEEPER, project) }
      end

      def is_asset_gatekeeper_of?(asset)
        asset.projects.any? { |project| check_for_role(Seek::Roles::ASSET_GATEKEEPER, project) }
      end

      def is_pal=(flag_and_items)
        assign_or_remove_roles(Seek::Roles::PAL, flag_and_items)
      end

      def is_project_administrator=(flag_and_items)
        assign_or_remove_roles(Seek::Roles::PROJECT_ADMINISTRATOR, flag_and_items)
      end

      def is_asset_housekeeper=(flag_and_items)
        assign_or_remove_roles(Seek::Roles::ASSET_HOUSEKEEPER, flag_and_items)
      end

      def is_asset_gatekeeper=(flag_and_items)
        assign_or_remove_roles(Seek::Roles::ASSET_GATEKEEPER, flag_and_items)
      end

      def projects_for_role(role)
        role_type = RoleType.find_by_key(role)
        fail UnknownRoleException.new("Unrecognised project role name #{role}") unless role_type
        Project.joins(roles: :person).where(people: { id: self.id },
                                                      roles: { role_type_id: role_type.id })
      end

      def roles_for_project(project)
        scoped_roles(project)
      end

      def roles_for_projects
        roles.where(scope_type: 'Project').group_by { |r| r.role_type.key }.transform_values do |v|
          v.map(&:scope)
        end
      end

      # determines if this person is the member of a project for which the user passed is a project manager,
      # #and the current person is not an admin
      def is_project_administered_by?(person)
        (person.projects_for_role(Seek::Roles::PROJECT_ADMINISTRATOR) & projects).any?
      end

      def is_in_any_gatekept_projects?
        projects.any? { |p| p.asset_gatekeepers.any? }
      end

      def is_programme_administrator_of_any_programme?
        has_role?(Seek::Roles::PROGRAMME_ADMINISTRATOR)
      end

      def is_programme_administrator?(programme)
        check_for_role(Seek::Roles::PROGRAMME_ADMINISTRATOR, programme)
      end

      def is_programme_administrator=(flag_and_items)
        assign_or_remove_roles(Seek::Roles::PROGRAMME_ADMINISTRATOR, flag_and_items)
      end

      def programmes_for_role(role)
        role_type = RoleType.find_by_key(role)
        fail UnknownRoleException.new("Unrecognised programme role name #{role}") unless role_type
        Programme.joins(roles: :person).where(people: { id: self }, roles: { role_type_id: role_type })
      end

      def administered_programmes
        if is_admin?
          Programme.all
        else
          programmes_for_role(Seek::Roles::PROGRAMME_ADMINISTRATOR)
        end
      end
    end
  end
end