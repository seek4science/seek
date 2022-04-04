module Seek
  module Roles
    PAL = 'pal'
    PROJECT_ADMINISTRATOR = 'project_administrator'
    ASSET_HOUSEKEEPER = 'asset_housekeeper'
    ASSET_GATEKEEPER = 'asset_gatekeeper'
    class ProjectRelatedRoles < RelatedRoles
      def self.role_names
        [Seek::Roles::PAL, Seek::Roles::PROJECT_ADMINISTRATOR, Seek::Roles::ASSET_HOUSEKEEPER, Seek::Roles::ASSET_GATEKEEPER]
      end

      def projects_for_person_with_role(person, role)
        items_for_person_and_role(person, role)
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
        item_ids & person.work_groups.collect(&:project_id)
      end

      ####################################################################

      module PersonClassMethods
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
      end

      # Project related instance methods that will be injected into the Person model
      module PersonInstanceMethods
        extend ActiveSupport::Concern

        included do
          has_many(:admin_defined_role_projects, dependent: :destroy)
          after_save(:resolve_admin_defined_role_projects)
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
          Project.joins(roles: [:person, :role_type]).where(people: { id: self.id },
                                                            roles: { role_type_id: role_type.id })
        end

        def roles_for_project(project)
          scoped_roles(project)
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
          !projects.collect(&:asset_gatekeepers).flatten.empty?
        end

        # called as callback after save, to make sure the role project records are aligned with the current projects, deleting
        # any for projects that have been removed, and resolving the mask
        def resolve_admin_defined_role_projects
          projects = group_memberships.collect(&:project)
          roles.where(scope_type: 'Project').where.not(scope_id: projects).destroy_all
        end

        def roles_for_projects
          roles.includes(:role_type).where(scope_type: 'Project').group_by { |r| r.role_type.key }.transform_values do |v|
            v.map(&:scope)
          end
        end
      end
    end
  end
end
