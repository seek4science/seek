module Seek #:nodoc:
  module Permissions #:nodoc:
    module ActsAsAuthorized
      AUTHORIZATION_ACTIONS = %i[view edit download delete manage].freeze

      def self.included(ar)
        ar.const_get(:Base).class_eval { include BaseExtensions }
      end

      module BaseExtensions
        def self.included(base)
          base.extend ClassMethods
        end

        # Sets up the basic interface for authorization hooks. All AR instances get these methods, and by default they return true.
        AUTHORIZATION_ACTIONS.each do |action|
          eval <<-END_EVAL
            def can_#{action}? user=User.current_user
              true
            end
          END_EVAL

          def can_perform?(action, *args)
            send "can_#{action}?", *args
          end
        end

        def authorization_supported?
          self.class.authorization_supported?
        end

        def contributor_credited?
          false
        end

        def title_is_public?
          false
        end

        module ClassMethods
          def acts_as_authorized
            include Seek::Permissions::PolicyBasedAuthorization
            include Seek::Permissions::CodeBasedAuthorization
            include Seek::Permissions::StateBasedPermissions
            include Seek::Permissions::PublishingPermissions

            does_not_require_can_edit :uuid, :first_letter
          end

          def authorization_supported?
            include?(Seek::Permissions::PolicyBasedAuthorization)
          end
        end
      end
    end
  end
end

ActiveRecord.module_eval do
  include Seek::Permissions::ActsAsAuthorized
end
