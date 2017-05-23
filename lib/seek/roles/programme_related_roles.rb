module Seek
  module Roles
    PROGRAMME_ADMINISTRATOR = 'programme_administrator'
    class ProgrammeRelatedRoles < RelatedRoles
      def self.role_names
        [Seek::Roles::PROGRAMME_ADMINISTRATOR]
      end

      def self.define_extra_methods(_base)
      end

      def programmes_for_person_with_role(person, role)
        items_for_person_and_role(person, role)
      end

      def people_with_programme_and_role(programme, role)
        mask = mask_for_role(role)
        AdminDefinedRoleProgramme.where(role_mask: mask, programme_id: programme.id).collect(&:person)
      end

      # Methods specific to ProgrammeRelatedResources required by RelatedResources superclass
      def related_item_class
        Programme
      end

      def related_item_join_class
        AdminDefinedRoleProgramme
      end

      def related_items_association(person)
        person.admin_defined_role_programmes
      end
      ###############################

      module PersonClassMethods
        def programme_administrators
          Seek::Roles::Roles.instance.people_with_role(Seek::Roles::PROGRAMME_ADMINISTRATOR)
        end
      end

      # Programme related instance methods that will be injected into the Person model
      module PersonInstanceMethods
        extend ActiveSupport::Concern

        included do
          Seek::Roles::ProgrammeRelatedRoles.role_names.each do |role|
            class_eval <<-END_EVAL
          def is_#{role}_of_any_programme?
            has_role?('#{role}')
          end

            END_EVAL
          end
          has_many(:admin_defined_role_programmes, dependent: :destroy)
        end

        def is_programme_administrator?(programme)
          check_for_role(Seek::Roles::PROGRAMME_ADMINISTRATOR, programme)
        end

        def is_programme_administrator=(flag_and_items)
          assign_or_remove_roles(Seek::Roles::PROGRAMME_ADMINISTRATOR, flag_and_items)
        end

        def programmes_for_role(role)
          fail UnknownRoleException.new("Unrecognised programme role name #{role}") unless Seek::Roles::ProgrammeRelatedRoles.role_names.include?(role)
          Seek::Roles::ProgrammeRelatedRoles.instance.programmes_for_person_with_role(self, role)
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
end
