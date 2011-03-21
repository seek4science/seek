require 'test_helper'

class ConfigTest < ActiveSupport::TestCase
#Features enabled
  test "events enabled" do
    assert_equal true ,Seek::Config.events_enabled
  end
  test "jerm_enabled" do
    assert_equal true ,Seek::Config.jerm_enabled
  end
  test "solr enabled" do
    assert_equal false ,Seek::Config.solr_enabled
  end
  test "email_enabled" do
    assert_equal false ,Seek::Config.email_enabled
  end
  test "smtp_settings port" do
    assert_equal 25 ,Seek::Config.smtp_settings("port").to_i
  end
  test "smtp_settings authentication" do
    assert_equal :plain ,Seek::Config.smtp_settings("authentication")
  end
  test "noreply_sender" do
    assert_equal "no-reply@sysmo-db.org" ,Seek::Config.noreply_sender
  end
  test "jws enabled" do
    assert_equal true ,Seek::Config.jws_enabled
  end
  test "exception_notification_enabled" do
    assert_equal false ,Seek::Config.exception_notification_enabled
  end
  test "hide_details_enabled" do
    assert_equal false ,Seek::Config.hide_details_enabled
  end
  test "activity_log_enabled" do
    assert_equal true ,Seek::Config.activity_log_enabled
  end
  test "activation_required_enabled" do
    assert_equal false ,Seek::Config.activation_required_enabled
  end
  test "google_analytics_enabled" do
    assert_equal false ,Seek::Config.google_analytics_enabled
  end
  test "google_analytics_tracker_id" do
    assert_equal '000-000' ,Seek::Config.google_analytics_tracker_id
  end
#Project
  test "project_name" do
    assert_equal "Sysmo" ,Seek::Config.project_name
  end
  test "project_type" do
    assert_equal "Consortium" ,Seek::Config.project_type
  end
    test "project_link" do
    assert_equal "http://www.sysmo.net",Seek::Config.project_link
  end
  test "project_long_name" do
    assert_equal "Sysmo Consortium" ,Seek::Config.project_long_name
  end
  test "project_title" do
    assert_equal "The Sysmo Consortium",Seek::Config.project_title
  end
  test "dm_project_name" do
    assert_equal "Sysmo-DB",Seek::Config.dm_project_name
  end
  test "dm_project_title" do
    assert_equal "The Sysmo Consortium",Seek::Config.dm_project_title
  end
  test "dm_project_link" do
    assert_equal "http://www.sysmo.net",Seek::Config.dm_project_link
  end
  test "application_name" do
    assert_equal "Sysmo SEEK",Seek::Config.application_name
  end
  test "application_title" do
    assert_equal "The Sysmo SEEK",Seek::Config.application_title
  end
  test "header_image_enabled" do
    assert_equal false,Seek::Config.header_image_enabled
  end
  test "header_image_link" do
      assert_equal "http://www.sysmo.net",Seek::Config.header_image_link
  end
  test "header_image_title" do
    assert_equal "Sysmo-DB",Seek::Config.header_image_title
  end
#pagination
  test "default page" do
    assert_equal "latest",Seek::Config.default_page("sops")
  end
  test "limit_latest" do
    assert_equal 7,Seek::Config.limit_latest
  end
#others
  test "type_managers" do
    assert_equal "admins",Seek::Config.type_managers
  end

  test "pubmed_api_email" do
    assert_equal nil,Seek::Config.pubmed_api_email
  end
  test "crossref_api_email" do
    assert_equal "sowen@cs.man.ac.uk",Seek::Config.crossref_api_email
  end
  test "site_base_host" do
    assert_equal "http://localhost:3000",Seek::Config.site_base_host
  end
  test "open_id_authentication_store" do
    assert_equal :memory,Seek::Config.open_id_authentication_store
  end
  test "copyright_addendum_enabled" do
    assert_equal false,Seek::Config.copyright_addendum_enabled
  end
  test "copyright_addendum_content" do
    assert_equal 'Additions copyright ...',Seek::Config.copyright_addendum_content
  end

  test "changing a setting" do
    Seek::Config.pubmed_api_email="fred@email.com"
    assert_equal "fred@email.com",Seek::Config.pubmed_api_email
  end

  test "invalid setting accessor" do
    assert_raises(NoMethodError) {Seek::Config.xxxxx}
    assert_raises(NoMethodError) {Seek::Config.xxxxx=true}
  end

end