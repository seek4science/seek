require 'test_helper'

class ConfigTest < ActiveSupport::TestCase
  # Features enabled
  test 'public seek enabled' do
    assert_equal true, Seek::Config.public_seek_enabled
  end

  test 'events enabled' do
    assert_equal true, Seek::Config.events_enabled
  end
  test 'jerm_disabled' do
    assert_equal false, Seek::Config.jerm_enabled
  end
  test 'solr enabled' do
    assert_equal true, Seek::Config.solr_enabled
  end

  test 'is_virtualliver' do
    with_config_value 'is_virtualliver', true do
      assert Seek::Config.is_virtualliver
    end
  end

  test "read setting attributes" do
    attributes = Seek::Config.read_setting_attributes
    refute attributes.empty?
    assert_include attributes,:events_enabled
  end

  test 'project_hierarchy_enabled' do
    with_config_value 'project_hierarchy_enabled', true do
      assert_equal true, Seek::Config.project_hierarchy_enabled
    end
  end

  test 'recaptcha setup?' do
    with_config_value :recaptcha_enabled, true do
      with_config_value :recaptcha_public_key, 'sdfsdf' do
        with_config_value :recaptcha_private_key, 'sdfsdf' do
          assert Seek::Config.recaptcha_setup?
        end
        with_config_value :recaptcha_private_key, '' do
          assert_raises(Exception) do
            Seek::Config.recaptcha_setup?
          end
        end
      end
    end
    with_config_value :recaptcha_enabled, false do
      with_config_value :recaptcha_private_key, '' do
        refute Seek::Config.recaptcha_setup?
      end
    end
  end

  test 'scales' do
    assert_equal %w(organism liver liverLobule intercellular cell), Seek::Config.scales
  end

  test 'seek_video_link' do
    assert_equal 'http://www.youtube.com/user/elinawetschHITS?feature=mhee#p/u', Seek::Config.seek_video_link
  end

  test 'external search' do
    with_config_value :external_search_enabled, true do
      assert Seek::Config.external_search_enabled
    end

    with_config_value :external_search_enabled, false do
      assert !Seek::Config.external_search_enabled
    end

  end

  test 'blacklisted feeds' do
    Seek::Config.blacklisted_feeds = { 'http://google.com' => Time.parse('1 Sep 2014'), 'http://fish.com' => Time.parse('1 June 2014') }
    assert_equal Time.parse('1 Sep 2014'), Seek::Config.blacklisted_feeds['http://google.com']
    assert_equal Time.parse('1 June 2014'), Seek::Config.blacklisted_feeds['http://fish.com']
  end

  test 'filestore_location' do
    cb = Factory :content_blob

    assert_equal 'tmp/testing-filestore', Seek::Config.filestore_path
    assert_equal "#{Rails.root}/tmp/testing-filestore/assets", Seek::Config.asset_filestore_path
    assert_equal "#{Rails.root}/tmp/testing-filestore/model_images", Seek::Config.model_image_filestore_path
    assert_equal "#{Rails.root}/tmp/testing-filestore/avatars", Seek::Config.avatar_filestore_path
    assert_equal "#{Rails.root}/tmp/testing-filestore/rdf", Seek::Config.rdf_filestore_path

    assert_equal "#{Rails.root}/tmp/testing-filestore/assets/#{cb.uuid}.dat", cb.filepath
    assert_equal "#{Rails.root}/tmp/testing-filestore/model_images", ModelImage.image_directory
    assert_equal "#{Rails.root}/tmp/testing-filestore/model_images/original", ModelImage.original_path

    assert_equal "#{Rails.root}/tmp/testing-filestore/tmp", Seek::Config.temporary_filestore_path
    assert_equal "#{Rails.root}/tmp/testing-filestore/tmp/converted", Seek::Config.converted_filestore_path

    assert_equal "#{Rails.root}/tmp/testing-filestore/avatars", Avatar.image_directory

    with_config_value :filestore_path, '/tmp/fish' do
      assert_equal '/tmp/fish/assets', Seek::Config.asset_filestore_path
      assert_equal '/tmp/fish/model_images', Seek::Config.model_image_filestore_path
      assert_equal '/tmp/fish/avatars', Seek::Config.avatar_filestore_path

      assert_equal "/tmp/fish/assets/#{cb.uuid}.dat", cb.filepath

      assert_equal '/tmp/fish/tmp', Seek::Config.temporary_filestore_path
      assert_equal '/tmp/fish/tmp/converted', Seek::Config.converted_filestore_path
      assert_equal '/tmp/fish/rdf', Seek::Config.rdf_filestore_path

    end

  end

  test 'email_enabled' do
    # NOTE: this is the value in seek_testing.rb, the actual default is 'false'
    assert_equal true, Seek::Config.email_enabled
  end

  test 'pdf_conversion_enabled' do
    assert_equal true, Seek::Config.pdf_conversion_enabled
  end

  test 'delete asset version enabled' do
    assert_equal false, Seek::Config.delete_asset_version_enabled
  end

  test 'forum_enabled' do
    assert_equal false, Seek::Config.forum_enabled
  end

  test 'sample_parser_enabled' do
    # NOTE: this is the value in seek_testing.rb, the actual default is 'false'
    assert_equal true, Seek::Config.sample_parser_enabled
  end

  test 'smtp_settings port' do
    assert_equal '25', Seek::Config.smtp_settings('port')
  end

  test 'tag_threshold' do
    assert_equal 1, Seek::Config.tag_threshold
  end

  test 'tag to integer conversion' do
    Seek::Config.tag_threshold = '5'
    assert_equal 5, Seek::Config.tag_threshold
  end

  test 'smtp_settings authentication' do
    assert_equal :plain, Seek::Config.smtp_settings('authentication')
  end
  test 'noreply_sender' do
    assert_equal 'no-reply@sysmo-db.org', Seek::Config.noreply_sender
  end
  test 'jws enabled' do
    assert_equal true, Seek::Config.jws_enabled
  end

  test 'exception_notification_enabled' do
    assert_equal false, Seek::Config.exception_notification_enabled
  end

  test 'exception_notification_recipients' do
    assert_equal '', Seek::Config.exception_notification_recipients
  end

  test 'hide_details_enabled' do
    assert_equal false, Seek::Config.hide_details_enabled
  end

  test 'activation_required_enabled' do
    assert_equal false, Seek::Config.activation_required_enabled
  end
  test 'google_analytics_enabled' do
    assert_equal false, Seek::Config.google_analytics_enabled
  end
  test 'google_analytics_tracker_id' do
    assert_equal '000-000', Seek::Config.google_analytics_tracker_id
  end

  test 'piwik_analytics_enabled' do
    assert_equal false, Seek::Config.piwik_analytics_enabled
  end
  test 'piwik_analytics_id_site' do
    assert_equal 1, Seek::Config.piwik_analytics_id_site
  end
  test 'piwik_analytics_url' do
    assert_equal 'localhost/piwik/', Seek::Config.piwik_analytics_url
  end

  # homepage settings
  test 'project_news_enabled' do
    assert_equal false, Seek::Config.project_news_enabled
  end
  test 'project_news_feed_urls' do
    assert_equal '', Seek::Config.project_news_feed_urls
  end
  test 'project_news_number_of_feed_entry' do
    assert_equal 10, Seek::Config.project_news_number_of_entries
  end

  test 'community_news_enabled' do
    assert_equal false, Seek::Config.community_news_enabled
  end
  test 'community_news_feed_urls' do
    assert_equal '', Seek::Config.community_news_feed_urls
  end
  test 'community_news_number_of_feed_entry' do
    assert_equal 10, Seek::Config.community_news_number_of_entries
  end

  # Project
  test 'project_name' do
    assert_equal 'Sysmo', Seek::Config.project_name
  end
  test 'project_type' do
    assert_equal 'Consortium', Seek::Config.project_type
  end
  test 'project_link' do
  assert_equal 'http://www.sysmo.net', Seek::Config.project_link
