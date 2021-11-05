module Seek
  # Fallback attribute, which if defined will be the result if the stored/default value for a setting is nil
  # Convention to create a new fallback is to name the method <setting_name>_fallback
  module Fallbacks
    # fallback attributes
    def project_long_name_fallback
      if project_type.blank?
        project_name.to_s
      else
        "#{project_name} #{project_type}"
      end
    end

    def dm_project_name_fallback
      project_name
    end
    
    def dm_project_link_fallback
      project_link
    end

    def application_name_fallback
      "#{project_name} SEEK"
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
      ActionMailer::Base.default_url_options = { host: host_with_port,
                                                 protocol: host_scheme,
                                                 script_name: script_name }
    end

    def smtp_propagate
      smtp_hash = smtp

      password =  smtp_settings 'password'
      smtp_hash['password'] = password

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
      GA.tracker = if google_analytics_enabled
                     google_analytics_tracker_id
                   else
                     '000-000'
                   end
    end

    def application_name_propagate
      # required to update error message title
      exception_notification_enabled_propagate
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
        config.site_key = recaptcha_public_key
        config.secret_key = recaptcha_private_key
      end
    end

    def configure_exception_notification
      if exception_notification_enabled && Rails.env.production?
        SEEK::Application.config.middleware.use ExceptionNotification::Rack,
                                                email: {
                                                  sender_address: [noreply_sender],
                                                  email_prefix: "[ #{application_name} ERROR ] ",
                                                  exception_recipients: exception_notification_recipients.nil? ? [] : exception_notification_recipients.split(/[, ]/)
                                                }
      else
        SEEK::Application.config.middleware.delete ExceptionNotifier
      end
    rescue RuntimeError => e
      Rails.logger.warn('Cannot update middleware with exception notification changes, server needs restarting')
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
    def recaptcha_setup?
      if Seek::Config.recaptcha_enabled
        if Seek::Config.recaptcha_public_key.blank? || Seek::Config.recaptcha_private_key.blank?
          raise Exception, 'Recaptcha is enabled, but public and private key are not set'
          false
        else
          true
        end
      else
        false
      end
    end

    def attr_encrypted_key_path
      dir = append_filestore_path 'attr_encrypted'
      File.join(dir, 'key')
    end

    def secret_key_base_path
      dir = append_filestore_path 'secret_key_base'
      File.join(dir, 'key')
    end

    def attr_encrypted_key
      if File.exist?(attr_encrypted_key_path)
        File.binread(attr_encrypted_key_path)[0..31]
      else
        write_attr_encrypted_key
        attr_encrypted_key
      end
    end

    def secret_key_base
      if File.exist?(secret_key_base_path)
        File.read(secret_key_base_path)
      else
        write_secret_key_base
        secret_key_base
      end
    end

    def rdf_filestore_path
      append_filestore_path 'rdf'
    end

    def temporary_filestore_path
      append_filestore_path 'tmp'
    end

    def clear_temporary_filestore
      FileUtils.rm_r(temporary_filestore_path)
    end

    def converted_filestore_path
      append_filestore_path 'converted-assets'
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

    def rebranding_filestore_path
      append_filestore_path 'rebranding'
    end

    def append_filestore_path(inner_dir)
      path = filestore_path
      path = File.join(Rails.root, path) unless path.start_with? '/'
      check_path_exists(File.join(path, inner_dir))
    end

    def check_path_exists(path)
      FileUtils.mkdir_p path unless File.exist?(path)
      path
    end

    def smtp_settings(field)
      smtp.with_indifferent_access[field.to_s]
    end

    def set_smtp_settings(field, value)
      merge! :smtp, field => (value.blank? ? nil : value)
      value
    end

    def facet_enable_for_page(controller)
      facet_enable_for_pages.with_indifferent_access[controller.to_s]
    end

    def sorting_for(controller)
      hash = sorting.with_indifferent_access
      hash[controller.to_s]&.to_sym
    end

    def set_sorting_for(controller, value)
      # Store value as a string, unless nil, or not a valid sorting option for that controller.
      if value.blank? || !Seek::ListSorter.options(controller.to_s.classify).include?(value.to_sym)
        value = nil
      else
        value = value.to_s
      end
      merge!(:sorting, controller.to_s => value)
      value&.to_sym
    end

    def results_per_page_for(controller)
      hash = results_per_page.with_indifferent_access
      hash[controller.to_s]
    end

    def set_results_per_page_for(controller, value)
      merge!(:results_per_page, controller.to_s => value.blank? ? nil : value.to_i)
      value
    end

    def host_with_port
      base_uri = URI(Seek::Config.site_base_host)
      host = base_uri.host
      unless (base_uri.port == 80 && base_uri.scheme == 'http') ||
             (base_uri.port == 443 && base_uri.scheme == 'https')
        host << ":#{base_uri.port}"
      end
      host
    end

    def host_scheme
      URI(Seek::Config.site_base_host).scheme
    end

    def write_attr_encrypted_key
      File.open(attr_encrypted_key_path, 'wb') do |f|
        f << SecureRandom.random_bytes(32)
      end
    end

    def write_secret_key_base
      File.open(secret_key_base_path, 'w') do |f|
        f << SecureRandom.hex(64)
      end
    end

    def soffice_available?(cached=false)
      @@soffice_available = nil unless cached
      begin
        port = ConvertOffice::ConvertOfficeConfig.options[:soffice_port]
        soc = TCPSocket.new('localhost', port)
        soc.close
        true
      rescue
        false
      end
    end

    def studies_enabled
      isa_enabled
    end

    def investigations_enabled
      isa_enabled
    end

    def assays_enabled
      isa_enabled
    end

    def omniauth_elixir_aai_config
      callback_path = '/identities/auth/elixir_aai/callback'

      {
          callback_path: callback_path,
          name: :elixir_aai,
          scope: [:openid, :email],
          response_type: 'code',
          issuer: 'https://login.elixir-czech.org/oidc/',
          discovery: false,
          send_nonce: true,
          client_signing_alg: :RS256,
          # The following is obtained from: https://login.elixir-czech.org/oidc/jwk
          client_jwk_signing_key: '{"keys":[{"kty":"RSA","e":"AQAB","kid":"rsa1","alg":"RS256","n":"uVHPfUHVEzpgOnDNi3e2pVsbK1hsINsTy_1mMT7sxDyP-1eQSjzYsGSUJ3GHq9LhiVndpwV8y7Enjdj0purywtwk_D8z9IIN36RJAh1yhFfbyhLPEZlCDdzxas5Dku9k0GrxQuV6i30Mid8OgRQ2q3pmsks414Afy6xugC6u3inyjLzLPrhR0oRPTGdNMXJbGw4sVTjnh5AzTgX-GrQWBHSjI7rMTcvqbbl7M8OOhE3MQ_gfVLXwmwSIoKHODC0RO-XnVhqd7Qf0teS1JiILKYLl5FS_7Uy2ClVrAYd2T6X9DIr_JlpRkwSD899pq6PR9nhKguipJE0qUXxamdY9nw"}]}',
          client_options: {
              identifier: omniauth_elixir_aai_client_id,
              secret: omniauth_elixir_aai_secret,
              redirect_uri: "#{site_base_host.chomp('/')}#{callback_path}",
              scheme: 'https',
              host: 'login.elixir-czech.org',
              port: 443,
              authorization_endpoint: '/oidc/authorize',
              token_endpoint: '/oidc/token',
              userinfo_endpoint: '/oidc/userinfo',
              jwks_uri: '/oidc/jwk',
          }
      }
    end

    def omniauth_ldap_settings(field)
      omniauth_ldap_config.with_indifferent_access[field.to_s]
    end

    def set_omniauth_ldap_settings(field, value)
      merge! :omniauth_ldap_config, field => (value.blank? ? nil : value)
      value
    end

    def omniauth_github_config
      [omniauth_github_client_id, omniauth_github_secret, { scope: 'user:email' }]
    end

    def omniauth_providers
      providers = {}
      providers[:ldap] = omniauth_ldap_config.merge(name: :ldap, form: SessionsController.action(:new)) if omniauth_ldap_enabled
      providers[:openid_connect] = omniauth_elixir_aai_config if omniauth_elixir_aai_enabled
      providers[:github] = omniauth_github_config if omniauth_github_enabled
      providers
    end
  end

  # The inner wiring. Ideally this should be hidden away,
  module Wiring
    def default(setting, value)
      Settings.defaults[setting] = value
    end

    # unlike default, always sets the value
    def fixed(setting, value)
      set_value(setting, value)
    end

    def define_class_method(method, *args, &block)
      singleton_class.instance_eval { define_method method.to_sym, *args, &block }
    end

    def get_default_value(setting, conversion = nil)
      val = Settings.defaults[setting.to_sym]
      val = val.send(conversion) if conversion && val
      val
    end

    use_db = begin
      Settings.table_exists?
    rescue StandardError
      false
    end

    if use_db
      def get_value(setting, conversion = nil)
        result = Settings.global.fetch(setting)
        if result
          val = result.value
        else
          val = Settings.defaults[setting.to_s]
        end
        val = val.send(conversion) if conversion && val
        val
      end

      def set_value(setting, val, conversion = nil)
        val = val.send(conversion) if conversion && val
        Settings.global[setting] = val
      end
    else
      def get_value(setting, conversion = nil)
        get_default_value(setting, conversion)
      end

      def set_value(setting, val, conversion = nil)
        val = val.send(conversion) if conversion && val
        Settings.defaults[setting.to_sym] = val
      end
    end

    def merge!(var, value)
      # Initialize the hash from defaults if it does not exist yet in settings
      Settings.global[var] = Settings.defaults[var.to_s] unless Settings.global.fetch(var)
      result = Settings.merge!(var, value)
      send "#{var}_propagate" if respond_to? "#{var}_propagate"
      result
    end

    def setting(setting, options = {})
      options ||= {}
      setter = "#{setting}="
      getter = setting.to_s
      propagate = "#{getter}_propagate"
      fallback = "#{getter}_fallback"
      default = "default_#{setting}"
      if respond_to?(fallback)
        define_class_method getter do
          get_value(setting, options[:convert]) || send(fallback)
        end
      else
        define_class_method getter do
          get_value(setting, options[:convert])
        end
      end

      define_class_method default do
        get_default_value(setting, options[:convert])
      end

      define_class_method setter do |val|
        set_value(setting, val, options[:convert])
        send propagate if respond_to?(propagate)
      end
    end

    def register_encrypted_setting(setting)
      encrypted_settings << setting.to_sym
    end

    def encrypted_settings
      @@encrypted_settings ||= []
    end

    def encrypted_setting?(setting)
      encrypted_settings.include?(setting.to_sym)
    end
  end

  # Configuration class.
  # FIXME: move to the top, but without moving the Fallback, Propagators and CustomAccessors into another file.
  class Config
    extend Wiring
    extend Fallbacks
    extend Propagators
    extend CustomAccessors

    PERMISSION_POPUP_ALWAYS = 0
    PERMISSION_POPUP_ON_CHANGE = 1
    PERMISSION_POPUP_NEVER = 2

    # reads the available attributes from config_setting_attributes.yml
    def self.read_setting_attributes
      yaml = YAML.load_file(File.join(File.dirname(File.expand_path(__FILE__)), 'config_setting_attributes.yml'))
      HashWithIndifferentAccess.new(yaml)
    end

    def self.read_project_setting_attributes
      yaml = YAML.load_file(File.join(File.dirname(File.expand_path(__FILE__)), 'project_setting_attributes.yml'))
      HashWithIndifferentAccess.new(yaml)
    end

    read_setting_attributes.each do |method, opts|
      setting method, opts
      register_encrypted_setting(method) if opts && opts[:encrypt]
    end

    read_project_setting_attributes.each do |method, opts|
      register_encrypted_setting(method) if opts && opts[:encrypt]
    end

    def self.schema_org_supported?
      true
    end
  end
end
