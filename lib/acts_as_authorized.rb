module Acts #:nodoc:
  module Authorized #:nodoc:
    def self.included(ar)
      ar.const_get(:Base).class_eval { include BaseExtensions }
      ar.module_eval { include AuthorizationEnforcement }
      ar.const_get(:Base).class_eval { does_not_require_can_edit :uuid, :first_letter }
    end

    AUTHORIZATION_ACTIONS = [:view, :edit, :download, :delete, :manage]

    module BaseExtensions
      def self.included base
        base.extend ClassMethods
      end

      #Sets up the basic interface for authorization hooks. All AR instances get these methods, and by default they return true.
      AUTHORIZATION_ACTIONS.each do |action|
        define_method "can_#{action}?" do
          true
        end

        def can_perform? action, *args
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

      def publish!
        if can_manage?
          policy.access_type=Policy::ACCESSIBLE
          policy.sharing_scope=Policy::EVERYONE
          policy.save
        else
          false
        end
      end

      def is_published?
        can_download? nil
      end

      module ClassMethods
        def acts_as_authorized
          include Acts::Authorized::PolicyBasedAuthorization
        end

        def authorization_supported?
          include?(Acts::Authorized::PolicyBasedAuthorization)
        end
      end
    end
  end
end

require 'authorization_enforcement'
require 'policy_based_authorization'

ActiveRecord.module_eval do
  include Acts::Authorized
end

