module Seek
  module Roles
    module Accessors
      extend ActiveSupport::Concern

      class_methods do
        def admins; with_role(:admin); end
        def pals; with_role(:pal); end
        def project_administrators; with_role(:project_administrator); end
        def asset_gatekeepers; with_role(:asset_gatekeeper); end
        def asset_housekeepers; with_role(:asset_housekeeper); end
        def programme_administrators; with_role(:programme_administrator); end
      end

      # System roles
      def is_admin?; has_role?(:admin); end
      def is_admin=(args); assign_or_remove_roles(:admin, args); end

      # Project roles
      def is_pal_of_any_project?; has_role?(:pal); end
      def is_project_administrator_of_any_project?; has_role?(:project_administrator); end
      def is_asset_housekeeper_of_any_project?; has_role?(:asset_housekeeper); end
      def is_asset_gatekeeper_of_any_project?; has_role?(:asset_gatekeeper); end

      def is_pal?(project); has_role_in?(:pal, project); end
      def is_project_administrator?(project); has_role_in?(:project_administrator, project); end
      def is_asset_housekeeper?(project); has_role_in?(:asset_housekeeper, project); end
      def is_asset_gatekeeper?(project); has_role_in?(:asset_gatekeeper, project); end

      def is_pal_of?(asset); has_role_in?(:pal, asset.projects); end
      def is_project_administrator_of?(asset); has_role_in?(:project_administrator, asset.projects); end
      def is_asset_housekeeper_of?(asset); has_role_in?(:asset_housekeeper, asset.projects); end
      def is_asset_gatekeeper_of?(asset); has_role_in?(:asset_gatekeeper, asset.projects); end

      def is_pal=(args); assign_or_remove_roles(:pal, args); end
      def is_project_administrator=(args); assign_or_remove_roles(:project_administrator, args); end
      def is_asset_housekeeper=(args); assign_or_remove_roles(:asset_housekeeper, args); end
      def is_asset_gatekeeper=(args); assign_or_remove_roles(:asset_gatekeeper, args); end

      # Programme roles
      def is_programme_administrator_of_any_programme?; has_role?(:programme_administrator); end
      def is_programme_administrator?(programme); has_role_in?(:programme_administrator, programme); end
      def is_programme_administrator=(args); assign_or_remove_roles(:programme_administrator, args); end

      # Misc methods

      def projects_for_role(key)
        Project.joins(roles: :person).where(people: { id: self }, roles: { role_type_id: RoleType.find_by_key!(key) })
      end

      def programmes_for_role(key)
        Programme.joins(roles: :person).where(people: { id: self }, roles: { role_type_id: RoleType.find_by_key!(key) })
      end

      def role_scopes_by_type
        roles.order(:role_type_id).group_by { |r| r.role_type }.transform_values do |v|
          v.map(&:scope).compact
        end
      end

      def is_admin_or_project_administrator?
        is_admin? || is_project_administrator_of_any_project?
      end

      # determines if this person is the member of a project for which the user passed is a project manager,
      # #and the current person is not an admin
      def is_project_administered_by?(person)
        person.is_project_administrator?(projects)
      end

      def is_in_any_gatekept_projects?
        projects.joins(:roles).where(roles: { role_type_id: RoleType.find_by_key!(:asset_gatekeeper) }).any?
      end

      def administered_programmes
        is_admin? ? Programme.all : programmes_for_role(:programme_administrator)
      end
    end
  end
end
