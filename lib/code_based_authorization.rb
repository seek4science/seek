#allows the current
module Acts
  module Authorized
    module CodeBasedAuthorization
      def self.included klass
        klass.extend ClassMethods
        klass.class_eval do
          has_many :special_auth_codes, :as => :asset, :required_access_to_owner => :manage
          accepts_nested_attributes_for :special_auth_codes, :allow_destroy => true
        end
      end

      module ClassMethods
      end

      def auth_by_code? code
        object.special_auth_codes.unexpired.collect(&:code).include?(code)
      end

    end
  end
end