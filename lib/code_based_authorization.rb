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

    [:view, :download].each do |action|
        eval <<-END_EVAL
          def can_#{action}? user = User.current_user
            SpecialAuthCode.current_auth_code.try(:asset) == self or super
          end
        END_EVAL
    end

    end
  end
end