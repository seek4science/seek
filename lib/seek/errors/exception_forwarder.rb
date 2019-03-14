module Seek
  module Errors
    # Handles forwarding Exception emails, via the ExceptionNotifier, but with additional default data and logging
    class ExceptionForwarder
      # Sends an exception email, if enabled, reported the provided exception, along with any options
      #
      # the option :data will get merged with some default info that reports the configured site host, and current user
      # information
      def self.send_notification(exception, options = {})
        return unless Seek::Config.exception_notification_enabled
        env = option[:env]
        data = default_data.merge(options[:data] || {})
        begin
          logger.error "Sending execption ERROR - #{exception.class.name} (#{exception.message})"
          ExceptionNotifier.notify_exception(exception, env: env, data: data)
        rescue StandardError => deliver_exception
          logger.error 'Error delivering exception email - ' \
                       "#{deliver_exception.class.name} (#{deliver_exception.message})"
        end
      end

      def self.default_data
        {
          user: user_hash,
          person: person_hash,
          site_host: Seek::Config.site_base_host
        }
      end

      def self.user_hash
        return {} unless User.current_user
        { id: User.current_user.id,
          login: User.current_user.login,
          created_at: User.current_user.created_at }
      end

      def self.person_hash
        return {} unless User.current_user&.person
        person = User.current_user.person
        { id: person.id,
          name: person.title,
          email: person.email,
          created_at: person.created_at }
      end
    end
  end
end
