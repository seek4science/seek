module Seek
  module Roles
    class UnknownRoleException < Exception; end
    class Roles
      include Singleton

      def self.role_names
        StandAloneRoles.role_names | ProjectRelatedRoles.role_names | ProgrammeRelatedRoles.role_names
      end

      def self.define_methods(base)
        define_common_methods(base)

        descendants.each do |subclass|
          subclass.define_extra_methods(base) if subclass.respond_to?(:define_extra_methods)
        end
      end

      def self.define_common_methods(base)
        role_names.each do |role|
          base.class_eval <<-END_EVAL
            def is_#{role}?(item=nil)
              has_role?('#{role}') && Seek::Roles::Roles.instance.check_role_for_item(self,'#{role}',item)
            end

            def is_#{role}=(flag_and_items)
                flag_and_items = Array(flag_and_items)
                flag = flag_and_items[0]
                items = flag_and_items[1]
                if flag
                  Seek::Roles::Roles.instance.add_roles(self,'#{role}',items)
                else
                  Seek::Roles::Roles.instance.remove_roles(self,'#{role}',items)
                end
            end

            def self.#{role}s
              Seek::Roles::Roles.instance.people_with_role('#{role}')
            end
          END_EVAL
        end
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

      def add_roles(person, role_name, items)
        person.roles_mask ||= 0
        select_handler(role_name).instance.add_roles(person, role_name, Array(items))
      end

      def remove_roles(person, role_name, items)
        select_handler(role_name).instance.remove_roles(person, role_name, Array(items))
      end

      def check_role_for_item(person, role_name, item)
        select_handler(role_name).instance.check_role_for_item(person, role_name, item)
      end

      def select_handler(role_name)
        handler = self.class.descendants.detect do |subclass|
          subclass.role_names.include?(role_name)
        end
        fail Seek::Roles::UnknownRoleException.new("Unknown role '#{role_name.inspect}'") if handler.nil?
        handler
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
