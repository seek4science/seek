module Seek
  module Roles
    # subclass for handler for Roles that are related to something, for example Projects
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

      def items_for_person_and_role(person, role_name)
        if person.roles.include?(role_name)
          mask = mask_for_role(role_name)
          join_association = related_item_join_class.name.underscore.pluralize
          related_item_class.joins(join_association.to_sym).where(
            "#{join_association}.person_id" => person.id).where("#{join_association}.role_mask" => mask).readonly(false)
        else
          # can't just return an empty array, as scopes may be added or the query extended
          related_item_class.where('1=2')
        end
      end

      def add_roles(person, role_info)
        return if role_info.items.empty?

        item_ids = collect_item_ids(role_info.items)

        # filter out any item ids attempted to be related to this role
        item_ids = filter_allowed_related_item_ids(item_ids, person)

        if item_ids.any?

          current_item_ids = items_ids_related_to_person_and_role(person, role_info.role_name)

          mask = role_info.role_mask

          (item_ids - current_item_ids).each do |item_id|
            related_items_association(person) << related_item_join_class.new(associated_item_id_sym => item_id, role_mask: mask)
          end

          if (person.roles_mask & mask).zero?
            person.update_attribute(:roles_mask, person.roles_mask + mask)
          end
        end
      end

      def remove_roles(person, role_info)
        return unless person.has_role?(role_info.role_name) # nothing to remove
        item_ids = collect_item_ids(role_info.items)

        current_item_ids = items_ids_related_to_person_and_role(person, role_info.role_name)
        item_ids.each do |item_id|
          clause = { "#{related_item_class.name.downcase}_id" => item_id }
          related_items_association(person).where(role_mask: role_info.role_mask).where(clause).destroy_all
        end
        if (current_item_ids - item_ids).empty?
          person.update_attribute(:roles_mask, person.roles_mask - role_info.role_mask)
        end
      end

      # Methods that should be implemented or overridden in superclass
      def related_item_class
        fail('Needs defining in subclass')
      end

      def related_item_join_class
        fail('Needs defining in subclass')
      end

      def related_items_association(_person)
        fail('Needs defining in subclass')
      end

      # by default nothing is filtered
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

      def items_ids_related_to_person_and_role(person, role_name)
        items_for_person_and_role(person, role_name).collect(&:id)
      end
    end
  end
end
