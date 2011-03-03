require 'test_helper'

class ApplicationConfigurationTest < ActiveSupport::TestCase
#Features enabled
  test "events enabled" do
    assert_equal true ,Seek::ApplicationConfiguration.events_enabled
  end
  test "jerm_enabled" do
    assert_equal true ,Seek::ApplicationConfiguration.jerm_enabled
  end
  test "solr enabled" do
    assert_equal false ,Seek::ApplicationConfiguration.solr_enabled
  end
  test "email_enabled" do
    assert_equal false ,Seek::ApplicationConfiguration.email_enabled
  end
  test "smtp_settings port" do
    assert_equal 25 ,Seek::ApplicationConfiguration.smtp_settings("port").to_i
  end
  test "smtp_settings authentication" do
    assert_equal :plain ,Seek::ApplicationConfiguration.smtp_settings("authentication")
  end
  test "noreply_sender" do
    assert_equal "no-reply@sysmo-db.org" ,Seek::ApplicationConfiguration.noreply_sender
  end
  test "jws enabled" do
    assert_equal true ,Seek::ApplicationConfiguration.jws_enabled
  end
  test "exception_notification_enabled" do
    assert_equal false ,Seek::ApplicationConfiguration.exception_notification_enabled
  end
  test "hide_details_enabled" do
    assert_equal false ,Seek::ApplicationConfiguration.hide_details_enabled
  end
  test "activity_log_enabled" do
    assert_equal true ,Seek::ApplicationConfiguration.activity_log_enabled
  end
  test "activation_required_enabled" do
    assert_equal false ,Seek::ApplicationConfiguration.activation_required_enabled
  end
  test "google_analytics_enabled" do
    assert_equal false ,Seek::ApplicationConfiguration.google_analytics_enabled
  end
  test "google_analytics_tracker_id" do
    assert_equal 'XX-XXXXXXX-X' ,Seek::ApplicationConfiguration.google_analytics_tracker_id
  end
#Project
  test "project_name" do
    assert_equal "Sysmo" ,Seek::ApplicationConfiguration.project_name
  end
  test "project_type" do
    assert_equal "Consortium" ,Seek::ApplicationConfiguration.project_type
  end
    test "project_link" do
    assert_equal "http://www.sysmo.net",Seek::ApplicationConfiguration.project_link
  end
  test "project_long_name" do
    assert_equal "Sysmo Consortium" ,Seek::ApplicationConfiguration.project_long_name
  end
  test "project_title" do
    assert_equal "The Sysmo Consortium",Seek::ApplicationConfiguration.project_title
  end
  test "dm_project_name" do
    assert_equal "Sysmo-DB",Seek::ApplicationConfiguration.dm_project_name
  end
  test "dm_project_title" do
    assert_equal "The Sysmo Consortium",Seek::ApplicationConfiguration.dm_project_title
  end
  test "dm_project_link" do
    assert_equal "http://www.sysmo.net",Seek::ApplicationConfiguration.dm_project_link
  end
  test "application_name" do
    assert_equal "Sysmo SEEK",Seek::ApplicationConfiguration.application_name
  end
  test "application_title" do
    assert_equal "The Sysmo SEEK",Seek::ApplicationConfiguration.application_title
  end
  test "header_image_enabled" do
    assert_equal false,Seek::ApplicationConfiguration.header_image_enabled
  end
=begin
  test "header_image_link" do
      assert_equal "http://www.sysmo.net",Seek::ApplicationConfiguration.header_image_link
  end
=end
  test "header_image_title" do
    assert_equal "Sysmo-DB",Seek::ApplicationConfiguration.header_image_title
  end
#pagination
  test "default page" do
    assert_equal "latest",Seek::ApplicationConfiguration.default_page("sops")
  end
  test "limit_latest" do
    assert_equal 7,Seek::ApplicationConfiguration.limit_latest
  end
#others
  test "type_managers" do
    assert_equal "admins",Seek::ApplicationConfiguration.type_managers
  end

  test "global_passphrase" do
    assert_equal "ohx0ipuk2baiXah",Seek::ApplicationConfiguration.global_passphrase
  end
  test "pubmed_api_email" do
    assert_equal nil,Seek::ApplicationConfiguration.pubmed_api_email
  end
  test "crossref_api_email" do
    assert_equal "sowen@cs.man.ac.uk",Seek::ApplicationConfiguration.crossref_api_email
  end
  test "site_base_host" do
    assert_equal "http://localhost:3000",Seek::ApplicationConfiguration.site_base_host
  end
  test "open_id_authentication_store" do
    assert_equal :memory,Seek::ApplicationConfiguration.open_id_authentication_store
  end
  test "asset_order" do
    assert_equal ['Person', 'Project', 'Institution', 'Investigation', 'Study', 'Assay', 'DataFile', 'Model', 'Sop', 'Publication', 'SavedSearch', 'Organism', 'Event'], Seek::ApplicationConfiguration.asset_order
  end
  test "copyright_addendum_enabled" do
    assert_equal false,Seek::ApplicationConfiguration.copyright_addendum_enabled
  end
  test "copyright_addendum_content" do
    assert_equal 'Additions copyright ...',Seek::ApplicationConfiguration.copyright_addendum_content
  end
end