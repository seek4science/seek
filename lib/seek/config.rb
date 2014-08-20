require 'simple_crypt'


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

    def site_base_host_propagate
      ActionMailer::Base.default_url_options = { :host => self.site_base_host.gsub(/https?:\/\//, '').gsub(/\/$/,'') }
    end

    def smtp_propagate
      smtp_hash = self.smtp

      password =  self.smtp_settings 'password'
      smtp_hash.merge! "password" => password

      new_hash = {}
      smtp_hash.keys.each do |key|
        new_hash[key.to_sym]=smtp_hash[key]
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

      if self.google_analytics_enabled
        GA.tracker= self.google_analytics_tracker_id
      else
        GA.tracker= "000-000"
      end
    end

    def application_title_propagate
      #required to update error message title
      exception_notification_enabled_propagate
    end

    def piwik_analytics_enabled_propagate
      if self.piwik_analytics_enabled
          PiwikAnalytics::configuration.id_site = self.piwik_analytics_id_site
          PiwikAnalytics::configuration.url = self.piwik_analytics_url
          PiwikAnalytics::configuration.use_async = true
          PiwikAnalytics::configuration.disabled=false
      else
        PiwikAnalytics::configuration.disabled=true
      end
    end

    def exception_notification_recipients_propagate
      configure_exception_notification
    end

    def exception_notification_enabled_propagate
      configure_exception_notification
    end

    def configure_exception_notification
      if exception_notification_enabled && !Rails.application.config.consider_all_requests_local
        SEEK::Application.config.middleware.use ExceptionNotification::Rack,
          :email=>{
            :sender_address         => [self.noreply_sender],
            :email_prefix           => "[ #{self.application_title} ERROR ] ",
            :exception_recipients   => self.exception_notification_recipients.nil? ? [] : self.exception_notification_recipients.split(%r([, ]))
          }
      else
        SEEK::Application.config.middleware.delete ExceptionNotifier
      end

    end

    def open_id_authentication_store_propagate
      OpenIdAuthentication.store = self.open_id_authentication_store.to_sym
    end

    def solr_enabled_propagate
      #for now do nothing.
    end

    def pubmed_api_email_propagate
      Bio::NCBI.default_email = "(#{self.pubmed_api_email})"
    end

    def propagate_all
      prop_methods=self.methods.select{|m| m.to_s.end_with?("_propagate")}
      prop_methods.each do |m|
        eval m.to_s
      end
    end

  end

  #Custom accessors for settings that are not a simple mapping
  module CustomAccessors
    include SimpleCrypt

    def rdf_filestore_path
      append_filestore_path "rdf"
    end
    def temporary_filestore_path
      append_filestore_path "tmp"
    end

    def converted_filestore_path
      File.join(temporary_filestore_path,"converted")
    end

    def asset_filestore_path
      append_filestore_path "assets"
    end

    def avatar_filestore_path
      append_filestore_path "avatars"
    end

    def model_image_filestore_path
      append_filestore_path "model_images"
    end

    def append_filestore_path inner_dir
      path = filestore_path
      unless path.start_with? "/"
        path = File.join(Rails.root,path)
      end
      File.join(path,inner_dir)
    end

    def smtp_settings field
      value = self.smtp[field.to_sym]
      if field == :password || field == 'password'
        if !value.blank?
          begin
            value = decrypt(value,generate_key(GLOBAL_PASSPHRASE))
          rescue Exception=>e
            value=""
            Rails.logger.error "ERROR DETERIMINING THE SMTP EMAIL PASSWORD - USING BLANK"
          end
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

    def facet_enable_for_page controller
      self.facet_enable_for_pages[controller.to_sym]
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

    #forced default is equivalent to default, it is only used to differentiate variables NOT able to be reset by admins with SEEK UI.
    # i.e. these variables are always set with values in seek configuration file.
    alias_method :forced_default, :default

    #unlike default, always sets the value
    def fixed setting,value
      setter="#{setting.to_s}="
      set_value setter,value
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
      def set_value setter, val, conversion=nil
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
    settings = [:home_description, :home_feeds_cache_timeout,:public_seek_enabled, :events_enabled, :bioportal_api_key, :jerm_enabled, :email_enabled, :no_reply, :jws_enabled,
      :jws_online_root, :hide_details_enabled, :activation_required_enabled, :project_name, :smtp, :default_pages, :project_type, :project_link, :header_image_enabled, :header_image,
      :type_managers_enabled, :type_managers, :pubmed_api_email, :crossref_api_email,:site_base_host, :copyright_addendum_enabled, :copyright_addendum_content, :noreply_sender, :solr_enabled,
      :application_name,:application_title,:project_long_name,:project_title,:dm_project_name,:dm_project_title,:dm_project_link,:application_title,:header_image_link,:header_image_title,
      :header_image_enabled,:header_image_link,:header_image_title,:google_analytics_enabled,
      :google_analytics_tracker_id,:piwik_analytics_url, :exception_notification_enabled,:exception_notification_recipients,:open_id_authentication_store, :sycamore_enabled,
      :project_news_enabled,:project_news_feed_urls,:community_news_enabled,:community_news_feed_urls,:is_virtualliver, :sabiork_ws_base_url,:filestore_path,
      :tagline_prefix,
      :biosamples_enabled,:events_enabled,:modelling_analysis_enabled,:organisms_enabled,:models_enabled,:forum_enabled,:jerm_enabled,:email_enabled,:jws_enabled,:external_search_enabled,:piwik_analytics_enabled,
      :seek_video_link, :scales, :delete_asset_version_enabled, :recaptcha_enabled, :project_hierarchy_enabled,#putting vl settings on their own line to simplify merges
      :admin_impersonation_enabled, :auth_lookup_enabled, :sample_parent_term,:specimen_culture_starting_date,:sample_age,:specimen_creators, :sample_parser_enabled,
      :publish_button_enabled,:project_browser_enabled, :experimental_features_enabled, :pdf_conversion_enabled,:admin_impersonation_enabled, :auth_lookup_enabled,
      :sample_parser_enabled,:guide_box_enabled,:treatments_enabled, :factors_studied_enabled,:experimental_conditions_enabled,:documentation_enabled,:tagging_enabled,
      :authorization_checks_enabled,:magic_guest_enabled,:workflows_enabled,:programmes_enabled,
      :assay_type_ontology_file,:technology_type_ontology_file,:modelling_analysis_type_ontology_file,:assay_type_base_uri,:technology_type_base_uri,:modelling_analysis_type_base_uri,
      :header_tagline_text_enabled,:header_home_logo_image,:related_items_limit,:faceted_browsing_enabled,:facet_enable_for_pages,:faceted_search_enabled,:is_one_facet_instance,
      :css_appended, :css_prepended, :javascript_appended,:javascript_prepended,:main_layout,:profile_select_by_default]


    #Settings that require a conversion to integer
    setting :tag_threshold,:convert=>"to_i"
    setting :limit_latest,:convert=>"to_i"
    setting :max_visible_tags,:convert=>"to_i"
    setting :piwik_analytics_id_site, :convert=>"to_i"
    setting :project_news_number_of_entries, :convert=>'to_i'
    setting :community_news_number_of_entries, :convert=>'to_i'
    setting :home_feeds_cache_timeout, :convert=>"to_i"

    settings.each do |sym|
      setting sym
    end
  end

end
