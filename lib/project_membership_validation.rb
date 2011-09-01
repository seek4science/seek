module Acts
  module Authorized
    module ProjectMembershipValidation

      def self.included(klass)
        klass.class_eval do
          #validate :current_user_must_be_a_member_of_a_project
          validate :current_user_must_be_member_of_associated_project
        end
      end

      def current_user_must_be_member_of_associated_project
        if User.current_user.nil? || User.current_user.person.nil? || !User.current_user.person.member_of?(projects)
          errors.add(:projects, "You must be a member of one of the the associated project")
        end
      end
    end
  end
end
