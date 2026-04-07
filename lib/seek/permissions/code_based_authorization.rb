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
        # But does NOT allow child codes to work on parents (no upward propagation)
        if is_a?(Investigation)
          # Investigation only checks its own codes (already checked above)
          # It does NOT check child Study or Assay codes
          return false
        elsif is_a?(Study) && respond_to?(:investigation)
          # Study can be accessed with its parent Investigation's code
          return investigation.special_auth_codes.unexpired.collect(&:code).include?(code) if investigation
        elsif is_a?(Assay)
          # Assay can be accessed with its parent Study's code
          if respond_to?(:study) && study
            return true if study.special_auth_codes.unexpired.collect(&:code).include?(code)
            # Assay can also be accessed with its grandparent Investigation's code
            return study.investigation.special_auth_codes.unexpired.collect(&:code).include?(code) if study.investigation
          end
        else
          # For assets (DataFiles, Models, SOPs, etc.), check parent Assay codes
          # This allows Assay codes to work on associated assets
          if respond_to?(:assays) && assays.any?
            # Check if any parent Assay has this code (or its parent Study/Investigation)
            assays.each do |assay|
              return true if assay.special_auth_codes.unexpired.collect(&:code).include?(code)
              # Also check the Assay's parent Study
              if assay.study
                return true if assay.study.special_auth_codes.unexpired.collect(&:code).include?(code)
                # Also check the Study's parent Investigation
                return true if assay.study.investigation && assay.study.investigation.special_auth_codes.unexpired.collect(&:code).include?(code)
              end
            end
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
