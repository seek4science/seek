module Seek
  module Roles
    module Accessors
      extend ActiveSupport::Concern

      class_methods do
        def admins
          with_role(:admin)
        end

        def pals
          with_role(:pal)
        end

        def project_administrators
          with_role(:project_administrator)
        end

        def asset_gatekeepers
          with_role(:asset_gatekeeper)
        end

        def asset_housekeepers
          with_role(:asset_housekeeper)
        end

        def programme_administrators
          with_role(:programme_administrator)
        end
      end

      def is_admin?
        has_role?(:admin)
      end

      def is_admin=(flag_and_items)
        assign_or_remove_roles(:admin, flag_and_items)
      end

      def is_admin_or_project_administrator?
        is_admin? || is_project_administrator_of_any_project?
      end

      def is_pal_of_any_project?
        has_role?(:pal)
      end

      def is_project_administrator_of_any_project?
        has_role?(:project_administrator)
      end

      def is_asset_housekeeper_of_any_project?
        has_role?(:asset_housekeeper)
      end

      def is_asset_gatekeeper_of_any_project?
        has_role?(:asset_gatekeeper)
      end

      def is_pal?(project)
        check_for_role :pal, project
      end

      def is_project_administrator?(project)
        check_for_role :project_administrator, project
      end

      def is_asset_housekeeper?(project)
        check_for_role :asset_housekeeper, project
      end

      def is_asset_gatekeeper?(project)
        check_for_role :asset_gatekeeper, project
      end

      def is_pal_of?(asset)
        asset.projects.any? { |project| check_for_role(:pal, project) }
      end

      def is_project_administrator_of?(asset)
        asset.projects.any? { |project| check_for_role(:project_administrator, project) }
      end

      def is_asset_housekeeper_of?(asset)
        asset.projects.any? { |project| check_for_role(:asset_housekeeper, project) }
      end

      def is_asset_gatekeeper_of?(asset)
        asset.projects.any? { |project| check_for_role(:asset_gatekeeper, project) }
      end

      def is_pal=(flag_and_items)
        assign_or_remove_roles(:pal, flag_and_items)
      end

      def is_project_administrator=(flag_and_items)
        assign_or_remove_roles(:project_administrator, flag_and_items)
      end

      def is_asset_housekeeper=(flag_and_items)
        assign_or_remove_roles(:asset_housekeeper, flag_and_items)
      end

      def is_asset_gatekeeper=(flag_and_items)
        assign_or_remove_roles(:asset_gatekeeper, flag_and_items)
      end

      def projects_for_role(role)
        role_type = RoleType.find_by_key!(role)
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
        (person.projects_for_role(:project_administrator) & projects).any?
      end

      def is_in_any_gatekept_projects?
        projects.any? { |p| p.asset_gatekeepers.any? }
      end

      def is_programme_administrator_of_any_programme?
        has_role?(:programme_administrator)
      end

      def is_programme_administrator?(programme)
        check_for_role(:programme_administrator, programme)
      end

      def is_programme_administrator=(flag_and_items)
        assign_or_remove_roles(:programme_administrator, flag_and_items)
      end

      def programmes_for_role(role)
        role_type = RoleType.find_by_key!(role)
        Programme.joins(roles: :person).where(people: { id: self }, roles: { role_type_id: role_type })
      end

      def administered_programmes
        if is_admin?
          Programme.all
        else
          programmes_for_role(:programme_administrator)
        end
      end
    end
  end
end
