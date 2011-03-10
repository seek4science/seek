require 'settings'
require 'authorization'
require 'save_without_timestamping'
require 'asset'
require 'calendar_date_select'
require 'active_record_extensions'

#Features enabled
  Settings.defaults[:events_enabled] = true
  Settings.defaults[:jerm_enabled] = true
  Settings.defaults[:test_enabled] = false
  Settings.defaults[:email_enabled] = false
  Settings.defaults[:smtp_settings] = {:address => '', :port => '25', :domain => '', :authentication  => :plain, :user_name => '', :password => ''}
  Settings.defaults[:noreply_sender] = 'no-reply@sysmo-db.org'  
  Settings.defaults[:solr_enabled] = false
  Settings.defaults[:jws_enabled] = true
  Settings.defaults[:jws_online_root] = "http://jjj.mib.ac.uk"
  Settings.defaults[:exception_notification_enabled] = false
  Settings.defaults[:hide_details_enabled] = false
  Settings.defaults[:activity_log_enabled] = true
  Settings.defaults[:activation_required_enabled] = false
  Settings.defaults[:google_analytics_enabled] = false
  Settings.defaults[:google_analytics_tracker_id] = 'XX-XXXXXXX-X'
  Settings.defaults[:copyright_addendum_enabled] = false
  Settings.defaults[:copyright_addendum_content] = 'Additions copyright ...'

  #Mailer settings
  ActionMailer::Base.smtp_settings= {
    :address => Settings.defaults[:smtp_settings][:address],
    :port => Settings.defaults[:smtp_settings][:port],
    :domain => Settings.defaults[:smtp_settings][:domain],
    :authentication => Settings.defaults[:smtp_settings][:authentication],
    :user_name => Settings.defaults[:smtp_settings][:user_name],
    :password  => Settings.defaults[:smtp_settings][:password]
  }
  if Settings.defaults[:google_analytics_enabled]
    Rubaidh::GoogleAnalytics.tracker_id = Settings.defaults[:google_analytics_tracker_id]
  else
    Rubaidh::GoogleAnalytics.tracker_id = "000-000"
  end


  if Settings.defaults[:exception_notification_enabled]
    ExceptionNotifier.render_only = false
    ExceptionNotifier.send_email_error_codes = %W( 400 406 403 405 410 500 501 503 )
    ExceptionNotifier.sender_address = %w(no-reply@sysmo-db.org)
    ExceptionNotifier.email_prefix = "[SEEK-#{RAILS_ENV.capitalize} ERROR] "
    ExceptionNotifier.exception_recipients = %w(joe@example.com bill@example.com)
  else
    ExceptionNotifier.render_only = true
  end


#Project
  Settings.defaults[:project_name] = 'SysMO'
  Settings.defaults[:project_type] = 'Consortium'
  Settings.defaults[:project_link] = 'http://www.sysmo.net'
  Settings.defaults[:header_image_enabled] = false
  Settings.defaults[:header_image] = 'sysmo-db-logo_smaller.png'


#Pagination
  Settings.defaults[:index] = {:people => 'latest', :projects => 'latest', :institutions => 'latest', :investigations => 'latest',:studies => 'latest', :assays => 'latest',
                    :data_files => 'latest', :models => 'latest',:sops => 'latest', :publications => 'latest',:events => 'latest'}
  Settings.defaults[:limit_latest] = 7

#Others

  Settings.defaults[:type_managers_enabled] = true  
  Settings.defaults[:type_managers] = 'admins'
  Settings.defaults[:tag_threshold] = 1
  Settings.defaults[:max_visible_tags] = 20
  Settings.defaults[:pubmed_api_email] = nil
  Settings.defaults[:crossref_api_email] = nil
  Settings.defaults[:site_base_host] = "http://localhost:3000"
  Settings.defaults[:open_id_authentication_store] = :memory

  OpenIdAuthentication.store = Settings.defaults[:open_id_authentication_store]
