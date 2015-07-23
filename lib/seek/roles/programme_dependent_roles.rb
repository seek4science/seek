module Seek
  module Roles
    class ProgrammeDependentRoles < DependentRoles
      def self.role_names
        %w(programme_administrator)
      end

      def self.define_extra_methods(base)
        role_names.each do |role|
          base.class_eval <<-END_EVAL
          def is_#{role}_of_any_programme?
            is_#{role}?(nil,true)
          end

          END_EVAL
        end
      end

      def add_roles(person, role_name, items)
        programme_ids = items.collect { |p| p.is_a?(Programme) ? p.id : p.to_i }

        mask = mask_for_role(role_name)

        current_programme_ids = person.admin_defined_role_programmes.where(role_mask: mask).collect { |r| r.programme.id }

        (programme_ids - current_programme_ids).each do |programme_id|
          person.admin_defined_role_programmes << AdminDefinedRoleProgramme.new(programme_id: programme_id, role_mask: mask)
        end

        person.roles_mask += mask if (person.roles_mask & mask).zero?
      end

      def remove_roles(person, role_name, items)
        programme_ids = items.collect { |p| p.is_a?(Programme) ? p.id : p.to_i }
        mask = mask_for_role(role_name)

        current_programme_ids = person.admin_defined_role_programmes.where(role_mask: mask).collect { |r| r.programme.id }
        programme_ids.each do |programme_id|
          AdminDefinedRoleProgramme.where(programme_id: programme_id, role_mask: mask, person_id: person.id).destroy_all
        end
        person.roles_mask -= mask if (current_programme_ids - programme_ids).empty?
      end

      def people_with_programme_and_role(programme, role)
        mask = mask_for_role(role)
        AdminDefinedRoleProgramme.where(role_mask: mask, programme_id: programme.id).collect(&:person)
      end

      def associated_item_class
        Programme
      end
    end
  end
end
