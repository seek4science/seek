module Seek
  module Roles
    class RoleInfo
      attr_reader :role_name, :role_mask, :role_type, :items

      def initialize(args)
        args.each do |param_name, value|
          instance_variable_set("@#{param_name}", value)
        end
        @items ||= []
        @items = Array(@items)
        @role_type = RoleType.find_by_key(@role_name)

        unless Seek::Roles::Roles.role_names.include?(@role_name) || role_type.nil?
          fail Seek::Roles::UnknownRoleException.new("Unknown role '#{@role_name.inspect}'")
        end

        @role_mask = Seek::Roles::Roles.instance.mask_for_role(@role_name)
      end
    end
  end
end