end
  test 'project_long_name' do
    assert_equal 'Sysmo Consortium', Seek::Config.project_long_name
  end
  test 'project_title' do
    assert_equal 'The Sysmo Consortium', Seek::Config.project_title
  end
  test 'dm_project_name' do
    assert_equal 'SysMO-DB', Seek::Config.dm_project_name
  end
  test 'dm_project_title' do
    assert_equal 'The Sysmo Consortium', Seek::Config.dm_project_title
  end
  test 'dm_project_link' do
    assert_equal 'http://www.sysmo-db.org', Seek::Config.dm_project_link
  end
  test 'application_name' do
    assert_equal 'SEEK', Seek::Config.application_name
  end
  test 'application_title' do
    assert_equal 'The Sysmo SEEK', Seek::Config.application_title
  end
  test 'header_image_enabled' do
    assert_equal true, Seek::Config.header_image_enabled
  end
  test 'header_image_link' do
    assert_equal 'http://www.sysmo-db.org', Seek::Config.header_image_link
  end
  test 'header_image_title' do
    assert_equal 'SysMO-DB', Seek::Config.header_image_title
  end
  # pagination
  test 'default page' do
    assert_equal 'latest', Seek::Config.default_page('sops')
  end

  test 'change default page' do
    assert_equal 'latest', Seek::Config.default_page('models')
    Seek::Config.set_default_page 'models', 'all'
    assert_equal 'all', Seek::Config.default_page('models')
    # seem to have to put it back else other tests fail later:
    Seek::Config.set_default_page 'models', 'latest'
  end

  test 'limit_latest' do
    assert_equal 7, Seek::Config.limit_latest
  end
  # others
  test 'type_managers' do
    assert_equal 'admins', Seek::Config.type_managers
  end

  test 'pubmed_api_email' do
    assert_equal nil, Seek::Config.pubmed_api_email
  end
  test 'crossref_api_email' do
    assert_equal 'sowen@cs.man.ac.uk', Seek::Config.crossref_api_email
  end
  test 'site_base_host' do
    assert_equal 'http://localhost:3000', Seek::Config.site_base_host
  end
  test 'open_id_authentication_store' do
    assert_equal :memory, Seek::Config.open_id_authentication_store
  end
  test 'copyright_addendum_enabled' do
    assert_equal false, Seek::Config.copyright_addendum_enabled
  end
  test 'copyright_addendum_content' do
    assert_equal 'Additions copyright ...', Seek::Config.copyright_addendum_content
  end

  test 'changing a setting' do
    Seek::Config.pubmed_api_email = 'fred@email.com'
    assert_equal 'fred@email.com', Seek::Config.pubmed_api_email
  end

  test 'convert setting from database' do
    Settings.limit_latest = '6'
    assert_equal 6, Seek::Config.limit_latest
  end

  test 'invalid setting accessor' do
    assert_raises(NoMethodError) { Seek::Config.xxxxx }
    assert_raises(NoMethodError) { Seek::Config.xxxxx = true }
  end

  test 'encrypt/decrypt smtp password' do
    Seek::Config.set_smtp_settings 'password', 'abcd'
    assert_equal Seek::Config.smtp_settings('password'), 'abcd'
    assert_equal ActionMailer::Base.smtp_settings[:password], 'abcd'
  end

  test 'encrypt/decrypt datacite password' do
    Seek::Config.datacite_password_encrypt 'abcd'
    assert_equal Seek::Config.datacite_password_decrypt, 'abcd'
  end

  test 'doi_prefix, doi_suffix' do
    assert_equal "10.5072", Seek::Config.doi_prefix
    assert_equal "Sysmo.SEEK", Seek::Config.doi_suffix
  end

  test 'datacite_url' do
    assert_equal "https://test.datacite.org/mds/", Seek::Config.datacite_url
  end

  test 'datacite_username' do
    assert_equal "test", Seek::Config.datacite_username
  end

  test 'datacite_password' do
    assert_equal "test", Seek::Config.datacite_password_decrypt
  end

  test 'time_lock_doi_for' do
    assert_equal 0, Seek::Config.time_lock_doi_for
  end

  test 'home_description' do
    assert_equal 'You can configure the text that goes here within the Admin pages: Site Configuration->Home page settings.', Seek::Config.home_description
    Seek::Config.home_description = 'A new description'
    assert_equal 'A new description', Seek::Config.home_description
  end

  test 'sabiork_ws_base_url' do
    assert_equal 'http://sabiork.h-its.org/sabioRestWebServices/', Seek::Config.sabiork_ws_base_url
  end

  test 'publish_button_enabled' do
    assert_equal true, Seek::Config.publish_button_enabled
  end

  test 'recaptcha enabled' do
    assert_equal true, Seek::Config.recaptcha_enabled
  end

  test 'propagate bioportal api key' do
    assert_equal 'fish', Organism.bioportal_api_key
    Seek::Config.bioportal_api_key = 'frog'
    assert_equal 'frog', Organism.bioportal_api_key
  end
end
