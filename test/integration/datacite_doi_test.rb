require 'test_helper'

class DataciteDoiTest < ActionDispatch::IntegrationTest
  include MockHelper

  DOIABLE_ASSETS = Seek::Util.doiable_asset_types.collect { |type| type.name.underscore }

  setup do
    @user = Factory(:user, login: 'test')
    login_as(@user)
    doi_citation_mock
  end

  test 'doiable assets' do
    assert_equal %w(data_file model sop workflow), DOIABLE_ASSETS
  end

  test 'mint a DOI button' do
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym, policy: Factory(:public_policy))
      assert asset.is_doiable?(1)

      get "/#{type.pluralize}/#{asset.id}?version=#{asset.version}"
      assert_response :success

      assert_select '#buttons' do
        assert_select 'a[href=?]', polymorphic_path(asset, action: 'mint_doi_confirm', version: 1), text: /Generate a DOI/
      end
    end
  end

  test 'get mint_doi_confirm' do
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym, policy: Factory(:public_policy))
      assert asset.is_published?
      assert asset.can_manage?

      asset.creators = [Factory(:person)]
      asset.save

      get "/#{type.pluralize}/#{asset.id}/mint_doi_confirm?version=#{asset.version}"
      assert_response :success

      assert_select 'p', text: /The DOI that will be generated will be #{asset.generated_doi}/
    end
  end

  test 'authorization for mint_doi_confirm' do
    a_user = User.current_user = Factory(:user, login: 'a_user')

    DOIABLE_ASSETS.each do |type|
      login_as(@user)
      asset = Factory(type.to_sym, policy: Factory(:private_policy), contributor: User.current_user)
      refute asset.is_published?
      assert asset.can_manage?
      refute asset.is_doiable?(asset.version)

      get "/#{type.pluralize}/#{asset.id}/mint_doi_confirm?version=#{asset.version}"
      assert_response :redirect

      asset.publish!
      assert asset.reload.is_published?

      login_as(a_user)
      assert_equal a_user, User.current_user
      refute asset.can_manage?
      refute asset.is_doiable?(asset.version)

      get "/#{type.pluralize}/#{asset.id}/mint_doi_confirm?version=#{asset.version}"
      assert_response :redirect
    end
  end

  test 'mint_doi' do
    mock_datacite_request
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym, policy: Factory(:public_policy))

      post "/#{type.pluralize}/#{asset.id}/mint_doi"
      assert_redirected_to polymorphic_path(asset, version: asset.version)
      assert_not_nil flash[:notice]

      assert AssetDoiLog.was_doi_minted_for?(asset.class.name, asset.id, asset.version)
    end
  end

  test 'handle error when mint_doi' do
    mock_datacite_request
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym, policy: Factory(:public_policy))

      with_config_value :datacite_username, 'invalid' do
        post "/#{type.pluralize}/#{asset.id}/mint_doi"
        assert_not_nil flash[:error]

        assert !AssetDoiLog.was_doi_minted_for?(asset.class.name, asset.id, asset.version)
      end
    end
  end

  test 'should show doi attribute for asset which doi is minted' do
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym, policy: Factory(:public_policy))
      doi = '10.5072/my_test'
      asset.doi = doi
      assert asset.save

      get "/#{type.pluralize}/#{asset.id}?version=#{asset.version}"
      assert_response :success

      assert_select 'p', text: /#{doi}/
    end
  end

  test 'should show doi attribute on minted version' do
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym, contributor: User.current_user)

      asset.save_as_new_version
      if type == 'workflow'
        Factory(:content_blob, asset: asset, asset_version: asset.version,
                               data: File.new("#{Rails.root}/test/fixtures/files/enm.t2flow", 'rb').read,
                               original_filename: 'enm.t2flow',
                               content_type: 'application/pdf')
      else
        Factory(:content_blob, asset: asset, asset_version: asset.version)
      end

      asset.reload
      assert_equal 2, asset.version

      doi = '10.5072/my_test'
      asset.doi = doi
      assert asset.save

      get "/#{type.pluralize}/#{asset.id}?version=2"
      assert_response :success
      assert_select 'p', text: /#{doi}/

      get "/#{type.pluralize}/#{asset.id}?version=1"
      assert_response :success

      assert_select 'p', text: /#{doi}/, count: 0
    end
  end

  test 'should log doi after doi is minted' do
    mock_datacite_request
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym, policy: Factory(:public_policy))

      post "/#{type.pluralize}/#{asset.id}/mint_doi"
      assert AssetDoiLog.was_doi_minted_for?(asset.class.name, asset.id, asset.version)

      log = AssetDoiLog.last
      assert_equal asset.class.name, log.asset_type
      assert_equal asset.id, log.asset_id
      assert_equal asset.version, log.asset_version
      assert_equal User.current_user.id, log.user_id
      assert_equal 1, log.action # MINTED
      assert_equal "10.5072/Sysmo.SEEK.#{asset.class.name.downcase}.#{asset.id}.#{asset.version}", log.doi
      AssetDoiLog.was_doi_minted_for?(asset.class.name, asset.id, asset.version)
    end
  end

  test 'after DOI is minted, the -Upload new version- button is disabled' do
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym, policy: Factory(:public_policy))
      latest_version = asset.latest_version
      latest_version.doi = '10.5072/my_test'
      assert latest_version.save
      assert asset.is_doi_minted?(latest_version.version)

      get "/#{type.pluralize}/#{asset.id}"

      assert_select "a[class='disabled']", text: /Upload new version/
    end
  end

  test 'can not upload new version after DOI is minted' do
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym, policy: Factory(:public_policy))
      latest_version = asset.latest_version
      latest_version.doi = '10.5072/my_test'
      assert latest_version.save
      assert asset.is_doi_minted?(latest_version.version)

      post "/#{type.pluralize}/#{asset.id}/new_version", data_file: {}, content_blobs: [{ data: {} }], revision_comment: 'This is a new revision'

      assert_redirected_to :root
      assert_not_nil flash[:error]
    end
  end

  test 'after DOI is minted, the -Delete- button is disabled' do
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym, contributor: User.current_user, policy: Factory(:private_policy))
      latest_version = asset.latest_version
      latest_version.doi = '10.5072/my_test'
      assert latest_version.save
      assert asset.is_doi_minted?(latest_version.version)

      get "/#{type.pluralize}/#{asset.id}"

      assert_select "span[class='disabled_icon disabled']", text: /Delete/
    end
  end

  test 'can not delete asset after DOI is minted' do
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym, contributor: User.current_user, policy: Factory(:private_policy))
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
    skip 'This test no longer works with the dynamic permissions form'

    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym, policy: Factory(:public_policy))
      latest_version = asset.latest_version
      latest_version.doi = '10.5072/my_test'
      assert latest_version.save
      assert asset.is_any_doi_minted?

      get "/#{type.pluralize}/#{asset.id}/edit"

      assert_select 'input[type=radio][disabled=true]', count: 2
    end
  end

  test 'can not unpublish asset after DOI is minted' do
    DOIABLE_ASSETS.each do |type|
      asset = Factory(type.to_sym, policy: Factory(:public_policy))
      latest_version = asset.latest_version
      latest_version.doi = '10.5072/my_test'
      assert latest_version.save
      assert asset.is_doi_minted?(latest_version.version)

      unpublic_sharing = { access_type: Policy::VISIBLE }

      put "/#{type.pluralize}/#{asset.id}", policy_attributes: unpublic_sharing

      assert_redirected_to :root
      assert_not_nil flash[:error]
    end
  end

  private

  def mock_datacite_request
    stub_request(:post, 'https://test.datacite.org/mds/metadata').with(basic_auth: ['test', 'test']).to_return(body: 'OK (10.5072/my_test)', status: 201)
    stub_request(:post, 'https://test.datacite.org/mds/doi').with(basic_auth: ['test', 'test']).to_return(body: 'OK', status: 201)
    stub_request(:post, 'https://test.datacite.org/mds/metadata').with(basic_auth: ['invalid', 'test']).to_return(body: '401 Bad credentials', status: 401)
  end

  def asset_url(asset)
    "#{root_url}data_files/#{asset.id}?version=#{asset.version}"
  end

  def login_as(user)
    User.current_user = user
    post '/session', login: user.login, password: 'blah'
  end
end
