module Extensions
  module Object
    # Disables all authorization enforcement within the block passed to this method.
    def disable_authorization_checks
      saved = Thread.current[:authorization_checks_disabled]
      Thread.current[:authorization_checks_disabled] = true
      yield
    ensure
      Thread.current[:authorization_checks_disabled] = saved
    end

    def authorization_checks_disabled?
      !!Thread.current[:authorization_checks_disabled]
    end

    def disable_authorization_checks!
      Thread.current[:authorization_checks_disabled] = true
    end

    def enable_authorization_checks!
      Thread.current[:authorization_checks_disabled] = false
    end
  end
end

Object.include Extensions::Object
