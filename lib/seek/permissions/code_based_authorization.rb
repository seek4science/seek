# allows the current
module Seek
  module Permissions
    module CodeBasedAuthorization
      def self.included(klass)
        klass.extend ClassMethods
        klass.class_eval do
          has_many :special_auth_codes, as: :asset, before_add: :check_owner_can_manage,
                                        before_remove: :check_owner_can_manage
          accepts_nested_attributes_for :special_auth_codes, allow_destroy: true
        end
      end

      module ClassMethods
      end

      def auth_by_code?(code)
        return false if code.blank?
        return true if special_auth_codes.unexpired.where(code: code).exists?

        if is_a?(Investigation)
          return false
        elsif is_a?(Study) && respond_to?(:investigation)
          return investigation.special_auth_codes.unexpired.where(code: code).exists? if investigation
        elsif is_a?(Assay)
          if respond_to?(:study) && study
            return true if study.special_auth_codes.unexpired.where(code: code).exists?
            return study.investigation.special_auth_codes.unexpired.where(code: code).exists? if study.investigation
          end
        elsif respond_to?(:assays) && assays.any?
          assays.each do |assay|
            return true if assay.special_auth_codes.unexpired.where(code: code).exists?

            if assay.study
              return true if assay.study.special_auth_codes.unexpired.where(code: code).exists?
              return true if assay.study.investigation&.special_auth_codes&.unexpired&.where(code: code)&.exists?
            end
          end
        end

        false
      end

      def check_owner_can_manage(_code)
        return unless authorization_checks_enabled
        raise 'You cannot change the items' unless can_manage?
      end
    end
  end
end
