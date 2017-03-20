module Seek
  module Roles
    ADMIN = 'admin'
    # Roles that stand alone, and are not linked to anything, for example Project or Programme
    class StandAloneRoles < Seek::Roles::Roles
      class InvalidCheckException < Exception; end

      def self.role_names
        [Seek::Roles::ADMIN]
      end

      def add_roles(person, role_info)
        fail InvalidCheckException.new("This role should not be assigned with other items - #{items.inspect}") unless role_info.items.empty?
        mask = mask_for_role(role_info.role_name)
        person.roles_mask += mask if (person.roles_mask & mask).zero?
      end

      def remove_roles(person, role_info)
        fail InvalidCheckException.new("This role should not be assigned with other items - #{items.inspect}") unless role_info.items.empty?
        return unless person.has_role?(role_info.role_name)
        mask = mask_for_role(role_info.role_name)
        person.roles_mask -= mask
      end

      def check_role_for_item(_person, _role_name, item)
        fail InvalidCheckException.new("This role should not be checked against an item - #{item.inspect}") unless item.nil?
        true
      end

      module PersonInstanceMethods
        def is_admin?
          has_role?(Seek::Roles::ADMIN)
        end

        def is_admin=(flag_and_items)
          assign_or_remove_roles(Seek::Roles::ADMIN, flag_and_items)
        end
      end

      module PersonClassMethods
        def admins
          Seek::Roles::Roles.instance.people_with_role(Seek::Roles::ADMIN)
        end
      end
    end
  end
end
