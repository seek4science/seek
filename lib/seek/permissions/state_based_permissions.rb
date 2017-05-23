module Seek
  module Permissions
    module StateBasedPermissions
      def self.included(_klass)
        Seek::Permissions::ActsAsAuthorized::AUTHORIZATION_ACTIONS.each do |action|
          eval <<-END_EVAL
            def state_allows_#{action}? user = User.current_user
                return true
            end
          END_EVAL
        end
      end
    end
  end
end
