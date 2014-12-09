require 'test_helper'

class DataciteDoiTest < ActionController::IntegrationTest

  DOIABLE_ASSETS = Seek::Util.doiable_asset_types.collect{|type| type.name.underscore}

  def setup
    User.current_user = Factory(:user, :login => 'test')
    post '/session', :login => 'test', :password => 'blah'
  end

  test 'doiable assets' do
    assert_equal ['data_file', 'model', 'sop', 'workflow'], DOIABLE_ASSETS
  end

  test 'mint a DOI button' do
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym,:policy=>Factory(:public_policy))
      assert asset.is_doiable?(1)

      get "/#{type.pluralize}/#{asset.id}?version=#{asset.version}"
      assert_response :success

      assert_select "ul.sectionIcons > li > span.icon" do
        assert_select "a[href=?]", polymorphic_path(asset, :action => 'mint_doi_confirm', :version => 1), :text=>/Generate a DOI/
      end
    end
  end

  test "get mint_doi_confirm" do
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym,:policy=>Factory(:public_policy))
      assert asset.is_published?
      assert asset.can_manage?

      asset.creators = [Factory(:person)]
      asset.save

      get "/#{type.pluralize}/#{asset.id}/mint_doi_confirm?version=#{asset.version}"
      assert_response :success

      assert_select "p",:text=>/The DOI that will be generated will be #{asset.generated_doi}/
    end
  end

  test "authorization for mint_doi_confirm" do
    skip("mint_doi_confirmation")
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym, :policy=>Factory(:private_policy), :contributor => User.current_user)
      refute asset.is_published?
      assert asset.can_manage?
      refute asset.is_doiable?(asset.version)

      get "/#{type.pluralize}/#{asset.id}/mint_doi_confirm?version=#{asset.version}"
      assert_response :redirect

      asset.publish!
      assert asset.reload.is_published?
      a_user = Factory(:user, :login => 'a_user')
      post '/session', :login => 'a_user', :password => 'blah'
      assert_equal a_user,User.current_user
      refute asset.can_manage?
      refute asset.is_doiable?(asset.version)

      get "/#{type.pluralize}/#{asset.id}/mint_doi_confirm?version=#{asset.version}"
      assert_response :redirect
    end
  end

  test "generate_metadata_in_xml" do
    metadata_param = datacite_metadata_param

    metadata_in_xml = DataFilesController.new().generate_metadata_xml(metadata_param)
    metadata_from_file = open("#{Rails.root}/test/fixtures/files/doi_metadata.xml").read

    assert_equal metadata_from_file, metadata_in_xml
  end

  test "generate_metadata_in_xml does not contain empty node" do
    metadata_param = {:identifier => '',
                      :creators => [],
                      :titles => ['test title'],
                      :publisher => 'Fairdom',
                      :publicationYear => '2014'
    }

    metadata_in_xml = DataFilesController.new().generate_metadata_xml(metadata_param)

    assert !metadata_in_xml.include?('identifier')
    assert !metadata_in_xml.include?('creators')
    assert !metadata_in_xml.include?('creator')
    assert !metadata_in_xml.include?('descriptions')

    assert metadata_in_xml.include?('title')
    assert metadata_in_xml.include?('titles')
    assert metadata_in_xml.include?('publisher')
    assert metadata_in_xml.include?('publicationYear')
  end

  test "mint_doi" do
    mock_datacite_request
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym,:policy=>Factory(:public_policy))

      post "/#{type.pluralize}/#{asset.id}/mint_doi"
      assert_redirected_to polymorphic_path(asset, :version => asset.version)
      assert_not_nil flash[:notice]

      assert AssetDoiLog.was_doi_minted_for?(asset.class.name, asset.id, asset.version)
    end
  end

  test "handle error when mint_doi" do
    mock_datacite_request
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym,:policy=>Factory(:public_policy))

      with_config_value :datacite_username, 'invalid' do
        post "/#{type.pluralize}/#{asset.id}/mint_doi"
        assert_not_nil flash[:error]

        assert !AssetDoiLog.was_doi_minted_for?(asset.class.name, asset.id, asset.version)
      end
    end
  end

  test 'minted_doi' do
    skip("minted_doi")
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym,:policy=>Factory(:public_policy))
      assert asset.is_published?
      assert asset.can_manage?

      doi = '10.5072/my_test'
      url = "#{root_url}data_files/#{asset.id}?version=#{asset.version}"

      get "/#{type.pluralize}/#{asset.id}/minted_doi?version=#{asset.version}&doi=#{doi}&url=#{url}"
      assert_response :success

      assert_select "li", :text => /#{doi}/
      assert_select "li", :text => "Resolved URL: http://test.host/data_files/#{asset.id}?version=1"
      assert_select "li", :text => /#{asset.title}/
    end
  end

  test 'should show doi attribute for asset which doi is minted' do
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym,:policy=>Factory(:public_policy))
      doi = '10.5072/my_test'
      asset.doi = doi
      assert asset.save

      get "/#{type.pluralize}/#{asset.id}?version=#{asset.version}"
      assert_response :success

      assert_select "p", :text => /#{doi}/
    end
  end

  test 'should show doi attribute on minted version' do
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym,:contributor=>User.current_user)

      asset.save_as_new_version
      if type == 'workflow'
        Factory(:content_blob, :asset => asset, :asset_version => asset.version,
                :data => File.new("#{Rails.root}/test/fixtures/files/enm.t2flow","rb").read,
                :original_filename => "enm.t2flow",
                :content_type => "application/pdf")
      else
        Factory(:content_blob, :asset => asset, :asset_version => asset.version)
      end

      asset.reload
      assert_equal 2, asset.version

      doi = '10.5072/my_test'
      asset.doi = doi
      assert asset.save

      get "/#{type.pluralize}/#{asset.id}?version=2"
      assert_response :success
      assert_select "p", :text => /#{doi}/

      get "/#{type.pluralize}/#{asset.id}?version=1"
      assert_response :success

      assert_select "p", :text => /#{doi}/, :count => 0
    end
  end

  test 'should log doi after doi is minted' do
    mock_datacite_request
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym,:policy=>Factory(:public_policy))

      post "/#{type.pluralize}/#{asset.id}/mint_doi"
      assert AssetDoiLog.was_doi_minted_for?(asset.class.name, asset.id, asset.version)

      log = AssetDoiLog.last
      assert_equal asset.class.name, log.asset_type
      assert_equal asset.id, log.asset_id
      assert_equal asset.version, log.asset_version
      assert_equal User.current_user.id, log.user_id
      assert_equal 1, log.action #MINTED
      assert_equal "10.5072/Sysmo.SEEK.#{asset.class.name.downcase}.#{asset.id}.#{asset.version}", log.doi
      AssetDoiLog.was_doi_minted_for?(asset.class.name, asset.id, asset.version)
    end
  end

  test 'after DOI is minted, the -Upload new version- button is disabled' do
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym,:policy=>Factory(:public_policy))
      latest_version = asset.latest_version
      latest_version.doi = '10.5072/my_test'
      assert latest_version.save
      assert asset.is_doi_minted?(latest_version.version)

      get "/#{type.pluralize}/#{asset.id}"

      assert_select "a[class='disabled']", :text => /Upload new version/
    end
  end

  test 'can not upload new version after DOI is minted' do
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym,:policy=>Factory(:public_policy))
      latest_version = asset.latest_version
      latest_version.doi = '10.5072/my_test'
      assert latest_version.save
      assert asset.is_doi_minted?(latest_version.version)

      post "/#{type.pluralize}/#{asset.id}/new_version", :data_file=>{},:content_blob=>{:data=>{}}, :revision_comment=>"This is a new revision"

      assert_redirected_to :root
      assert_not_nil flash[:error]
    end
  end

  test 'after DOI is minted, the -Delete- button is disabled' do
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym, :contributor =>  User.current_user, :policy=>Factory(:private_policy))
      latest_version = asset.latest_version
      latest_version.doi = '10.5072/my_test'
      assert latest_version.save
      assert asset.is_doi_minted?(latest_version.version)

      if type == 'workflow'
        get "/#{type.pluralize}/#{asset.id}/edit"
      else
        get "/#{type.pluralize}/#{asset.id}"
      end

      assert_select "span[class='disabled_icon disabled']", :text => /Delete/
    end
  end

  test 'can not delete asset after DOI is minted' do
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym, :contributor =>  User.current_user, :policy=>Factory(:private_policy))
      latest_version = asset.latest_version
      latest_version.doi = '10.5072/my_test'
      assert latest_version.save
      assert asset.is_doi_minted?(latest_version.version)

      delete "/#{type.pluralize}/#{asset.id}"

      assert_redirected_to asset
      assert_not_nil flash[:error]
    end
  end

  test 'after DOI is minted, disable the sharing_form options to unpublish the asset' do
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym,:policy=>Factory(:public_policy))
      latest_version = asset.latest_version
      latest_version.doi = '10.5072/my_test'
      assert latest_version.save
      assert asset.is_any_doi_minted?

      get "/#{type.pluralize}/#{asset.id}/edit"

      assert_select "input[type=radio][disabled=true]", :count => 2
    end
  end

  test 'can not unpublish asset after DOI is minted' do
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym,:policy=>Factory(:public_policy))
      latest_version = asset.latest_version
      latest_version.doi = '10.5072/my_test'
      assert latest_version.save
      assert asset.is_doi_minted?(latest_version.version)

      unpublic_sharing = {:sharing_scope =>Policy::ALL_SYSMO_USERS,
                        "access_type_#{Policy::ALL_SYSMO_USERS}".to_sym => Policy::VISIBLE
      }
      put "/#{type.pluralize}/#{asset.id}", :sharing=>unpublic_sharing

      assert_redirected_to :root
      assert_not_nil flash[:error]
    end
  end

  private

  def mock_datacite_request
    stub_request(:post, "https://test:test@test.datacite.org/mds/metadata").to_return(:body => 'OK (10.5072/my_test)', :status => 201)
    stub_request(:post, "https://test:test@test.datacite.org/mds/doi").to_return(:body => 'OK', :status => 201)
    stub_request(:post, "https://invalid:test@test.datacite.org/mds/metadata").to_return(:body => '401 Bad credentials', :status => 401)
  end

  def datacite_metadata_param
    {:identifier => '10.5072/my_test',
     :creators => [{:creatorName => 'Last1, First1'}, {:creatorName => 'Last2, First2'}],
     :titles => ['test title'],
     :publisher => 'Fairdom',
     :publicationYear => '2014',
     :subjects => ['System Biology', 'Bioinformatic'],
     :language => 'eng',
     :resourceType => 'Dataset',
     :version => '1.0',
     :descriptions => ['test description']
    }
  end

  def asset_url asset
    "#{root_url}data_files/#{asset.id}?version=#{asset.version}"
  end
end
