# allows the current
module Seek
  module Permissions
    module CodeBasedAuthorization
      def self.included(klass)
        klass.extend ClassMethods
        klass.class_eval do
          has_many :special_auth_codes, as: :asset, before_add: :check_owner_can_manage, before_remove: :check_owner_can_manage
          accepts_nested_attributes_for :special_auth_codes, allow_destroy: true
        end
      end

      module ClassMethods
      end

      def auth_by_code?(code)
        special_auth_codes.unexpired.collect(&:code).include?(code)
      end

      def check_owner_can_manage(_code)
        if authorization_checks_enabled
          raise 'You cannot change the items' unless can_manage?
        end
      end
    end
  end
end
