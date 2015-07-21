module Seek
  module Roles
    class DependentRoles < Roles
      def self.role_names
        []
      end

      def check_role_for_item(person, role_name, programme)
        roles_for_person_and_item(person, programme).include?(role_name)
      end

      def roles_for_person_and_item(person, item)
        id = (item.is_a?(associated_item_class)) ? item.id : item.to_i
        person.roles.select do |role_name|
          mask = mask_for_role(role_name)
          clause = { "#{associated_item_class.name.downcase}_id" => id, role_mask: mask }
          method = "admin_defined_role_#{associated_item_class.name.downcase.pluralize}"
          person.send(method).where(clause).any?
        end
      end
    end
  end
end
