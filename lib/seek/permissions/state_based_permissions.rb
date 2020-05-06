module Seek
  module Permissions
    module StateBasedPermissions
      def self.included(_klass)
        Seek::Permissions::ActsAsAuthorized::AUTHORIZATION_ACTIONS.each do |action|
          define_method "state_allows_#{action}?" do |_user = User.current_user|
            true
          end
        end
      end
    end
  end
end
