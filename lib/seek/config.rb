module Seek
  class Config

    def self.define_class_method method ,*args, &block
      singleton_class.instance_eval { define_method method.to_sym, *args, &block }
    end

    if Settings.table_exists?
      def self.get_value getter
        Settings.send getter
      end
    else
      def self.get_value getter
        Settings.defaults[getter.to_sym]
      end
    end

    def self.setting setting,options={}
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

    settings = [:events_enabled, :jerm_enabled, :test_enabled, :email_enabled, :no_reply, :jws_enabled,
      :jws_online_root, :hide_details_enabled, :activity_log_enabled,
      :activation_required_enabled, :project_name, :smtp,
      :project_type, :project_link, :header_image_enabled, :header_image,
      :type_managers_enabled, :type_managers, :pubmed_api_email, :crossref_api_email,
      :site_base_host, :copyright_addendum_enabled, :copyright_addendum_content, :noreply_sender, :limit_latest, :solr_enabled,
      :application_name,:application_title,:project_long_name,:project_title,:dm_project_name,:dm_project_title,:dm_project_link,:application_title,:header_image_link,:header_image_title,
      :header_image_enabled,:header_image_link,:header_image_title,:google_analytics_enabled,:google_analytics_tracker_id,:exception_notification_enabled,:open_id_authentication_store]

    setting :tag_threshold,:convert=>"to_i"
    setting :limit_latest,:convert=>"to_i"
    setting :max_visible_tags,:convert=>"to_i"

    def self.default setting,value
      Settings.defaults[setting]=value
    end

    #fallback attributes
    def self.project_long_name_fallback
      "#{self.project_name} #{self.project_type}"
    end

    def self.project_title_fallback
      self.project_long_name
    end

    def self.dm_project_name_fallback
      self.project_name
    end

    def self.dm_project_title_fallback
      self.project_title
    end

    def self.dm_project_link_fallback
      self.project_link
    end

    def self.application_name_fallback
      "#{self.project_name} SEEK"
    end

    def self.application_title_fallback
      self.application_name_fallback
    end

    def self.header_image_link_fallback
      self.dm_project_link
    end

    def self.header_image_title_fallback
      self.dm_project_name
    end

    def self.smtp_settings field
      self.smtp[field.to_sym]
    end

    def self.set_smtp_settings (field, value)
      self.smtp[field]=value
    end

    #propagate methods
    def self.google_analytics_enabled_propagate
      if self.google_analytics_enabled
          Rubaidh::GoogleAnalytics.tracker_id = self.google_analytics_tracker_id
      else
          Rubaidh::GoogleAnalytics.tracker_id = "000-000"
      end
    end

    def self.exception_notification_enabled_propagate
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




    settings.each do |sym|
      setting sym
    end

    def self.default_page controller
      Settings.index[controller.to_sym]
    end
    
    def self.set_default_page (controller, value)
      Settings.merge! :index, controller.to_sym => value
    end

    def self.propagate_all
      prop_methods=self.methods.select{|m| m.end_with?("_propagate")}
      prop_methods.each do |m|
        eval m
      end
    end
    
  end

end



