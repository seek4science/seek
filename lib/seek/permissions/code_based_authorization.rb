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
        # Check own special auth codes first
        return true if special_auth_codes.unexpired.collect(&:code).include?(code)

        # For ISA items, also check parent codes to allow hierarchical access
        # This allows Investigation codes to work on Studies/Assays, and Study codes to work on Assays
        if is_a?(Study) && respond_to?(:investigation)
          # Study can be accessed with its parent Investigation's code
          return investigation.special_auth_codes.unexpired.collect(&:code).include?(code) if investigation
        elsif is_a?(Assay)
          # Assay can be accessed with its parent Study's code
          if respond_to?(:study) && study
            return true if study.special_auth_codes.unexpired.collect(&:code).include?(code)
            # Assay can also be accessed with its grandparent Investigation's code
            return study.investigation.special_auth_codes.unexpired.collect(&:code).include?(code) if study.investigation
          end
        end

        false
      end

      def check_owner_can_manage(_code)
        if authorization_checks_enabled
          raise 'You cannot change the items' unless can_manage?
        end
      end
    end
  end
end
