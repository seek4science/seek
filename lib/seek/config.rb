require 'forwardable'

module Seek
  class Config

    extend SingleForwardable

    #settings that require simple accessors. Avoids writing many duplicated getters and setters.
    simple_settings = [:events_enabled,:jerm_enabled, :email_enabled, :no_reply, :jws_enabled,
                       :jws_online_root, :hide_details_enabled, :activity_log_enabled,
                       :activation_required_enabled, :google_analytics_tracker_id, :project_name,
                       :project_type, :project_link, :header_image_enabled, :header_image,
                       :type_managers_enabled, :type_managers, :pubmed_api_email, :crossref_api_email,
                       :site_base_host, :copyright_addendum_enabled, :copyright_addendum_content, :noreply_sender]

    
    simple_settings.each do |sym|
      def_delegator Settings,sym
      def_delegator Settings,sym.to_s+"="
    end

    def self.solr_enabled
      Settings.solr_enabled
    end

    def self.solr_enabled= value
      Settings.solr_enabled = value
      if Settings.solr_enabled
        #start the solr server and reindex
        system ("rake solr:start RAILS_ENV=#{RAILS_ENV}")
        system ("rake solr:reindex RAILS_ENV=#{RAILS_ENV}")
      elsif Settings.solr_enabled == false
        #stop the solr server
        system ("rake solr:stop RAILS_ENV=#{RAILS_ENV}")
      end
    end

    def self.exception_notification_enabled
      Settings.exception_notification_enabled
    end

    def self.exception_notification_enabled= value
      Settings.exception_notification_enabled = value
      if Settings.exception_notification_enabled
        ExceptionNotifier.render_only            = false
        ExceptionNotifier.send_email_error_codes = %W( 400 406 403 405 410 500 501 503 )
        ExceptionNotifier.sender_address         = %w(no-reply@sysmo-db.org)
        ExceptionNotifier.email_prefix           = "[SEEK-#{RAILS_ENV.capitalize} ERROR] "
        ExceptionNotifier.exception_recipients   = %w(joe@example.com bill@example.com)
      else
        ExceptionNotifier.render_only = true
      end
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
    
    def self.tag_threshold
      Settings.tag_threshold.to_i
    end

    def self.tag_threshold= value
      Settings.tag_threshold = value
    end

    def self.max_visible_tags
      Settings.max_visible_tags.to_i
    end

    def self.max_visible_tags= value
      Settings.max_visible_tags = value
    end

    def self.smtp_settings field
      Settings.smtp_settings[field.to_sym]
    end

    def self.set_smtp_settings (field, value)
      Settings.merge! :smtp_settings, field.to_sym => value
      ActionMailer::Base.smtp_settings= {
          :address        => Settings.smtp_settings[:address],
          :port           => Settings.smtp_settings[:port],
          :domain         => Settings.smtp_settings[:domain],
          :authentication => Settings.smtp_settings[:authentication],
          :user_name      => Settings.smtp_settings[  :user_name],
          :password       => Settings.smtp_settings[:password]
      }
    end

    def self.open_id_authentication_store
      Settings.open_id_authentication_store
    end

    def self.open_id_authentication_store= value
      Settings.open_id_authentication_store = value
      OpenIdAuthentication.store            = Settings.open_id_authentication_store
    end

  end
end