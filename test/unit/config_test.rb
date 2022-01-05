require 'test_helper'

class ConfigTest < ActiveSupport::TestCase
  # Features enabled

  test 'events enabled' do
    assert Seek::Config.events_enabled
  end
  test 'jerm_disabled' do
    assert !Seek::Config.jerm_enabled
  end
  test 'solr enabled' do
    assert Seek::Config.solr_enabled
  end

  test 'is_virtualliver' do
    with_config_value 'is_virtualliver', true do
      assert Seek::Config.is_virtualliver
    end
  end

  test 'read setting attributes' do
    attributes = Seek::Config.read_setting_attributes
    refute attributes.empty?
    assert_includes attributes, :events_enabled
  end

  test 'project_hierarchy_enabled' do
    with_config_value 'project_hierarchy_enabled', true do
      assert Seek::Config.project_hierarchy_enabled
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

    assert_equal "#{Rails.root}/tmp/testing-filestore/tmp", Seek::Config.temporary_filestore_path
    assert_equal "#{Rails.root}/tmp/testing-filestore/converted-assets", Seek::Config.converted_filestore_path

    assert_equal "#{Rails.root}/tmp/testing-filestore/avatars", Avatar.image_directory

    with_config_value :filestore_path, '/tmp/fish' do
      assert_equal '/tmp/fish/assets', Seek::Config.asset_filestore_path
      assert_equal '/tmp/fish/model_images', Seek::Config.model_image_filestore_path
      assert_equal '/tmp/fish/avatars', Seek::Config.avatar_filestore_path

      assert_equal "/tmp/fish/assets/#{cb.uuid}.dat", cb.filepath

      assert_equal '/tmp/fish/tmp', Seek::Config.temporary_filestore_path
      assert_equal '/tmp/fish/converted-assets', Seek::Config.converted_filestore_path
      assert_equal '/tmp/fish/rdf', Seek::Config.rdf_filestore_path
    end
  end

  test 'email_enabled' do
    # NOTE: this is the value in seek_testing.rb, the actual default is 'false'
    assert Seek::Config.email_enabled
  end

  test 'pdf_conversion_enabled' do
    assert Seek::Config.pdf_conversion_enabled
  end

  test 'delete asset version enabled' do
    assert !Seek::Config.delete_asset_version_enabled
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

  test 'tag as integer' do
    Seek::Config.tag_threshold = 6
    assert_equal 6, Seek::Config.tag_threshold
  end

  test 'changing default_associated_projects_access_type integer conversion' do
    Seek::Config.default_associated_projects_access_type = '0'
    assert_equal 0, Seek::Config.default_associated_projects_access_type
  end

  test 'changing default_all_visitors_access_type integer conversion' do
    Seek::Config.default_all_visitors_access_type = '0'
    assert_equal 0, Seek::Config.default_all_visitors_access_type
  end

  test 'changing max_all_visitors_access_type integer conversion' do
    Seek::Config.max_all_visitors_access_type = '0'
    assert_equal 0, Seek::Config.max_all_visitors_access_type
  end

  test 'smtp_settings authentication' do
    assert_equal :plain, Seek::Config.smtp_settings('authentication')
  end
  test 'noreply_sender' do
    assert_equal 'no-reply@sysmo-db.org', Seek::Config.noreply_sender
  end
  test 'jws enabled' do
    assert Seek::Config.jws_enabled
  end

  test 'exception_notification_enabled' do
    assert !Seek::Config.exception_notification_enabled
  end

  test 'exception_notification_recipients' do
    assert_equal '', Seek::Config.exception_notification_recipients
  end

  test 'hide_details_enabled' do
    assert !Seek::Config.hide_details_enabled
  end

  test 'activation_required_enabled' do
    assert !Seek::Config.activation_required_enabled
  end
  test 'google_analytics_enabled' do
    assert !Seek::Config.google_analytics_enabled
  end
  test 'google_analytics_tracker_id' do
    assert_equal '000-000', Seek::Config.google_analytics_tracker_id
  end

  test 'piwik_analytics_enabled' do
    assert !Seek::Config.piwik_analytics_enabled
  end
  test 'piwik_analytics_id_site' do
    assert_equal 1, Seek::Config.piwik_analytics_id_site
  end
  test 'piwik_analytics_url' do
    assert_equal 'localhost/piwik/', Seek::Config.piwik_analytics_url
  end

  # homepage settings
  test 'project_news_enabled' do
    assert !Seek::Config.project_news_enabled
  end
  test 'project_news_feed_urls' do
    assert_equal '', Seek::Config.project_news_feed_urls
  end
  test 'project_news_number_of_feed_entry' do
    assert_equal 10, Seek::Config.project_news_number_of_entries
  end

  test 'community_news_enabled' do
    assert !Seek::Config.community_news_enabled
  end
  test 'community_news_feed_urls' do
    assert_equal '', Seek::Config.community_news_feed_urls
  end
  test 'community_news_number_of_feed_entry' do
    assert_equal 10, Seek::Config.community_news_number_of_entries
  end

  # Project
  test 'project_name' do
    assert_equal 'Sysmo SEEK', Seek::Config.instance_name
  end

  test 'instance_link' do
    assert_equal 'http://www.sysmo.net', Seek::Config.instance_link
  end

  test 'instance_admins_name' do
    assert_equal 'SysMO-DB', Seek::Config.instance_admins_name
  end

  test 'instance_admins_link' do
    assert_equal 'http://www.sysmo-db.org', Seek::Config.instance_admins_link
  end
  test 'application_name' do
    assert_equal 'FAIRDOM-SEEK', Seek::Config.application_name
  end

  test 'header_image_enabled' do
    assert Seek::Config.header_image_enabled
  end
  test 'header_image_link' do
    assert_equal 'http://www.sysmo-db.org', Seek::Config.header_image_link
  end
  test 'header_image_title' do
    assert_equal 'SysMO-DB', Seek::Config.header_image_title
  end

  test 'change default sorting' do
    assert_nil Seek::Config.sorting_for('models')
    Seek::Config.set_sorting_for 'models', 'created_at_asc'
    assert_equal :created_at_asc, Seek::Config.sorting_for('models')
    # seem to have to put it back else other tests fail later:
    Seek::Config.set_sorting_for('models', nil)
    assert_nil Seek::Config.sorting_for('models')
  end

  test 'results_per_page_default' do
    assert_equal 7, Seek::Config.results_per_page_default
  end

  test 'results_per_page_default_condensed' do
    assert_equal 14, Seek::Config.results_per_page_default_condensed
  end

  # others
  test 'type_managers' do
    assert_equal 'admins', Seek::Config.type_managers
  end

  test 'pubmed_api_email' do
    assert_nil Seek::Config.pubmed_api_email
  end

  test 'crossref_api_email' do
    assert_equal 'sowen@cs.man.ac.uk', Seek::Config.crossref_api_email
  end

  test 'site_base_host' do
    assert_equal 'http://localhost:3000', Seek::Config.site_base_host
  end

  test 'host_with_port' do
    assert_equal 'localhost:3000', Seek::Config.host_with_port

    with_config_value(:site_base_host, 'https://secure.website:443') do
      assert_equal 'secure.website', Seek::Config.host_with_port
    end

    with_config_value(:site_base_host, 'http://insecure.website:80') do
      assert_equal 'insecure.website', Seek::Config.host_with_port
    end

    with_config_value(:site_base_host, 'http://localhost') do
      assert_equal 'localhost', Seek::Config.host_with_port
    end
  end

  test 'host_scheme' do
    assert_equal 'http', Seek::Config.host_scheme

    with_config_value(:site_base_host, 'https://secure.website:443') do
      assert assert_equal 'https', Seek::Config.host_scheme
    end

    with_config_value(:site_base_host, 'http://insecure.website:80') do
      assert_equal 'http', Seek::Config.host_scheme
    end

    with_config_value(:site_base_host, 'http://localhost') do
      assert_equal 'http', Seek::Config.host_scheme
    end
  end

  test 'copyright_addendum_enabled' do
    assert !Seek::Config.copyright_addendum_enabled
  end
  test 'copyright_addendum_content' do
    assert_equal 'Additions copyright ...', Seek::Config.copyright_addendum_content
  end

  test 'changing a setting' do
    Seek::Config.pubmed_api_email = 'fred@email.com'
    assert_equal 'fred@email.com', Seek::Config.pubmed_api_email
  end

  test 'convert setting from database' do
    Settings.global.set('results_per_page_default', '6')
    assert_equal 6, Seek::Config.results_per_page_default
  end

  test 'default associated projects access permission is accessible' do
    assert_equal Policy::ACCESSIBLE, Seek::Config.default_associated_projects_access_type
  end

  test 'default all visitors access permission is accessible' do
    with_config_value :default_all_visitors_access_type, Policy::ACCESSIBLE do
      assert_equal Policy::ACCESSIBLE, Seek::Config.default_all_visitors_access_type
    end
  end

  test 'invalid setting accessor' do
    assert_raises(NoMethodError) { Seek::Config.xxxxx }
    assert_raises(NoMethodError) { Seek::Config.xxxxx = true }
  end

  test 'encrypt/decrypt smtp password' do
    password = 'a-distinctive-password-that-can-be-identified-easily'
    Seek::Config.set_smtp_settings 'password', password
    assert_equal password, Seek::Config.smtp_settings('password')
    assert_equal password, ActionMailer::Base.smtp_settings[:password]

    setting = Settings.global.where(var: 'smtp').first
    assert setting.encrypted?
    assert_nil setting[:value]
    refute setting[:encrypted_value].include?(password)
  end

  test 'doi_prefix, doi_suffix' do
    assert_equal '10.5072', Seek::Config.doi_prefix
    assert_equal 'Sysmo.SEEK', Seek::Config.doi_suffix
  end

  test 'datacite_url' do
    assert_equal 'https://mds.test.datacite.org/', Seek::Config.datacite_url
  end

  test 'datacite_username' do
    assert_equal 'test', Seek::Config.datacite_username
  end

  test 'datacite_password' do
    assert_equal 'test', Seek::Config.datacite_password
  end

  test 'time_lock_doi_for' do
    assert_equal 0, Seek::Config.time_lock_doi_for
  end

  test 'home_description' do
    assert_equal 'You can configure the text that goes here within the Admin pages: Site Configuration->Home page settings.', Seek::Config.home_description
    Seek::Config.home_description = 'A new description'
    assert_equal 'A new description', Seek::Config.home_description
  end

  test 'registration_disabled_description' do
    assert_equal 'Registration is not available, please contact your administrator', Seek::Config.registration_disabled_description
    Seek::Config.registration_disabled_description = 'A new description'
    assert_equal 'A new description', Seek::Config.registration_disabled_description
  end

  test 'sabiork_ws_base_url' do
    assert_equal 'http://sabiork.h-its.org/sabioRestWebServices/', Seek::Config.sabiork_ws_base_url
  end

  test 'publish_button_enabled' do
    assert Seek::Config.publish_button_enabled
  end

  test 'recaptcha enabled' do
    assert Seek::Config.recaptcha_enabled
  end

  test 'propagate bioportal api key' do
    assert_equal 'fish', Organism.bioportal_api_key
    Seek::Config.bioportal_api_key = 'frog'
    assert_equal 'frog', Organism.bioportal_api_key
  end

  test 'imprint_enabled' do
    assert !Seek::Config.imprint_enabled
  end

  test 'imprint_description' do
    assert_equal 'Here is imprint example', Seek::Config.imprint_description
  end

  test 'zenodo_api_url' do
    assert_equal 'https://sandbox.zenodo.org/api', Seek::Config.zenodo_api_url
  end

  test 'zenodo_oauth_url' do
    assert_equal 'https://sandbox.zenodo.org/oauth', Seek::Config.zenodo_oauth_url
  end

  test 'default_value works for all settings' do
    Seek::Config.read_setting_attributes.each do |method, _|
      method_name = "default_#{method}"
      assert Seek::Config.respond_to?(method_name.to_sym), "`#{method_name}` is not defined on Seek::Config"
    end
  end

  test 'default_value is not changed' do
    old_default_value = Seek::Config.default_external_help_url
    with_config_value 'external_help_url', 'http://www.somewhere.com' do
      new_default_value = Seek::Config.default_external_help_url
      assert_equal old_default_value, new_default_value
    end
  end

  test 'size limits are numeric' do
    with_config_value(:max_cachable_size, '1000') do
      with_config_value(:hard_max_cachable_size, '2000') do
        assert_equal 1000, Seek::Config.max_cachable_size
        assert_equal 2000, Seek::Config.hard_max_cachable_size
        assert_equal Integer, Seek::Config.max_cachable_size.class
        assert_equal Integer, Seek::Config.hard_max_cachable_size.class
      end
    end
  end

  test 'attr encrypted key' do
    assert_equal "#{Rails.root}/tmp/testing-filestore/attr_encrypted/key", Seek::Config.attr_encrypted_key_path
    FileUtils.rm(Seek::Config.attr_encrypted_key_path) if File.exist?(Seek::Config.attr_encrypted_key_path)
    refute_nil key = Seek::Config.attr_encrypted_key
    assert File.exist?(Seek::Config.attr_encrypted_key_path)
    FileUtils.rm(Seek::Config.attr_encrypted_key_path)
    assert_equal 32, key.length

    # check it regenerates it different each time
    refute_equal key, Seek::Config.attr_encrypted_key
  end

  test 'secret key base' do
    path = "#{Rails.root}/tmp/testing-filestore/secret_key_base/key"
    FileUtils.rm(path) if File.exist?(path)
    key = Seek::Config.secret_key_base
    refute_nil key
    assert File.exist?(path)
    assert_equal key,Seek::Config.secret_key_base
    assert_equal key,File.read(path)
    assert_equal 128,key.length
    FileUtils.rm(path)
    refute_equal key, Seek::Config.secret_key_base
  end

  test 'project-specific setting' do
    many_bananas_project = Factory(:project)
    no_bananas_project = Factory(:project)
    many_bananas_project.settings.set('banana_count', 10)
    no_bananas_project.settings.set('banana_count', 0)

    assert_equal 10, many_bananas_project.settings.get('banana_count')
    assert_equal 0, no_bananas_project.settings.get('banana_count')
  end

  test 'project-specific settings can be accessed in various ways' do
    many_bananas_project = Factory(:project)
    many_bananas_project.settings.set('banana_count', 10)

    assert_equal 10, many_bananas_project.settings.get('banana_count')
    assert_equal 10, Settings.for(many_bananas_project).get('banana_count')
  end

  test 'project-specific settings do no conflict with global settings' do
    many_bananas_project = Factory(:project)
    no_bananas_project = Factory(:project)
    many_bananas_project.settings.set('banana_count', 10)
    Settings.global.set('banana_count', 5)
    no_bananas_project.settings.set('banana_count', 0)

    assert_equal 10, many_bananas_project.settings.get('banana_count')
    assert_equal 5, Settings.global.get('banana_count')
    assert_equal 0, no_bananas_project.settings.get('banana_count')
  end

  test 'encrypts settings' do
    Seek::Config.datacite_password = 'test'

    setting = Settings.global.where(var: 'datacite_password').last

    assert_equal 'test', setting.value
    refute_equal 'test', setting.encrypted_value
    assert_nil setting[:value], 'Password should be encrypted in database'

    setting.destroy!
  end

  test 'handles legacy encrypted settings before encryption was implemented' do
    Seek::Config.datacite_password = 'test'

    setting = Settings.global.where(var: 'datacite_password').last

    setting.update_column(:value, 'test')
    setting.update_column(:encrypted_value, nil)
    setting.update_column(:encrypted_value_iv, nil)

    refute setting.encrypted?
    assert setting.encrypt?
    assert_equal 'test', setting.reload.value
    assert_equal 'test', setting[:value], 'Password should not be encrypted yet'

    setting.value = 'test'
    setting.save!

    assert setting.encrypted?
    assert setting.encrypt?
    assert_equal 'test', setting.reload.value
    assert_nil setting[:value], 'Password should be encrypted now'
  end

  test 'merge! converts Hash to HashWithIndifferentAccess' do
    with_config_value 'smtp', {} do
      assert_equal 'Hash', Seek::Config.smtp.class.name
      Settings.merge!(:smtp, {})
      assert_equal 'ActiveSupport::HashWithIndifferentAccess', Seek::Config.smtp.class.name
    end
  end

  test 'transfer_setting' do

    # old name has a value hanging around
    Seek::Config.set_value(:old_name, "The INSTANCE name")

    refute_nil Settings.fetch(:old_name)
    refute_nil Settings.global.fetch(:old_name)
    assert_equal "The INSTANCE name",Seek::Config.get_value(:old_name)
    assert_nil Seek::Config.get_value(:new_name)

    Seek::Config.transfer_value(:old_name, :new_name)

    assert_equal "The INSTANCE name",Seek::Config.get_value(:new_name)
    assert_nil Seek::Config.get_value(:old_name)
    assert_nil Settings.fetch(:old_name)
    assert_nil Settings.global.fetch(:old_name)

    # repeatable
    Seek::Config.transfer_value(:old_name, :new_name)

    assert_equal "The INSTANCE name",Seek::Config.get_value(:new_name)
    assert_nil Seek::Config.get_value(:old_name)
    assert_nil Settings.fetch(:old_name)
    assert_nil Settings.global.fetch(:old_name)

    # don't transfer default if not set
    Seek::Config.default :old_name_2, 'The setting'
    assert_equal "The setting",Seek::Config.get_value(:old_name_2)
    assert_nil Settings.fetch(:old_name_2)
    assert_nil Settings.global.fetch(:old_name_2)

    Seek::Config.transfer_value(:old_name_2, :new_name_2)

    assert_nil Settings.global.fetch(:old_name_2)
    assert_nil Settings.global.fetch(:new_name_2)
    assert_nil Seek::Config.get_value(:new_name_2)
    assert_nil Seek::Config.get_value(:old_name_2)
    assert_nil Settings.fetch(:old_name_2)
    assert_nil Settings.fetch(:new_name_2)

  end

end
