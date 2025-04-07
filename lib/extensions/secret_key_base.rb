module Extensions
  module SecretKeyBase
    def secret_key_base
      if Rails.env.production?
        Seek::Config.secret_key_base.freeze
      else
        "3daa438adac605595e91478ba4d9291ddcae049c9f0a922731b9f94fa7f65804db54fb19554490e45436ab8b7beb738f97c2c98ca9d00f5ac3d12749611c80f3".freeze
      end
    end
  end
end

Rails::Application::Configuration.prepend Extensions::SecretKeyBase