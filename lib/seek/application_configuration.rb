module Seek
  class ApplicationConfiguration
#Features enabled
    def self.events_enabled
         Settings.events_enabled
    end
    def self.events_enabled=value
         Settings.events_enabled = value
    end

    def self.jerm_enabled
         Settings.jerm_enabled
    end
    def self.jerm_enabled=value
         Settings.jerm_enabled = value
    end

    def self.email_enabled
         Settings.email_enabled
    end
    def self.email_enabled= value
          Settings.email_enabled = value
     end

    def self.noreply_sender
         Settings.noreply_sender
    end
    def self.noreply_sender= value
         Settings.noreply_sender = value
    end

    def self.solr_enabled
         Settings.solr_enabled
    end
    def self.solr_enabled= value
         Settings.solr_enabled = value
    end

    def self.jws_enabled
         Settings.jws_enabled
    end
    def self.jws_enabled= value
         Settings.jws_enabled = value
    end

    def self.jws_online_root
         Settings.jws_online_root
    end
    def self.jws_online_root= value
         Settings.jws_online_root = value
    end

    def self.exception_notification_enabled
         Settings.exception_notification_enabled
    end
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

    def self.hide_details_enabled
         Settings.hide_details_enabled
    end
    def self.hide_details_enabled= value
         Settings.hide_details_enabled = value
    end

    def self.activity_log_enabled
         Settings.activity_log_enabled
    end
    def self.activity_log_enabled= value
         Settings.activity_log_enabled = value
    end

    def self.activation_required_enabled
         Settings.activation_required_enabled
    end
    def self.activation_required_enabled= value
         Settings.activation_required_enabled = value
    end

    def self.google_analytics_enabled
         Settings.google_analytics_enabled
    end
    def self.google_analytics_enabled= value
         Settings.google_analytics_enabled = value
         if Settings.google_analytics_enabled
           Rubaidh::GoogleAnalytics.tracker_id = Settings.google_analytics_tracker_id
         else
           Rubaidh::GoogleAnalytics.tracker_id = "000-000"
         end

    end

    def self.google_analytics_tracker_id
         Settings.google_analytics_tracker_id
    end
    def self.google_analytics_tracker_id= value
         Settings.google_analytics_tracker_id = value
    end

#Project
    def self.project_name
         Settings.project_name
    end
    def self.project_name= value
         Settings.project_name = value
    end

    def self.project_type
         Settings.project_type
    end
    def self.project_type= value
         Settings.project_type = value
    end

    def self.project_link
         Settings.project_link
    end
    def self.project_link= value
         Settings.project_link = value
    end

    def self.project_long_name
         Settings.project_long_name || "#{Settings.project_name} #{Settings.project_type}"
    end
    def self.project_long_name= value
         Settings.project_long_name = value
    end

    def self.project_title
        Settings.project_title || self.project_long_name
    end
    def self.project_title= value
         Settings.project_title = value
    end

    def self.dm_project_name
         Settings.dm_project_name || Settings.project_name
    end
    def self.dm_project_name= value
         Settings.dm_project_name = value
    end

    def self.dm_project_title
         Settings.dm_project_title || self.project_title
    end
    def self.dm_project_title= value
         Settings.dm_project_title = value
    end

    def self.dm_project_link
         Settings.dm_project_link || Settings.project_link
    end
    def self.dm_project_link= value
         Settings.dm_project_link = value
    end

    def self.application_name
         Settings.application_name || "#{Settings.project_name}-SEEK"
    end
    def self.application_name= value
         Settings.application_name = value
    end

    def self.application_title
         Settings.application_title || self.application_name
    end
    def self.application_title= value
         Settings.application_title = value
    end

    def self.header_image_enabled
         Settings.header_image_enabled
    end
    def self.header_image_enabled= value
         Settings.header_image_enabled = value
    end

    def self.header_image_link
         Settings.header_image_link || self.dm_project_link
    end
    def self.header_image_link= value
         Settings.header_image_link = value
    end
    def self.header_image_title
         Settings.header_image_title || self.dm_project_name
    end
    def self.header_image_title= value
         Settings.header_image_title = value
    end

#Pagination
    def self.default_page controller
        Settings.index[controller.to_sym]
    end
    def self.set_default_page (controller, value)
        Settings.merge! :index, controller.to_sym => value
    end

    def self.limit_latest
        Settings.limit_latest.to_i
    end
    def self.limit_latest= value
        Settings.limit_latest = value
    end
#Others
    def self.type_managers_enabled
        Settings.type_managers_enabled
    end
    def self.type_managers_enabled= value
        Settings.type_managers_enabled = value
    end

    def self.type_managers
        Settings.type_managers
    end
    def self.type_managers= value
        Settings.type_managers = value
    end

    def self.tag_threshold
        Integer(Settings.tag_threshold)
    end
    def self.tag_threshold= value
        Settings.tag_threshold = value
    end

    def self.max_visible_tags
        Integer(Settings.max_visible_tags)
    end
    def self.max_visible_tags= value
        Settings.max_visible_tags = value
    end

    def self.pubmed_api_email
        Settings.pubmed_api_email
    end
    def self.pubmed_api_email= value
        Settings.pubmed_api_email = value
    end

    def self.crossref_api_email
        Settings.crossref_api_email
    end
    def self.crossref_api_email= value
        Settings.crossref_api_email = value
    end

    def self.site_base_host
        Settings.site_base_host
    end
    def self.site_base_host= value
        Settings.site_base_host = value
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

    def self.open_id_authentication_store
        Settings.open_id_authentication_store
    end
    def self.open_id_authentication_store= value
        Settings.open_id_authentication_store = value
        OpenIdAuthentication.store = Settings.open_id_authentication_store
    end

    def self.copyright_addendum_enabled
        Settings.copyright_addendum_enabled
    end
    def self.copyright_addendum_enabled= value
        Settings.copyright_addendum_enabled = value
    end

    def self.copyright_addendum_content
        Settings.copyright_addendum_content
    end
    def self.copyright_addendum_content= value
        Settings.copyright_addendum_content = value
    end

 end
end