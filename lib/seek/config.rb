module Seek

  # Fallback attribute, which if defined will be the result if the stored/default value for a setting is nil
  # Convention to create a new fallback is to name the method <setting_name>_fallback
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

  # Propagator methods that are triggered after a setting is changed.
  # Convention for creating a new propagator is to add a method named <setting_name>_propagate
  module Propagators

    def smtp_propagate
      smtp_hash = self.smtp
      password =  self.smtp_settings 'password'
      smtp_hash.merge! :password => password
      ActionMailer::Base.smtp_settings = smtp_hash
    end

    def google_analytics_enabled_propagate
      Rubaidh::GoogleAnalytics.enabled = self.google_analytics_enabled
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
        ExceptionNotifier.exception_recipients   = self.exception_notification_recipients.split %r([, ])
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
    include SimpleCrypt

    def smtp_settings field
      value = self.smtp[field.to_sym]
      if field == :password || field == 'password'
        if !value.blank?
          value = decrypt(value,generate_key(GLOBAL_PASSPHRASE))
        end
      end
      value
    end

    def set_smtp_settings (field, value)
      if [:password, :user_name, :authentication].include? field.to_sym
        if value.blank?
          value = nil
        end
      end

      if field.to_sym == :authentication and value
        value = value.to_sym
      end
      if field.to_sym == :password
        if !value.blank?
          value = encrypt(value,generate_key(GLOBAL_PASSPHRASE))
        end
      end
      merge! :smtp, {field => value}
      value
    end

    def default_page controller
      self.default_pages[controller.to_sym]
    end

    #FIXME: change to standard setter=
    def set_default_page (controller, value)
      merge! :default_pages, {controller => value}
      value
    end

  end

  #The inner wiring. Ideally this should be hidden away,
  module Wiring

    def default setting,value
      Settings.defaults[setting]=value
    end

    def define_class_method method ,*args, &block
      singleton_class.instance_eval { define_method method.to_sym, *args, &block }
    end

    if Settings.table_exists?
      def get_value getter,conversion=nil
        val = Settings.send getter
        val = val.send(conversion) if conversion && val
        val
      end
      def set_value setter, val, conversion=nil
        val = val.send(conversion) if conversion && val
        Settings.send setter, val
      end
    else
      def get_value getter,conversion=nil
        val = Settings.defaults[getter.to_sym]
        val = val.send(conversion) if conversion && val
        val
      end
      def set_value setter, val
        val = val.send(conversion) if conversion && val
        Settings.defaults[setter.to_sym] = val
      end
    end

    def merge! var, value
      result = Settings.merge! var, value
      self.send "#{var}_propagate" if self.respond_to? "#{var}_propagate"
      result
    end

    def setting setting,options={}
      setter="#{setting.to_s}="
      getter="#{setting.to_s}"
      propagate="#{getter}_propagate"
      fallback="#{getter}_fallback"
      if self.respond_to?(fallback)
        define_class_method getter do
          get_value(getter,options[:convert]) || self.send(fallback)
        end
      else
        define_class_method getter do
           get_value(getter,options[:convert])
        end
      end

      define_class_method setter do |val|
        set_value(setter,val,options[:convert])
        self.send propagate if self.respond_to?(propagate)
      end
    end
  end

  # Configuration class.
  # FIXME: move to the top, but without moving the Fallback, Propagators and CustomAccessors into another file.
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
      :site_base_host, :copyright_addendum_enabled, :copyright_addendum_content, :noreply_sender, :solr_enabled,
      :application_name,:application_title,:project_long_name,:project_title,:dm_project_name,:dm_project_title,:dm_project_link,:application_title,:header_image_link,:header_image_title,
      :header_image_enabled,:header_image_link,:header_image_title,:google_analytics_enabled,
      :google_analytics_tracker_id,:exception_notification_enabled,:exception_notification_recipients,:open_id_authentication_store, :sycamore_enabled]

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