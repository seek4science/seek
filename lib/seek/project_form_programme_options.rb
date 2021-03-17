module Seek
  # the behaviour of the project creation form Programme options is driven by several configuration options
  # this class bundles the behaviour together into one logical place
  class ProjectFormProgrammeOptions
    module ClassMethods
      # whether the Programme box should be shown at all
      def show_programme_box?
        Seek::Config.programmes_enabled && (
          programme_administrator_logged_in? ||
            Programme.site_managed_programme.present? ||
            Programme.can_create?
        )
      end

      # whether the programmes should be selected from a drop down box
      def programme_dropdown?
        show_programme_box? && programme_administrator_logged_in?
      end

      # whether there should be a checkbox to select a managed programme
      def managed_checkbox?
        !programme_dropdown? &&
          Programme.site_managed_programme.present? &&
          Programme.can_create?
      end

      # whether managed programmes are forced and the only option
      def managed_only?
        !programme_dropdown? &&
          Programme.site_managed_programme.present? &&
          !Programme.can_create?
      end

      # whether programme creation is an allowed option
      def creation_allowed?
        show_programme_box? && Programme.can_create?
      end

      # whether creating a new programme is the only option
      def creation_allowed_only?
        creation_allowed? && !(
          programme_administrator_logged_in? ||
            Programme.site_managed_programme.present?
        )
      end

      private

      # private method - whether a programme administrator is logged in
      def programme_administrator_logged_in?
        User.programme_administrator_logged_in?
      end
    end

    extend ClassMethods
  end
end
