module Seek #:nodoc:
  module Permissions #:nodoc:
    module ActsAsAuthorized
      extend ActiveSupport::Concern

      AUTHORIZATION_ACTIONS = %i[view download edit manage delete].freeze

      class_methods do
        def acts_as_authorized
          include Seek::Permissions::PolicyBasedAuthorization
          include Seek::Permissions::CodeBasedAuthorization
          include Seek::Permissions::StateBasedPermissions
          include Seek::Permissions::PublishingPermissions
          include Seek::Permissions::SpecialContributors

          does_not_require_can_edit :uuid, :first_letter
        end

        def authorization_supported?
          include?(Seek::Permissions::PolicyBasedAuthorization)
        end

        # Allow `authorized_for` to be safely called on any collection of SEEK resources.
        def authorized_for(action, user = User.current_user)
          assets = all
          assets = assets.select { |a| a.send("can_#{action}?", user) } if should_check_can?(action)
          assets
        end

        # Only check `can...` if it has been overridden.
        def should_check_can?(action)
          instance_method("can_#{action}?").owner != Seek::Permissions::ActsAsAuthorized
        end

        # Delegate this type's authorization to i.e. an associated object
        def delegate_auth_to(authable)
          delegate *AUTHORIZATION_ACTIONS.map { |a| :"can_#{a}?" }, to: authable
        end
      end

      # Sets up the basic interface for authorization hooks. All AR instances get these methods, and by default they return true.
      AUTHORIZATION_ACTIONS.each do |action|
        define_method "can_#{action}?" do |_user = User.current_user|
          true
        end
      end

      def can_perform?(action, *args)
        send("can_#{action}?", *args)
      end

      def authorization_supported?
        self.class.authorization_supported?
      end

      def title_is_public?
        false
      end
    end
  end
end
