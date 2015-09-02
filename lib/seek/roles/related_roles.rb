module Seek
  module Roles
    #subclass for handler for Roles that are related to something, for example Projects
    class RelatedRoles < Roles
      def self.role_names
        []
      end

      def check_role_for_item(person, role_name, programme)
        roles_for_person_and_item(person, programme).include?(role_name)
      end

      def roles_for_person_and_item(person, item)
        id = (item.is_a?(related_item_class)) ? item.id : item.to_i
        person.roles.select do |role_name|
          mask = mask_for_role(role_name)
          related_items_association(person).where(role_mask: mask).where(associated_item_id_sym => id).any?
        end
      end

      def items_for_person_and_role(person, role)
        if person.roles.include?(role)
          mask = mask_for_role(role)

          related_items_association(person).where(role_mask: mask).collect(&:item)
        else
          []
        end
      end

      def add_roles(person, role_name, items)
        return if items.empty?
        mask = mask_for_role(role_name)
        item_ids = collect_item_ids(items)

        #filter out any item ids attempted to be related to this role
        item_ids = filter_allowed_related_item_ids(item_ids, person)

        if item_ids.any?

          current_item_ids = items_ids_related_to_person_and_role(role_name, person)

          (item_ids - current_item_ids).each do |item_id|
            related_items_association(person) << related_item_join_class.new(associated_item_id_sym => item_id, role_mask: mask)
          end

          person.roles_mask += mask if (person.roles_mask & mask).zero?
        end

      end

      def remove_roles(person, role_name, items)
        return unless person.has_role?(role_name) # nothing to remove
        mask = mask_for_role(role_name)
        item_ids = collect_item_ids(items)

        current_item_ids = items_ids_related_to_person_and_role(role_name, person)
        item_ids.each do |item_id|
          clause = {"#{related_item_class.name.downcase}_id" => item_id}
          related_items_association(person).where(role_mask: mask).where(clause).destroy_all
        end
        person.roles_mask -= mask if (current_item_ids - item_ids).empty?
      end

      #Methods that should be implemented or overridden in superclass
      def related_item_class
        fail("Needs defining in subclass")
      end

      def related_item_join_class
        fail("Needs defining in subclass")
      end

      def related_items_association(person)
        fail("Needs defining in subclass")
      end

      #by default nothing is filtered
      def filter_allowed_related_item_ids(item_ids, _person)
        item_ids
      end

      private

      def associated_item_id_sym
        "#{related_item_class.name.downcase}_id".to_sym
      end

      def collect_item_ids(items)
        items.collect { |item| item.is_a?(related_item_class) ? item.id : item.to_i }
      end

      def items_ids_related_to_person_and_role(role_name, person)
        related_items_association(person).where(role_mask: mask_for_role(role_name)).collect(&:item).collect(&:id)
      end

    end
  end
end
