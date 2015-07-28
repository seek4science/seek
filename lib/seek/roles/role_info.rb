module Seek
  module Roles
    class RoleInfo
      attr_reader :role_name
      attr_reader :items

      def initialize args

        args.each do |param_name,value|
          instance_variable_set("@#{param_name}", value)
        end
        @items ||=[]
        @items = Array(@items)

        unless Seek::Roles::Roles.role_names.include?(@role_name)
          raise Seek::Roles::UnknownRoleException.new("Unknown role '#{@role_name.inspect}'")
        end
      end
    end
  end
end