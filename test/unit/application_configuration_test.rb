require 'test_helper'

class ApplicationConfigurationTest < ActiveSupport::TestCase
#Features enabled
  test "events enabled" do
    assert_equal true ,Seek::ApplicationConfiguration.get_events_enabled
  end
  test "jerm_enabled" do
    assert_equal true ,Seek::ApplicationConfiguration.get_jerm_enabled
  end
  test "solr enabled" do
    assert_equal false ,Seek::ApplicationConfiguration.get_solr_enabled
  end
  test "email_enabled" do
    assert_equal false ,Seek::ApplicationConfiguration.get_email_enabled
  end
  test "smtp_settings port" do
    assert_equal 25 ,Seek::ApplicationConfiguration.get_smtp_settings("port").to_i
  end
  test "smtp_settings authentication" do
    assert_equal :plain ,Seek::ApplicationConfiguration.get_smtp_settings("authentication")
  end
  test "noreply_sender" do
    assert_equal "no-reply@sysmo-db.org" ,Seek::ApplicationConfiguration.get_noreply_sender
  end
  test "jws enabled" do
    assert_equal true ,Seek::ApplicationConfiguration.get_jws_enabled
  end
  test "exception_notification_enabled" do
    assert_equal false ,Seek::ApplicationConfiguration.get_exception_notification_enabled
  end
  test "hide_details_enabled" do
    assert_equal false ,Seek::ApplicationConfiguration.get_hide_details_enabled
  end
  test "activity_log_enabled" do
    assert_equal true ,Seek::ApplicationConfiguration.get_activity_log_enabled
  end
  test "activation_required_enabled" do
    assert_equal false ,Seek::ApplicationConfiguration.get_activation_required_enabled
  end
  test "google_analytics_enabled" do
    assert_equal false ,Seek::ApplicationConfiguration.get_google_analytics_enabled
  end
  test "google_analytics_tracker_id" do
    assert_equal 'XX-XXXXXXX-X' ,Seek::ApplicationConfiguration.get_google_analytics_tracker_id
  end
#Project
  test "project_name" do
    assert_equal "Sysmo" ,Seek::ApplicationConfiguration.get_project_name
  end
  test "project_type" do
    assert_equal "Consortium" ,Seek::ApplicationConfiguration.get_project_type
  end
    test "project_link" do
    assert_equal "http://www.sysmo.net",Seek::ApplicationConfiguration.get_project_link
  end
=begin
  test "project_long_name" do
    assert_equal "Sysmo Consortium" ,Seek::ApplicationConfiguration.get_project_long_name
  end
=end
  test "project_title" do
    assert_equal "The Sysmo Consortium",Seek::ApplicationConfiguration.get_project_title
  end
  test "dm_project_name" do
    assert_equal "Sysmo-DB",Seek::ApplicationConfiguration.get_dm_project_name
  end
=begin
  test "dm_project_title" do
    assert_equal "The Sysmo Consortium",Seek::ApplicationConfiguration.get_dm_project_title
  end
=end
=begin
  test "dm_project_link" do
    assert_equal "http://www.sysmo.net",Seek::ApplicationConfiguration.get_dm_project_link
  end
=end
  test "application_name" do
    assert_equal "Sysmo SEEK",Seek::ApplicationConfiguration.get_application_name
  end
  test "application_title" do
    assert_equal "The Sysmo SEEK",Seek::ApplicationConfiguration.get_application_title
  end
  test "header_image_enabled" do
    assert_equal false,Seek::ApplicationConfiguration.get_header_image_enabled
  end
=begin
  test "header_image_link" do
    assert_equal "http://www.sysmo.net",Seek::ApplicationConfiguration.get_header_image_link
  end
=end
=begin
  test "header_image_title" do
    assert_equal "Sysmo-DB",Seek::ApplicationConfiguration.get_header_image_title
  end
=end
#pagination
  test "default page" do
    assert_equal "latest",Seek::ApplicationConfiguration.get_default_page("sops")
  end
  test "limit_latest" do
    assert_equal 7,Seek::ApplicationConfiguration.get_limit_latest
  end
#others
  test "type_managers" do
    assert_equal "admins",Seek::ApplicationConfiguration.get_type_managers
  end

  test "global_passphrase" do
    assert_equal "ohx0ipuk2baiXah",Seek::ApplicationConfiguration.get_global_passphrase
  end
  test "pubmed_api_email" do
    assert_equal nil,Seek::ApplicationConfiguration.get_pubmed_api_email
  end
  test "crossref_api_email" do
    assert_equal "sowen@cs.man.ac.uk",Seek::ApplicationConfiguration.get_crossref_api_email
  end
  test "site_base_host" do
    assert_equal "http://localhost:3000",Seek::ApplicationConfiguration.get_site_base_host
  end
  test "open_id_authentication_store" do
    assert_equal :memory,Seek::ApplicationConfiguration.get_open_id_authentication_store
  end
  test "asset_order" do
    assert_equal ['Person', 'Project', 'Institution', 'Investigation', 'Study', 'Assay', 'DataFile', 'Model', 'Sop', 'Publication', 'SavedSearch', 'Organism', 'Event'], Seek::ApplicationConfiguration.get_asset_order
  end
  test "copyright_addendum_enabled" do
    assert_equal false,Seek::ApplicationConfiguration.get_copyright_addendum_enabled
  end
  test "copyright_addendum_content" do
    assert_equal 'Additions copyright ...',Seek::ApplicationConfiguration.get_copyright_addendum_content
  end
end