module Seek
  class SettingDefaulter
    @manager = nil
    def initialize manager
      @manager = manager
    end

    def method_missing method, *args
      @manager.send "#{method}_default=", *args
    end
  end

  class SettingManager
    @@settings = []
    def self.setting setting, options={}, &block
      @@settings << setting
      side_effect = block || options[:side_effect]
      default = options[:default].respond_to?(:call) ? options[:default] : proc {self.send options[:default]} if options[:default]
      setting_reader setting, &default
      setting_writer setting, options[:plugin], options[:plugin_setting], options[:conversion], &side_effect
    end

    def self.defaults &block
      SettingDefaulter.new(self).instance_exec &block
    end
    
    def self.propagate_all in_initializer=true
      @@initializing = true if in_initializer
      @@settings.each {|setting| self.send "propagate_#{setting}"}
      @@initializing = false
    end

    def self.initializing?
      @@initializing
    end

    @@initializing=false

    def self.define_class_method method ,*args, &block
      singleton_class.instance_eval { define_method method.to_sym, *args, &block }
    end

    def self.persist_settings?
      Settings.table_exists?
    end

    def self.setting_reader setting, &block
      if persist_settings?
        define_class_method setting do
          unless value = Settings.send(setting)
            value = block.call if block
          end
          value
        end
      else
        define_class_method setting do
          Settings.defaults[setting] || block.try(:call)
        end
      end
    end

    def self.setting_writer setting, plugin=nil, plugin_setting=nil, conversion=nil, &block
      define_class_method "propagate_#{setting}" do
        if plugin
          plugin_setting ||= setting
          value = self.send(setting)
          plugin.send "#{plugin_setting}=", value
        end
        if block
          block.call self.send(setting)
        end
      end

      define_class_method "#{setting}_default=" do |value|
        value = conversion.call value if conversion
        Settings.defaults[setting] = value
        value
      end

      if persist_settings?
        define_class_method "#{setting}=" do |value|
          value = conversion.call value if conversion
          Settings.send "#{setting}=", value
          self.send "propagate_#{setting}"
          value
        end
      else
        define_class_method "#{setting}=" do |value|
          raise "You can't store Settings, perhaps the settings table is missing in your database?"
        end
      end
    end
  end

  class Config < SettingManager
    #settings that require simple accessors.
    simple_settings = [:events_enabled, :jerm_enabled, :test_enabled, :email_enabled, :no_reply, :jws_enabled,
                       :jws_online_root, :hide_details_enabled, :activity_log_enabled,
                       :activation_required_enabled, :project_name,
                       :project_type, :project_link, :header_image_enabled, :header_image,
                       :type_managers_enabled, :type_managers, :pubmed_api_email, :crossref_api_email,
                       :site_base_host, :copyright_addendum_enabled, :copyright_addendum_content, :noreply_sender, :limit_latest]

    simple_settings.each do |sym|
      setting sym
    end

    setting :solr_enabled, :side_effect => proc { |enabled|
      if enabled
        #start the solr server and reindex
        system "rake solr:start RAILS_ENV=#{RAILS_ENV}"
        system "rake solr:reindex RAILS_ENV=#{RAILS_ENV}" unless initializing?
      elsif enabled == false
        #stop the solr server
        system "rake solr:stop RAILS_ENV=#{RAILS_ENV}"
      end
    }

    setting :exception_notification_enabled, :side_effect => proc { |enabled|
      if enabled
        ExceptionNotifier.render_only            = false
        ExceptionNotifier.send_email_error_codes = %W( 400 406 403 405 410 500 501 503 )
        ExceptionNotifier.sender_address         = %w(no-reply@sysmo-db.org)
        ExceptionNotifier.email_prefix           = "[SEEK-#{RAILS_ENV.capitalize} ERROR] "
        ExceptionNotifier.exception_recipients   = %w(joe@example.com bill@example.com)
      else
        ExceptionNotifier.render_only = true
      end
    }

    setting :google_analytics_tracker_id, :plugin => Rubaidh::GoogleAnalytics, :plugin_setting => :tracker_id, :conversion => proc {|id| id.blank? ? 'XX-XXXXXXX-X' : id}
    setting :google_analytics_enabled, :plugin => Rubaidh::GoogleAnalytics, :plugin_setting => :enabled

    setting :project_long_name, :default => proc {"#{project_name} #{project_type}"}
    setting :project_title, :default => :project_long_name
    setting :dm_project_name, :default => :project_name
    setting :dm_project_title, :default => :project_title
    setting :dm_project_link, :default => :project_link
    setting :application_name, :default => proc {"#{project_name}-SEEK"}
    setting :application_title, :default => :application_name
    setting :header_image_link, :default => :dm_project_link
    setting :header_image_title, :default => :dm_project_name

    setting :tag_threshold, :conversion => (method :Integer)
    setting :max_visible_tags, :conversion => (method :Integer)
    setting :smtp, :plugin => ActionMailer::Base, :plugin_setting => :smtp_settings
    setting :open_id_authentication_store, :plugin => OpenIdAuthentication, :plugin_setting => :store
    setting :default_pages

#Pagination
    def self.default_page controller
      self.default_pages[controller.to_sym]
    end

    def self.set_default_page (controller, value)
      self.default_pages = self.default_pages.merge controller.to_sym => value
    end

    def self.smtp_settings field
      smtp[field.to_sym]
    end

    def self.set_smtp_settings (field, value)
      self.smtp = smtp.merge field.to_sym => value
    end
  end
end


#Adding methods to enable/disable Google Analytics
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