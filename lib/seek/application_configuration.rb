module Seek
  class ApplicationConfiguration

    #or we could just extend Settings..
    def self.method_missing method, *args, &block
      Settings.send method, *args, &block
    end

#Features enabled
    def self.exception_notification_enabled= value
        Settings.exception_notification_enabled = value
        if Settings.exception_notification_enabled
          ExceptionNotifier.render_only = false
          ExceptionNotifier.send_email_error_codes = %W( 400 406 403 405 410 500 501 503 )
          ExceptionNotifier.sender_address = %w(no-reply@sysmo-db.org)
          ExceptionNotifier.email_prefix = "[SEEK-#{RAILS_ENV.capitalize} ERROR] "
          ExceptionNotifier.exception_recipients = %w(joe@example.com bill@example.com)
        else
          ExceptionNotifier.render_only = true
        end
    end

    def self.google_analytics_enabled= value
         Settings.google_analytics_enabled = value
         if Settings.google_analytics_enabled
           Rubaidh::GoogleAnalytics.tracker_id = Settings.google_analytics_tracker_id
         else
           #This isn't needed if Settings is set to default the tracker_id to 000-000
           Rubaidh::GoogleAnalytics.tracker_id = "000-000"
         end
    end

#Project
    def self.project_long_name
         Settings.project_long_name || "#{Settings.project_name} #{Settings.project_type}"
    end

    def self.project_title
        Settings.project_title || self.project_long_name
    end

    def self.dm_project_name
         Settings.dm_project_name || Settings.project_name
    end

    def self.dm_project_title
         Settings.dm_project_title || self.project_title
    end

    def self.dm_project_link
         Settings.dm_project_link || Settings.project_link
    end

    def self.application_name
         Settings.application_name || "#{Settings.project_name}-SEEK"
    end

    def self.application_title
         Settings.application_title || self.application_name
    end

    def self.header_image_link
         Settings.header_image_link || self.dm_project_link
    end

    def self.header_image_title
         Settings.header_image_title || self.dm_project_name
    end

#Pagination
    def self.default_page controller
        Settings.index[controller.to_sym]
    end
    def self.set_default_page (controller, value)
        Settings.merge! :index, controller.to_sym => value
    end

#Others

    def self.tag_threshold
        Integer(Settings.tag_threshold)
    end

    def self.max_visible_tags
        Integer(Settings.max_visible_tags)
    end

    def self.smtp_settings field
        Settings.smtp_settings[field.to_sym]
    end
    def self.set_smtp_settings (field, value)
      Settings.merge! :smtp_settings, field.to_sym => value
      ActionMailer::Base.smtp_settings= {
        :address => Settings.smtp_settings[:address],
        :port => Settings.smtp_settings[:port],
        :domain => Settings.smtp_settings[:domain],
        :authentication => Settings.smtp_settings[:authentication],
        :user_name => Settings.smtp_settings[:user_name],
        :password  => Settings.smtp_settings[:password]
      }
    end

    def self.open_id_authentication_store= value
        Settings.open_id_authentication_store = value
        OpenIdAuthentication.store = Settings.open_id_authentication_store
    end

 end
end