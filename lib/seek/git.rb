module Seek
  module Git
    def with_git_user(&block)
      orig_user_name = git_base.config('user.name')
      orig_user_email = git_base.config('user.email')
      git_base.config('user.name', git_user_name)
      git_base.config('user.email', git_user_email)
      yield
    ensure
      git_base.config('user.name', orig_user_name)
      git_base.config('user.email', orig_user_email)
    end

    def git_user_name
      User.current_user&.person&.name || Seek::Config.application_name
    end

    def git_user_email
      User.current_user&.person&.email || Seek::Config.noreply_sender
    end
  end
end