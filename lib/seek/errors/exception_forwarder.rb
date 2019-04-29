module Seek
  module Errors
    # Handles forwarding Exception emails, via the ExceptionNotifier, but with additional default data and logging
    class ExceptionForwarder
      # Sends an exception email, if enabled, reported the provided exception, along with any options
      #
      # the option :data will get merged with some default info that reports the configured site host, and current user
      # information
      def self.send_notification(exception, options = {}, user = User.current_user)
        return unless Seek::Config.exception_notification_enabled
        env = options[:env]
        data = default_data(user).merge(options[:data] || {})
        begin
          Rails.logger.error "Sending execption ERROR - #{exception.class.name} (#{exception.message})"
          ExceptionNotifier.notify_exception(exception, env: env, data: data)
         rescue StandardError => deliver_exception
           Rails.logger.error 'Error delivering exception email - ' \
                        "#{deliver_exception.class.name} (#{deliver_exception.message})"
        end
      end

      def self.default_data(user)
        {
          user: user_hash(user),
          person: person_hash(user),
          site_host: Seek::Config.site_base_host
        }
      end

      def self.user_hash(user)
        return {} unless user
        { id: user.id,
          login: user.login,
          created_at: user.created_at }
      end

      def self.person_hash(user)
        return {} unless user&.person
        person = user.person
        { id: person.id,
          name: person.title,
          email: person.email,
          created_at: person.created_at }
      end
    end
  end
end
