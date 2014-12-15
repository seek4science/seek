require 'simple_crypt'

module Seek
  # Fallback attribute, which if defined will be the result if the stored/default value for a setting is nil
  # Convention to create a new fallback is to name the method <setting_name>_fallback
  module Fallbacks
    # fallback attributes
    def project_long_name_fallback
      "#{project_name} #{project_type}"
    end

    def project_title_fallback
      project_long_name
    end

    def dm_project_name_fallback
      project_name
    end

    def dm_project_title_fallback
      project_title
    end

    def dm_project_link_fallback
      project_link
    end

    def application_name_fallback
      "#{project_name} SEEK"
    end

    def application_title_fallback
      application_name_fallback
    end

    def header_image_link_fallback
      dm_project_link
    end

    def header_image_title_fallback
      dm_project_name
    end
  end

  # Propagator methods that are triggered after a setting is changed.
  # Convention for creating a new propagator is to add a method named <setting_name>_propagate
  module Propagators
    def site_base_host_propagate
      script_name = (SEEK::Application.config.relative_url_root || '/')
      ActionMailer::Base.default_url_options = { host: site_base_host.gsub(/https?:\/\//, '').gsub(/\/$/, ''),
						                                           script_name: script_name }
    end

    def smtp_propagate
      smtp_hash = smtp

      password =  smtp_settings 'password'
      smtp_hash.merge! 'password' => password

      new_hash = {}
      smtp_hash.keys.each do |key|
        new_hash[key.to_sym] = smtp_hash[key]
      end

      ActionMailer::Base.smtp_settings = new_hash
    end

    def bioportal_api_key_propagate
      affected = ActiveRecord::Base.descendants.select do |cl|
        cl.respond_to?(:bioportal_api_key=)
      end
      affected.each do |cl|
        cl.bioportal_api_key = bioportal_api_key
      end
    end

    def google_analytics_enabled_propagate
      if google_analytics_enabled
        GA.tracker = google_analytics_tracker_id
      else
        GA.tracker = '000-000'
      end
    end

    def application_title_propagate
      # required to update error message title
      exception_notification_enabled_propagate
    end

    def piwik_analytics_enabled_propagate
      if piwik_analytics_enabled
        PiwikAnalytics.configuration.id_site = piwik_analytics_id_site
        PiwikAnalytics.configuration.url = piwik_analytics_url
        PiwikAnalytics.configuration.use_async = true
        PiwikAnalytics.configuration.disabled = false
      else
        PiwikAnalytics.configuration.disabled = true
      end
    end

    def exception_notification_recipients_propagate
      configure_exception_notification
    end

    def exception_notification_enabled_propagate
      configure_exception_notification
    end

    def recaptcha_private_key_propagate
      configure_recaptcha_keys
    end

    def recaptcha_public_key_propagate
      configure_recaptcha_keys
    end

    def configure_recaptcha_keys
      Recaptcha.configure do |config|
        config.public_key  = recaptcha_public_key
        config.private_key = recaptcha_private_key
      end
    end

    def configure_exception_notification
      if exception_notification_enabled && !Rails.application.config.consider_all_requests_local
        SEEK::Application.config.middleware.use ExceptionNotification::Rack,
          email: {
            sender_address: [noreply_sender],
            email_prefix: "[ #{application_title} ERROR ] ",
            exception_recipients: exception_notification_recipients.nil? ? [] : exception_notification_recipients.split(%r{[, ]})
          }
      else
        SEEK::Application.config.middleware.delete ExceptionNotifier
      end
    end

    def open_id_authentication_store_propagate
      OpenIdAuthentication.store = open_id_authentication_store.to_sym
    end

    def solr_enabled_propagate
      # for now do nothing.
    end

    def pubmed_api_email_propagate
      Bio::NCBI.default_email = "(#{pubmed_api_email})"
    end

    def propagate_all
      prop_methods = methods.select { |m| m.to_s.end_with?('_propagate') }
      prop_methods.each do |m|
        eval m.to_s
      end
    end
  end

  # Custom accessors for settings that are not a simple mapping
  module CustomAccessors
    include SimpleCrypt

    def recaptcha_setup?
      if Seek::Config.recaptcha_enabled
        if Seek::Config.recaptcha_public_key.blank? || Seek::Config.recaptcha_private_key.blank?
          fail Exception.new('Recaptcha is enabled, but public and private key are not set')
          false
        else
          true
        end
      else
        false
      end
    end

    def rdf_filestore_path
      append_filestore_path 'rdf'
    end

    def temporary_filestore_path
      append_filestore_path 'tmp'
    end

    def converted_filestore_path
      File.join(temporary_filestore_path, 'converted')
    end

    def asset_filestore_path
      append_filestore_path 'assets'
    end

    def avatar_filestore_path
      append_filestore_path 'avatars'
    end

    def model_image_filestore_path
      append_filestore_path 'model_images'
    end

    def append_filestore_path(inner_dir)
      path = filestore_path
      unless path.start_with? '/'
        path = File.join(Rails.root, path)
      end
      File.join(path, inner_dir)
    end

    def smtp_settings(field)
      value = smtp[field.to_sym]
      if field == :password || field == 'password'
        value=decrypt_value(value)
      end
      value
    end

    def set_smtp_settings(field, value)
      if [:password, :user_name, :authentication].include? field.to_sym
        if value.blank?
          value = nil
        end
      end

      if field.to_sym == :authentication and value
        value = value.to_sym
      end
      if field.to_sym == :password
        unless value.blank?
          value = encrypt(value, generate_key(GLOBAL_PASSPHRASE))
        end
      end
      merge! :smtp, field => value
      value
    end

    def datacite_password_decrypt
      datacite_password = Seek::Config.datacite_password
      decrypt_value(datacite_password)
    end

    def decrypt_value(value)
      unless value.blank?
        begin
          decrypt(value, generate_key(GLOBAL_PASSPHRASE))
        rescue => exception
          Rails.logger.error 'ERROR decrypting value - reverting to a blank string'
          ''
        end
      end
    end

    def datacite_password_encrypt(password)
      unless password.blank?
        Seek::Config.datacite_password = encrypt(password, generate_key(GLOBAL_PASSPHRASE))
      end
      datacite_password
    end

    def facet_enable_for_page(controller)
      facet_enable_for_pages[controller.to_sym]
    end

    def default_page(controller)
      default_pages[controller.to_sym]
    end

    # FIXME: change to standard setter=
    def set_default_page(controller, value)
      merge! :default_pages, controller => value
      value
    end
  end

  # The inner wiring. Ideally this should be hidden away,
  module Wiring
    def default(setting, value)
      Settings.defaults[setting] = value
    end

    # unlike default, always sets the value
    def fixed(setting, value)
      setter = "#{setting}="
      set_value setter, value
    end

    def define_class_method(method , *args, &block)
      singleton_class.instance_eval { define_method method.to_sym, *args, &block }
    end

    if Settings.table_exists?
      def get_value(getter, conversion = nil)
        val = Settings.send getter
        val = val.send(conversion) if conversion && val
        val
      end

      def set_value(setter, val, conversion = nil)
        val = val.send(conversion) if conversion && val
        Settings.send setter, val
      end
    else
      def get_value(getter, conversion = nil)
        val = Settings.defaults[getter.to_sym]
        val = val.send(conversion) if conversion && val
        val
      end

      def set_value(setter, val, conversion = nil)
        val = val.send(conversion) if conversion && val
        Settings.defaults[setter.to_sym] = val
      end
    end

    def merge!(var, value)
      result = Settings.merge! var, value
      send "#{var}_propagate" if self.respond_to? "#{var}_propagate"
      result
    end

    def setting(setting, options = {})
      setter = "#{setting}="
      getter = "#{setting}"
      propagate = "#{getter}_propagate"
      fallback = "#{getter}_fallback"
      if self.respond_to?(fallback)
        define_class_method getter do
          get_value(getter, options[:convert]) || send(fallback)
        end
      else
        define_class_method getter do
          get_value(getter, options[:convert])
        end
      end

      define_class_method setter do |val|
        set_value(setter, val, options[:convert])
        send propagate if self.respond_to?(propagate)
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

    # reads the available attributes from config_setting_attributes.yml
    def self.read_setting_attributes
      yaml = YAML.load_file(File.join(File.dirname(File.expand_path(__FILE__)), 'config_setting_attributes.yml'))
      yaml.keys.map { |k| k.to_sym }
    end


    # Settings that require a conversion to integer
    setting :tag_threshold, convert: 'to_i'
    setting :limit_latest, convert: 'to_i'
    setting :max_visible_tags, convert: 'to_i'
    setting :piwik_analytics_id_site, convert: 'to_i'
    setting :project_news_number_of_entries, convert: 'to_i'
    setting :community_news_number_of_entries, convert: 'to_i'
    setting :home_feeds_cache_timeout, convert: 'to_i'
    setting :time_lock_doi_for, convert: 'to_ig'

    read_setting_attributes.each do |sym|
      setting sym
    end
  end
end
