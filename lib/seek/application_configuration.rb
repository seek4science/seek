module Seek
  class ApplicationConfiguration
#Features enabled
    def self.get_events_enabled
         Settings.events_enabled
    end
    def self.set_events_enabled value
         Settings.events_enabled = value
    end

    def self.get_jerm_enabled
         Settings.jerm_enabled
    end
    def self.set_jerm_enabled value
         Settings.jerm_enabled = value
    end

    def self.get_email_enabled
         Settings.email_enabled
    end
    def self.set_email_enabled value
          Settings.email_enabled = value
     end

    def self.get_noreply_sender
         Settings.noreply_sender
    end
    def self.set_noreply_sender value
         Settings.noreply_sender = value
    end

    def self.get_solr_enabled
         Settings.solr_enabled
    end
    def self.set_solr_enabled value
         Settings.solr_enabled = value
    end

    def self.get_jws_enabled
         Settings.jws_enabled
    end
    def self.set_jws_enabled value
         Settings.jws_enabled = value
    end

    def self.get_jws_online_root
         Settings.jws_online_root
    end
    def self.set_jws_online_root value
         Settings.jws_online_root = value
    end

    def self.get_exception_notification_enabled
         Settings.exception_notification_enabled
    end
    def self.set_exception_notification_enabled value
         Settings.exception_notification_enabled = value
    end

    def self.get_hide_details_enabled
         Settings.hide_details_enabled
    end
    def self.set_hide_details_enabled value
         Settings.hide_details_enabled = value
    end

    def self.get_activity_log_enabled
         Settings.activity_log_enabled
    end
    def self.set_activity_log_enabled value
         Settings.activity_log_enabled = value
    end

    def self.get_activation_required_enabled
         Settings.activation_required_enabled
    end
    def self.set_activation_required_enabled value
         Settings.activation_required_enabled = value
    end

    def self.get_google_analytics_enabled
         Settings.google_analytics_enabled
    end
    def self.set_google_analytics_enabled value
         Settings.google_analytics_enabled = value
    end

    def self.get_google_analytics_tracker_id
         Settings.google_analytics_tracker_id
    end
    def self.set_google_analytics_tracker_id value
         Settings.google_analytics_tracker_id = value
    end

#Project
    def self.get_project_name
         Settings.project_name
    end
    def self.set_project_name value
         Settings.project_name = value
    end

    def self.get_project_type
         Settings.project_type
    end
    def self.set_project_type value
         Settings.project_type = value
    end

    def self.get_project_link
         Settings.project_link
    end
    def self.set_project_link value
         Settings.project_link = value
    end

    def self.get_project_long_name
         Settings.project_long_name
    end
    def self.set_project_long_name value
         Settings.project_long_name = value
    end

    def self.get_project_title
         Settings.project_title
    end
    def self.set_project_title value
         Settings.project_title = value
    end
    def self.get_dm_project_name
         Settings.dm_project_name
    end
    def self.set_dm_project_name value
         Settings.dm_project_name = value
    end

    def self.get_dm_project_title
         Settings.dm_project_title
    end
    def self.set_dm_project_title value
         Settings.dm_project_title = value
    end

    def self.get_dm_project_link
         Settings.dm_project_link
    end
    def self.set_dm_project_link value
         Settings.dm_project_link = value
    end

    def self.get_application_name
         Settings.application_name
    end
    def self.set_application_name value
         Settings.application_name = value
    end

    def self.get_application_title
         Settings.application_title
    end
    def self.set_application_title value
         Settings.application_title = value
    end

    def self.get_header_image_enabled
         Settings.header_image_enabled
    end
    def self.set_header_image_enabled value
         Settings.header_image_enabled = value
    end

    def self.get_header_image_link
         Settings.header_image_link
    end
    def self.set_header_image_link value
         Settings.header_image_link = value
    end
    def self.get_header_image_title
         Settings.header_image_title
    end
    def self.set_header_image_title value
         Settings.header_image_title = value
    end

#Pagination
    def self.get_default_page controller
        Settings.index[controller.to_sym]
    end
    def self.set_default_page controller, value
        Settings.merge! :index, controller.to_sym => value
    end

    def self.get_limit_latest
        Settings.limit_latest
    end
    def self.set_limit_latest  value
        Settings.limit_latest = value
    end
#Others
    def self.get_type_managers_enabled
        Settings.type_managers_enabled
    end
    def self.set_type_managers_enabled  value
        Settings.type_managers_enabled = value
    end

    def self.get_type_managers
        Settings.type_managers
    end
    def self.set_type_managers  value
        Settings.type_managers = value
    end

    def self.get_tag_threshold
        Integer(Settings.tag_threshold)
    end
    def self.set_tag_threshold  value
        Settings.tag_threshold = value
    end

    def self.get_max_visible_tags
        Integer(Settings.max_visible_tags)
    end
    def self.set_max_visible_tags  value
        Settings.max_visible_tags = value
    end

    def self.get_global_passphrase
        Settings.global_passphrase
    end
    def self.set_global_passphrase  value
         Settings.global_passphrase = value
    end

    def self.get_pubmed_api_email
        Settings.pubmed_api_email
    end
    def self.set_pubmed_api_email  value
        Settings.pubmed_api_email = value
    end

    def self.get_crossref_api_email
        Settings.crossref_api_email
    end
    def self.set_crossref_api_email  value
        Settings.crossref_api_email = value
    end

    def self.get_site_base_host
        Settings.site_base_host
    end
    def self.set_site_base_host  value
        Settings.site_base_host = value
    end

    def self.get_smtp_settings field
        Settings.smtp_settings[field.to_sym]
    end
    def self.set_smtp_settings field, value
        Settings.merge! :smtp_settings, field.to_sym => value
    end

    def self.get_open_id_authentication_store
        Settings.open_id_authentication_store
    end
    def self.set_open_id_authentication_store  value
        Settings.open_id_authentication_store = value
    end

    def self.get_asset_order
        Settings.asset_order
    end
    def self.set_asset_order  value
        Settings.asset_order = value
    end

    def self.get_copyright_addendum_enabled
        Settings.copyright_addendum_enabled
    end
    def self.set_copyright_addendum_enabled  value
        Settings.copyright_addendum_enabled = value
    end

    def self.get_copyright_addendum_content
        Settings.copyright_addendum_content
    end
    def self.set_copyright_addendum_content  value
        Settings.copyright_addendum_content = value
    end
 end
end