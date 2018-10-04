# frozen_string_literal: true

module Seek
  module Permissions
    # helper methods to help identify special contributor states, where the contributor is no longer known,
    # or never existed
    module SpecialContributors
      def has_deleted_contributor?
        contributor.nil? && deleted_contributor.present?
      end

      def has_jerm_contributor?
        contributor.nil? && deleted_contributor.nil?
      end
    end
  end
end
