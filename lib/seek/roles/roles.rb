module Seek
  module Roles
    class UnknownRoleException < Exception; end
    class Roles
      include Singleton

      def self.role_names
        StandAloneRoles.role_names | ProjectRelatedRoles.role_names | ProgrammeRelatedRoles.role_names
      end

      def role_names_for_mask(roles_mask)
        role_names.reject do |r|
          ((roles_mask || 0) & mask_for_role(r)).zero?
        end
      end

      def people_with_role(role_name)
        mask = mask_for_role(role_name)
        clause = 'roles_mask & ' + mask.to_s + ' > 0'
        Person.where(clause)
      end

      def mask_for_role(role)
        2**Seek::Roles::Roles.role_names.index(role.to_s)
      end

      def role_names
        self.class.role_names
      end
    end
  end
end