#
#
#    @@settings = []
#    def self.setting setting, options={}, &side_effect
#      @@settings << setting
#
#      side_effect ||= options[:side_effect]
#      setting_propagator setting, options[:plugin], options[:plugin_setting], &side_effect
#
#      #default can either be a callable (proc) or a symbol referring to a method, like another setting
#      default = options[:default].respond_to?(:call) ? options[:default] : proc {self.send options[:default]} if options[:default]
#      setting_reader setting, &default
#
#      setting_writer setting, &options[:conversion]
#    end
#
#    def self.defaults &block
#      me = self
#
#      #old_self is used for anything that is not a setting
#      old_self = eval "self", block.binding
#      rewriter = Class.new do
#        @@me = me
#        @@old_self = old_self
#        def self.method_missing method, *args, &other_block
#          new_method = "#{method}_default="
#          if @@me.respond_to? new_method
#            @@me.send new_method, *args, &other_block
#          else
#            @@old_self.send method, *args, &other_block
#          end
#        end
#      end
#      rewriter.instance_exec &block
#    end
#
#    def self.propagate_all in_initializer=true
#      @@initializing = true if in_initializer
#      @@settings.each {|setting| self.send "propagate_#{setting}" if self.respond_to? "propagate_#{setting}"}
#      @@initializing = false
#    end
#
#    def self.initializing?
#      @@initializing
#    end
#
#    @@initializing=false
#
#    def self.persist_settings?
#      Settings.table_exists?
#    end
#
#    private
#    #These three methods aren't really intended to be used seperately, see SettingManager#setting
#    def self.setting_propagator setting, plugin=nil, plugin_setting=nil, &side_effect
#      if plugin or side_effect
#        define_class_method "propagate_#{setting}" do
#          if plugin
#            plugin_setting ||= setting
#            value = self.send(setting)
#            plugin.send "#{plugin_setting}=", value
#          end
#          if side_effect
#            side_effect.call self.send(setting)
#          end
#        end
#      end
#    end
#
#    def self.setting_reader setting, &default
#      #if the settings can't be stored, look them up in the defaults instead
#      if persist_settings?
#        define_class_method setting do
#          unless value = Settings.send(setting)
#            value = default.call if default
#          end
#          value
#        end
#      else
#        define_class_method setting do
#          unless value = Settings.defaults[setting]
#            value = default.call if default
#          end
#          value
#        end
#      end
#    end
#
#    def self.setting_writer setting, &conversion
#      define_class_method "#{setting}_default=" do |value|
#        value = conversion.call value if conversion
#        Settings.defaults[setting] = value
#        value
#      end
#
#      if persist_settings?
#        define_class_method "#{setting}=" do |value|
#          value = conversion.call value if conversion
#          Settings.send "#{setting}=", value
#          self.send "propagate_#{setting}" if self.respond_to? "propagate_#{setting}"
#          value
#        end
#      else
#        define_class_method "#{setting}=" do |value|
#          raise "You can't store Settings, perhaps the settings table is missing in your database?"
#        end
#      end
#    end
#
#
#  end
#
#  class Config < SettingManager
#    #settings that require simple accessors.
#    simple_settings = [:events_enabled, :jerm_enabled, :test_enabled, :email_enabled, :no_reply, :jws_enabled,
#      :jws_online_root, :hide_details_enabled, :activity_log_enabled,
#      :activation_required_enabled, :project_name,
#      :project_type, :project_link, :header_image_enabled, :header_image,
#      :type_managers_enabled, :type_managers, :pubmed_api_email, :crossref_api_email,
#      :site_base_host, :copyright_addendum_enabled, :copyright_addendum_content, :noreply_sender, :limit_latest]
#
##    # setting creates three or four methods per setting, and adds it to the list of settings. For simple settings they look like this.
##    if persist_settings? # <-checks if the db/tables exist for storing settings
##      def self.events_enabled
##        Settings.events_enabled
##      end
##      def self.events_enabled= value
##        Settings.events_enabled= value
##      end
##    else
##      def self.events_enabled
##        Settings.defaults[:events_enabled]
##      end
##      def self.events_enabled= value
##        raise "You can't store Settings, perhaps the settings table is missing in your database?"
##      end
##    end
##
##    def self.events_enabled_default= value
##      Settings.defaults[:events_enabled]= value
##    end
##
##    # And then I add it to the list of all settings. Right now this
##    # is only used by propagate_all, so if you skipped this it would
##    # still work, but I'd do it anyway, just in case a list of all
##    # settings is ever useful.
##    @@settings << :events_enabled
##
##    # If this was all the setting method did, then you could define it like so..
##    def self.setting name
##      @@settings << name
##      if persist_settings?
##        define_class_method name do
##          Settings.send name
##        end
##        define_class_method "#{name}=" do |value|
##          Settings.send "#{name}=", value
##        end
##      else
##        define_class_method name do
##          Settings.defaults[name]
##        end
##        define_class_method "#{name}=" do |value|
##          raise "You can't store Settings, perhaps the settings table is missing in your database?"
##        end
##      end
##      define_class_method "#{name}_default=" do |value|
##        Settings.defaults[name] = value
##      end
##    end
#
#    # Its more complicated than this because there are a bunch of special cases,
#    # for side_effect's, conversion's, storing values into plugins, and 'calculated defaults' (like how if project_title = nil, it uses project_long_name instead)
#
#    simple_settings.each do |sym|
#      setting sym
#    end
#
#    setting :solr_enabled, :side_effect => proc { |enabled|
#      if enabled
#        #start the solr server and reindex
#        system "rake solr:start RAILS_ENV=#{RAILS_ENV}"
#        system "rake solr:reindex RAILS_ENV=#{RAILS_ENV}" unless initializing?
#      elsif enabled == false
#        #stop the solr server
#        system "rake solr:stop RAILS_ENV=#{RAILS_ENV}"
#      end
#    }
#
##    # Writing solr_enabled by hand would look like this
##    if persist_settings? # <-checks if the db/tables exist for storing settings
##      def self.solr_enabled
##        Settings.solr_enabled
##      end
##      def self.solr_enabled= value
##        Settings.solr_enabled= value
##        propagate_solr_enabled
##      end
##    else
##      def self.solr_enabled
##        Settings.defaults[:solr_enabled]
##      end
##      def self.solr_enabled= value
##        raise "You can't store Settings, perhaps the settings table is missing in your database?"
##      end
##    end
##
##    def self.solr_enabled_default= value
##      Settings.defaults[:solr_enabled]= value
##    end
##
##    def self.propagate_solr_enabled
##      if solr_enabled
##        # start the solr server and reindex
##        system "rake solr:start RAILS_ENV=#{RAILS_ENV}"
##        system "rake solr:reindex RAILS_ENV=#{RAILS_ENV}" unless initializing?
##      elsif solr_enabled == false
##        # stop the solr server
##        system "rake solr:stop RAILS_ENV=#{RAILS_ENV}"
##      end
##    end
##    @@settings << :solr_enabled
#
#
#    # Ok, I'm going to stop with the real examples now, though I can add them if wanted.
#    # :conversion is something called on the value passed to setting before it is stored.
#    #
#    # :plugin and :plugin_setting are a more specific version of side effect, for when
#    # the side effect is just passing the value into some other place.
#    #
#    # :default is called to produce a default to use if Settings returns nil, it can also
#    # accept the name of another setting.
#    #
#    # The really important point, is that if you want to do something that the library doesn't support,
#    # you don't neccessarily need to change the library. Lets say you want to store your default somewhere other than Settings.defaults[].
##
##    setting :my_setting_with_weird_defaults, :side_effect => ..some sort of side effect ..
##
##    def self.my_setting_with_weird_defaults_default= value
##      OtherPlaceToStore.defaults.weird_default = value
##    end
##
##    def self.my_setting_with_weird_defaults_default
##      OtherPlaceToStore.defaults.weird_default
##    end
##
#    # Of course, if you end up needing to change where _all_ the defaults live, it would be easier to edit the library, but you don't _need_ to.
#
#    setting :exception_notification_enabled, :side_effect => proc { |enabled|
#      if enabled
#        ExceptionNotifier.render_only            = false
#        ExceptionNotifier.send_email_error_codes = %W( 400 406 403 405 410 500 501 503 )
#        ExceptionNotifier.sender_address         = %w(no-reply@sysmo-db.org)
#        ExceptionNotifier.email_prefix           = "[SEEK-#{RAILS_ENV.capitalize} ERROR] "
#        ExceptionNotifier.exception_recipients   = %w(joe@example.com bill@example.com)
#      else
#        ExceptionNotifier.render_only = true
#      end
#    }
#
#    setting :google_analytics_tracker_id, :plugin => Rubaidh::GoogleAnalytics, :plugin_setting => :tracker_id, :conversion => proc {|id| id.blank? ? 'XX-XXXXXXX-X' : id}
#    setting :google_analytics_enabled, :plugin => Rubaidh::GoogleAnalytics, :plugin_setting => :enabled
#
#    setting :project_long_name, :default => proc {"#{project_name} #{project_type}"}
#    setting :project_title, :default => :project_long_name
#    setting :dm_project_name, :default => :project_name
#    setting :dm_project_title, :default => :project_title
#    setting :dm_project_link, :default => :project_link
#    setting :application_name, :default => proc {"#{project_name}-SEEK"}
#    setting :application_title, :default => :application_name
#    setting :header_image_link, :default => :dm_project_link
#    setting :header_image_title, :default => :dm_project_name
#
#    setting :tag_threshold, :conversion => (method :Integer)
#    setting :max_visible_tags, :conversion => (method :Integer)
#    setting :smtp, :plugin => ActionMailer::Base, :plugin_setting => :smtp_settings, :conversion => proc { |smtp_hash|
#      smtp_hash[:authentication] = blank_to_nil (smtp_hash[:authentication])
#    }
#    setting :open_id_authentication_store, :plugin => OpenIdAuthentication, :plugin_setting => :store
#    setting :default_pages
#
#    #Pagination
#    def self.default_page controller
#      self.default_pages[controller.to_sym]
#    end
#
#    def self.set_default_page (controller, value)
#      self.default_pages = self.default_pages.merge controller.to_sym => value
#    end
#
#    def self.smtp_settings field
#      smtp[field.to_sym]
#    end
#
#    def self.set_smtp_settings (field, value)
#      self.smtp = smtp.merge field.to_sym => value
#    end
#
#    def self.blank_to_nil value
#      value.blank? ? nil : value
#    end
#  end
#end
# 
#
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