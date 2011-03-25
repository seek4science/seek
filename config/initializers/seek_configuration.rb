require 'seek/config'

Seek::Config.default :events_enabled,true
Seek::Config.default :jerm_enabled,true
Seek::Config.default :test_enabled, false
Seek::Config.default :email_enabled,false
Seek::Config.default :smtp, {:address => '', :port => '25', :domain => '', :authentication => :plain, :user_name => '', :password => ''}
Seek::Config.default :noreply_sender, 'no-reply@sysmo-db.org'
Seek::Config.default :solr_enabled,false
Seek::Config.default :jws_enabled, true
Seek::Config.default :jws_online_root,"http://jjj.mib.ac.uk"
Seek::Config.default :exception_notification_enabled,false
Seek::Config.default :hide_details_enabled,false
Seek::Config.default :activity_log_enabled,true
Seek::Config.default :activation_required_enabled,false
Seek::Config.default :google_analytics_enabled, false
Seek::Config.default :google_analytics_tracker_id, '000-000'
Seek::Config.default :copyright_addendum_enabled,false
Seek::Config.default :copyright_addendum_content,'Additions copyright ...'
#
#  #Project
Seek::Config.default :project_name,'SysMO'
Seek::Config.default :project_type,'Consortium'
Seek::Config.default :project_link,'http://www.sysmo.net'
Seek::Config.default :header_image_enabled,false
Seek::Config.default :header_image,'sysmo-db-logo_smaller.png'
#
#  #Pagination
Seek::Config.default :default_pages,{:people => 'latest', :projects => 'latest', :institutions => 'latest', :investigations => 'latest',:studies => 'latest', :assays => 'latest', :data_files => 'latest', :models => 'latest',:sops => 'latest', :publications => 'latest',:events => 'latest'}
Seek::Config.default :limit_latest,7
#
#  #Others
Seek::Config.default :type_managers_enabled,true
Seek::Config.default :type_managers,'admins'
Seek::Config.default :tag_threshold,1
Seek::Config.default :max_visible_tags,20
Seek::Config.default :pubmed_api_email,nil
Seek::Config.default :crossref_api_email,nil
Seek::Config.default :site_base_host,"http://localhost:3000"
Seek::Config.default :open_id_authentication_store,:memory

GLOBAL_PASSPHRASE="ohx0ipuk2baiXah"
Seek::Config.propagate_all