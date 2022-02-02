if (Rails.env.development? || Rails.env.test?) # && false
  class DevEmail
    def self.delivering_email(mail)
      mail.to = 'test@localhost'
      pp mail
    end
  end
  ActionMailer::Base.register_interceptor(DevEmail)
end