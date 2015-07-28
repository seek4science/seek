module Seek
  module Roles
    # Roles that stand alone, and are not linked to anything, for example Project or Programme
    class StandAloneRoles < Seek::Roles::Roles
      class InvalidCheckException < Exception; end

      def self.role_names
        %w(admin)
      end

      def add_roles(person, role_name, items = [])
        fail InvalidCheckException.new("This role should not be assigned with other items - #{items.inspect}") unless items.empty?
        mask = mask_for_role(role_name)
        person.roles_mask += mask if (person.roles_mask & mask).zero?
      end

      def remove_roles(person, role_name, items = [])
        fail InvalidCheckException.new("This role should not be assigned with other items - #{items.inspect}") unless items.empty?
        return unless person.has_role?(role_name)
        mask = mask_for_role(role_name)
        person.roles_mask -= mask
      end

      def check_role_for_item(_person, _role_name, item)
        fail InvalidCheckException.new("This role should not be checked against an item - #{item.inspect}") unless item.nil?
        true
      end
    end
  end
end
