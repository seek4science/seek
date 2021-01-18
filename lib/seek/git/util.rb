module Seek
  module Git
    module Util
      def git_author
        { email: git_user_email, name: git_user_name, time: Time.now }
      end

      def git_user_name
        User.current_user&.person&.name || Seek::Config.application_name
      end

      def git_user_email
        User.current_user&.person&.email || Seek::Config.noreply_sender
      end
    end
  end
end