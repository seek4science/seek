module Seek
  module Roles
    module Refactor
      class InvalidRoleTypeException < Exception; end
      class RoleInfo
        attr_reader :role_name, :role_type, :role_mask, :items

        def initialize(args)
          @role_name = args[:role_name]
          args[:items] ||= []
          @items = Array(args[:items])
          @role_type = RoleType.find_by_key(@role_name)
          @role_mask

          fail Seek::Roles::UnknownRoleException.new("Unknown role '#{@role_name.inspect}'") unless @role_type

          @role_mask = Seek::Roles::Roles.instance.mask_for_role(@role_name)
        end
      end

      extend ActiveSupport::Concern

      included do
        has_many :roles, dependent: :destroy
        has_many :role_types, through: :roles
        after_commit :clear_role_cache

        include StandAloneRoles::PersonInstanceMethods
        extend StandAloneRoles::PersonClassMethods
        include ProjectRelatedRoles::PersonInstanceMethods
        extend ProjectRelatedRoles::PersonClassMethods
        include ProgrammeRelatedRoles::PersonInstanceMethods
        extend ProgrammeRelatedRoles::PersonClassMethods
      end

      class_methods do
        def with_role(key)
          joins(roles: :role_type).where(role_types: { key: key })
        end
      end

      def role_names
        role_types.pluck(:key).uniq
      end

      def scoped_roles(scope)
        roles.where(scope_id: scope&.id, scope_type: scope&.class&.name)
      end

      def has_role?(key)
        has_cached_role?(key, :any) || role_types.where(key: key).exists?
      end

      def check_for_role(key, scope)
        has_cached_role?(key, scope) || scoped_roles(scope).with_role_key(key).exists?
      end

      def is_admin_or_project_administrator?
        is_admin? || is_project_administrator_of_any_project?
      end

      def assign_or_remove_roles(rolename, flag_and_items)
        flag_and_items = Array(flag_and_items)
        flag = flag_and_items[0]
        items = flag_and_items[1]
        if flag
          add_roles(Seek::Roles::RoleInfo.new(role_name: rolename, items: items))
        else
          remove_roles(Seek::Roles::RoleInfo.new(role_name: rolename, items: items))
        end
      end

      def assign_role(key, scope = nil)
        return if check_for_role(key, scope)
        cache_role(key, scope)
        role_type = RoleType.find_by_key(key)
        raise InvalidRoleTypeException unless role_type
        scoped_roles(scope).build(role_type: role_type)
      end

      def add_roles(role_infos)
        Array(role_infos).each do |role_info|
          if role_info.items.empty?
            assign_role(role_info.role_name)&.save
          else
            role_info.items.each { |item| assign_role(role_info.role_name, item)&.save }
          end
        end
      end

      def remove_roles(role_infos)
        Array(role_infos).each do |role_info|
          if role_info.items.empty?
            scoped_roles(nil).where(role_type_id: role_info.role_type).destroy_all
          else
            role_info.items.each do |item|
              scoped_roles(item).where(role_type_id: role_info.role_type).destroy_all
            end
          end
        end
      end

      def check_role_for_item(_person, _role_name, item)
        fail InvalidCheckException.new("This role should not be checked against an item - #{item.inspect}") unless item.nil?
        true
      end

      private

      def role_cache
        @_role_cache ||= { any: Set.new }
      end

      def cache_role(key, scope)
        role_cache[scope] ||= Set.new
        role_cache[scope].add(key)
        role_cache[:any].add(key)
      end

      def has_cached_role?(key, scope)
        role_cache[scope] && role_cache[scope].include?(key)
      end

      def clear_role_cache
        @_role_cache = nil
      end
    end
  end
end