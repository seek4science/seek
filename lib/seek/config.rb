module Seek

  module Wiring

    def default setting,value
      Settings.defaults[setting]=value
    end

    def define_class_method method ,*args, &block
      singleton_class.instance_eval { define_method method.to_sym, *args, &block }
    end

    if Settings.table_exists?
      def get_value getter
        Settings.send getter
      end
    else
      def get_value getter
        Settings.defaults[getter.to_sym]
      end
    end

    def setting setting,options={}
      setter="#{setting.to_s}="
      getter="#{setting.to_s}"
      propagate="#{setter}_propagate"
      fallback="#{getter}_fallback"
      if self.respond_to?(fallback)
        define_class_method getter do
          Settings.send(getter) || self.send(fallback)
        end
      else
        if options[:convert]
          conv=options[:convert]
          define_class_method getter do
            get_value(getter).send conv
          end
        else
          define_class_method getter do
            get_value(getter)
          end
        end
      end

      define_class_method setter do |val|
        Settings.send setter,val
        self.send propagate if self.respond_to?(propagate)
      end
    end
  end

  #Fallback attribute, which if defined will be the result if the stored/default value for a setting is nil
  #Convention to create a new fallback is to name the method <setting_name>_fallback
  module Fallbacks
    #fallback attributes
    def project_long_name_fallback
      "#{self.project_name} #{self.project_type}"
    end

    def project_title_fallback
      self.project_long_name
    end

    def dm_project_name_fallback
      self.project_name
    end

    def dm_project_title_fallback
      self.project_title
    end

    def dm_project_link_fallback
      self.project_link
    end

    def application_name_fallback
      "#{self.project_name} SEEK"
    end

    def application_title_fallback
      self.application_name_fallback
    end

    def header_image_link_fallback
      self.dm_project_link
    end

    def header_image_title_fallback
      self.dm_project_name
    end
  end

  #Propagator methods that are triggered when a setting is changed.
  #Convention for creating a new propagator is to add a method named <setting_name>_propagate
  module Propagators

    def google_analytics_enabled_propagate
      if self.google_analytics_enabled
          Rubaidh::GoogleAnalytics.tracker_id = self.google_analytics_tracker_id
      else
          Rubaidh::GoogleAnalytics.tracker_id = "000-000"
      end
    end

    def exception_notification_enabled_propagate
      if self.exception_notification_enabled
        ExceptionNotifier.render_only            = false
        ExceptionNotifier.send_email_error_codes = %W( 400 406 403 405 410 500 501 503 )
        ExceptionNotifier.sender_address         = %w(no-reply@sysmo-db.org)
        ExceptionNotifier.email_prefix           = "[SEEK-#{RAILS_ENV.capitalize} ERROR] "
        ExceptionNotifier.exception_recipients   = %w(joe@example.com bill@example.com)
      else
        ExceptionNotifier.render_only = true
      end
    end

    def open_id_authentication_store_propagate
      OpenIdAuthentication.store = self.open_id_authentication_store
    end

    def solr_enabled_propagate
      #for now do nothing.
    end

    def propagate_all
      prop_methods=self.methods.select{|m| m.end_with?("_propagate")}
      prop_methods.each do |m|
        eval m
      end
    end

  end

  #Custom accessors for settings that are not a simple mapping
  module CustomAccessors

    def smtp_settings field
      self.smtp[field.to_sym]
    end

    def set_smtp_settings (field, value)
      self.smtp[field]=value
    end

    def default_page controller
      self.default_pages[controller.to_sym]
    end

    #FIXME: change to standard setter=
    def set_default_page (controller, value)
      self.default_pages[controller.to_sym] = value
    end

  end

  class Config
    extend Wiring
    extend Fallbacks
    extend Propagators
    extend CustomAccessors

    #Basic settings
    settings = [:events_enabled, :jerm_enabled, :test_enabled, :email_enabled, :no_reply, :jws_enabled,
      :jws_online_root, :hide_details_enabled, :activity_log_enabled,
      :activation_required_enabled, :project_name, :smtp, :default_pages,
      :project_type, :project_link, :header_image_enabled, :header_image,
      :type_managers_enabled, :type_managers, :pubmed_api_email, :crossref_api_email,
      :site_base_host, :copyright_addendum_enabled, :copyright_addendum_content, :noreply_sender, :limit_latest, :solr_enabled,
      :application_name,:application_title,:project_long_name,:project_title,:dm_project_name,:dm_project_title,:dm_project_link,:application_title,:header_image_link,:header_image_title,
      :header_image_enabled,:header_image_link,:header_image_title,:google_analytics_enabled,
      :google_analytics_tracker_id,:exception_notification_enabled,:open_id_authentication_store]

    #Settings that require a conversion to integer
    setting :tag_threshold,:convert=>"to_i"
    setting :limit_latest,:convert=>"to_i"
    setting :max_visible_tags,:convert=>"to_i"

    settings.each do |sym|
      setting sym
    end
  end

end

module Rubaidh
  class GoogleAnalytics
    def self.enabled= enabled
      if enabled
        enable
      else
        disable
      end
    end

    def self.enable
      @@environments = ['production']
    end

    def self.disable
      @@environments = []
    end
  end
end