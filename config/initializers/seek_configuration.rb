Seek::Config.defaults {
  #Features enabled
  events_enabled true
  jerm_enabled true
  test_enabled false
  email_enabled false
  smtp :address => '', :port => '25', :domain => '', :authentication => :plain, :user_name => '', :password => ''
  noreply_sender 'no-reply@sysmo-db.org'
  solr_enabled false
  jws_enabled true
  jws_online_root "http://jjj.mib.ac.uk"
  exception_notification_enabled false
  hide_details_enabled false
  activity_log_enabled true
  activation_required_enabled false
  google_analytics_enabled false
  google_analytics_tracker_id '000-000'
  copyright_addendum_enabled false
  copyright_addendum_content 'Additions copyright ...'

  #Project
  project_name 'SysMO'
  project_type 'Consortium'
  project_link 'http://www.sysmo.net'
  header_image_enabled false
  header_image 'sysmo-db-logo_smaller.png'
    
  #Pagination
  default_pages :people => 'latest', :projects => 'latest', :institutions => 'latest', :investigations => 'latest',:studies => 'latest', :assays => 'latest', :data_files => 'latest', :models => 'latest',:sops => 'latest', :publications => 'latest',:events => 'latest'
  limit_latest 7

  #Others
  type_managers_enabled true
  type_managers 'admins'
  tag_threshold 1
  max_visible_tags 20
  pubmed_api_email nil
  crossref_api_email nil
  site_base_host "http://localhost:3000"
  open_id_authentication_store :memory
}
Seek::Config.propagate_all