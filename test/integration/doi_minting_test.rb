require 'test_helper'

class DoiMintingTest < ActionDispatch::IntegrationTest
  include MockHelper

  # Only test the versioned types. Types with snapshots are tested separately.
  DOIABLE_ASSETS = Seek::Util.doiable_asset_types.select { |type| type.method_defined?(:versions) }.collect { |type| type.name.underscore }

  setup do
    @user = FactoryBot.create(:user, login: 'test')
    login_as(@user)
    doi_citation_mock
  end

  test 'doiable assets' do
    assert_equal %w(data_file document file_template model sop workflow), DOIABLE_ASSETS
  end

  test 'mint a DOI button' do
    DOIABLE_ASSETS.each do |type|
      asset = FactoryBot.create(type.to_sym, policy: FactoryBot.create(:public_policy))
      assert asset.find_version(1).can_mint_doi?

      get "/#{type.pluralize}/#{asset.id}?version=#{asset.version}"
      assert_response :success

      assert_select '#buttons' do
        assert_select 'a[href=?]', polymorphic_path(asset, action: 'mint_doi_confirm', version: 1), text: /Generate a DOI/
      end
    end
  end

  test 'hidden version can not mint a DOI' do
    DOIABLE_ASSETS.each do |type|
      asset = FactoryBot.create(type.to_sym, policy: FactoryBot.create(:public_policy))
      assert asset.find_version(1).can_mint_doi?
      login_as(asset.contributor.user)

      disable_authorization_checks do
        asset.save_as_new_version('new version')
      end

      assert :public, asset.find_version(1).visibility
      asset.find_version(2).update(visibility: :registered_users)
      assert_equal :registered_users, asset.find_version(2).reload.visibility
      refute asset.find_version(2).can_mint_doi?
    end
  end

  test 'get mint_doi_confirm' do
    DOIABLE_ASSETS.each do |type|
      asset = FactoryBot.create(type.to_sym, policy: FactoryBot.create(:public_policy))
      assert asset.is_published?
      assert asset.can_manage?
      versioned_asset = asset.latest_version

      asset.creators = [FactoryBot.create(:person)]
      asset.save

      get "/#{type.pluralize}/#{asset.id}/mint_doi_confirm?version=#{versioned_asset.version}"
      assert_response :success

      assert_select 'pre', text: versioned_asset.suggested_doi
    end
  end

  test 'authorization for mint_doi_confirm' do
    a_user = User.current_user = FactoryBot.create(:user, login: 'a_user')

    DOIABLE_ASSETS.each do |type|
      login_as(@user)
      asset = FactoryBot.create(type.to_sym, policy: FactoryBot.create(:private_policy), contributor: User.current_user.person)
      refute asset.is_published?
      assert asset.can_manage?
      assert asset.find_version(asset.version).can_mint_doi?

      get "/#{type.pluralize}/#{asset.id}/mint_doi_confirm?version=#{asset.version}"
      assert_response :redirect
      refute asset.find_version(asset.version).has_doi?

      asset.publish!
      assert asset.reload.is_published?

      login_as(a_user)
      assert_equal a_user, User.current_user
      refute asset.can_manage?

      get "/#{type.pluralize}/#{asset.id}/mint_doi_confirm?version=#{asset.version}"
      assert_response :redirect
      refute asset.find_version(asset.version).has_doi?
    end
  end

  test 'mint_doi' do
    mock_datacite_request
    DOIABLE_ASSETS.each do |type|
      asset = FactoryBot.create(type.to_sym, policy: FactoryBot.create(:public_policy))

      post "/#{type.pluralize}/#{asset.id}/mint_doi"
      assert_redirected_to polymorphic_path(asset, version: asset.version)
      assert_not_nil flash[:notice]

      assert AssetDoiLog.was_doi_minted_for?(asset.class.name, asset.id, asset.version)
    end
  end

  test 'handle error when mint_doi' do
    mock_datacite_request
    DOIABLE_ASSETS.each do |type|
      asset = FactoryBot.create(type.to_sym, policy: FactoryBot.create(:public_policy))

      with_config_value :datacite_username, 'invalid' do
        post "/#{type.pluralize}/#{asset.id}/mint_doi"
        assert_not_nil flash[:error]

        assert !AssetDoiLog.was_doi_minted_for?(asset.class.name, asset.id, asset.version)
      end
    end
  end

  test 'should show doi attribute for asset which doi is minted' do
    DOIABLE_ASSETS.each do |type|
      asset = FactoryBot.create(type.to_sym, policy: FactoryBot.create(:public_policy))
      doi = '10.5072/my_test'
      version = asset.latest_version
      version.doi = doi
      assert version.save

      get "/#{type.pluralize}/#{asset.id}?version=#{asset.version}"
      assert_response :success

      assert_select 'a', text: /#{doi}/
    end
  end

  test 'should show doi attribute on minted version' do
    DOIABLE_ASSETS.each do |type|
      asset = FactoryBot.create(type.to_sym, contributor: User.current_user.person)

      asset.save_as_new_version

      FactoryBot.create(:content_blob, asset: asset, asset_version: asset.version)

      asset.reload
      assert_equal 2, asset.version

      doi = '10.5072/my_test'
      version = asset.latest_version
      version.doi = doi
      assert version.save

      get "/#{type.pluralize}/#{asset.id}?version=2"
      assert_response :success
      assert_select 'a', text: /#{doi}/

      get "/#{type.pluralize}/#{asset.id}?version=1"
      assert_response :success

      assert_select 'a', text: /#{doi}/, count: 0
    end
  end

  test 'should log doi after doi is minted' do
    mock_datacite_request
    DOIABLE_ASSETS.each do |type|
      asset = FactoryBot.create(type.to_sym, policy: FactoryBot.create(:public_policy))

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

  test 'after DOI is minted, the -Upload new version- button is not disabled' do
    DOIABLE_ASSETS.each do |type|
      asset = FactoryBot.create(type.to_sym, policy: FactoryBot.create(:public_policy))
      latest_version = asset.latest_version
      latest_version.doi = '10.5072/my_test'
      assert latest_version.save
      assert latest_version.has_doi?

      get "/#{type.pluralize}/#{asset.id}"

      assert_select "a", text: /Register new version/
      assert_select "a[class='disabled']", text: /Register new version/, count:0
    end
  end

  test 'after DOI is minted, the -Delete- button is disabled' do
    DOIABLE_ASSETS.each do |type|
      asset = FactoryBot.create(type.to_sym, contributor: User.current_user.person, policy: FactoryBot.create(:private_policy))
      latest_version = asset.latest_version
      latest_version.doi = '10.5072/my_test'
      assert latest_version.save
      assert latest_version.has_doi?

      get "/#{type.pluralize}/#{asset.id}"

      assert_select "span[class='disabled_icon disabled']", text: /Delete/
    end
  end

  test 'can not delete asset after DOI is minted' do
    DOIABLE_ASSETS.each do |type|
      asset = FactoryBot.create(type.to_sym, contributor: User.current_user.person, policy: FactoryBot.create(:private_policy))
      latest_version = asset.latest_version
      latest_version.doi = '10.5072/my_test'
      assert latest_version.save
      assert latest_version.has_doi?

      delete "/#{type.pluralize}/#{asset.id}"

      assert_redirected_to asset
      assert_not_nil flash[:error]
    end
  end

  test 'after DOI is minted, disable the sharing_form options to unpublish the asset' do
    skip 'This test no longer works with the dynamic permissions form'

    DOIABLE_ASSETS.each do |type|
      asset = FactoryBot.create(type.to_sym, contributor: User.current_user.person, policy: FactoryBot.create(:public_policy))
      latest_version = asset.latest_version
      latest_version.doi = '10.5072/my_test'
      assert latest_version.save
      assert asset.has_doi?

      get "/#{type.pluralize}/#{asset.id}/edit"

      assert_select 'input[type=radio][disabled=true]', count: 2
    end
  end

  test 'can not unpublish asset after DOI is minted' do
    DOIABLE_ASSETS.each do |type|
      asset = FactoryBot.create(type.to_sym, contributor: User.current_user.person, policy: FactoryBot.create(:public_policy))
      latest_version = asset.latest_version
      latest_version.doi = '10.5072/my_test'
      assert latest_version.save
      assert latest_version.has_doi?

      unpublic_sharing = { access_type: Policy::VISIBLE }

      put "/#{type.pluralize}/#{asset.id}", params: { policy_attributes: unpublic_sharing }

      assert_redirected_to :root
      assert_not_nil flash[:error]
    end
  end

  test 'can update asset with DOI if current version does not have one' do
    asset = FactoryBot.create(:workflow, contributor: User.current_user.person, policy: FactoryBot.create(:public_policy))
    latest_version = asset.latest_version
    latest_version.doi = '10.5072/my_test'
    assert latest_version.save
    assert latest_version.has_doi?

    assert asset.save_as_new_version
    assert_nil asset.latest_version.doi

    put workflow_path(asset), params: { workflow: { title: 'test 123' }, policy_attributes: { access_type: Policy::ACCESSIBLE } }

    assert_nil flash[:error]
    assert_equal 'test 123', asset.reload.title
  end

  test 'cannot update asset with DOI to be private, even if current version does not have a DOI' do
    asset = FactoryBot.create(:workflow, contributor: User.current_user.person, policy: FactoryBot.create(:public_policy))
    latest_version = asset.latest_version
    latest_version.doi = '10.5072/my_test'
    assert latest_version.save
    assert latest_version.has_doi?

    assert asset.save_as_new_version
    assert_nil asset.latest_version.doi

    put workflow_path(asset), params: { workflow: { title: 'test 123' }, policy_attributes: { access_type: Policy::NO_ACCESS } }

    assert flash[:error].include?('not possible')
    assert_not_equal 'test 123', asset.reload.title
  end

  test 'mint doi for git-versioned workflow' do
    mock_datacite_request

    workflow = FactoryBot.create(:remote_git_workflow, policy: FactoryBot.create(:public_policy))
    assert_nil workflow.latest_git_version.doi
    refute workflow.latest_git_version.mutable?
    assert workflow.latest_git_version.can_mint_doi?

    post "/workflows/#{workflow.id}/mint_doi"
    assert_redirected_to polymorphic_path(workflow, version: workflow.version)
    assert_not_nil flash[:notice]

    assert AssetDoiLog.was_doi_minted_for?(workflow.class.name, workflow.id, workflow.version)
    assert_equal "10.5072/Sysmo.SEEK.workflow.#{workflow.id}.1", workflow.latest_git_version.doi
  end

  test 'cannot mint doi for git-versioned workflow if it is still mutable' do
    mock_datacite_request

    workflow = FactoryBot.create(:remote_git_workflow, policy: FactoryBot.create(:public_policy))
    workflow.latest_git_version.update_column(:mutable, true)
    assert_nil workflow.latest_git_version.doi
    assert workflow.latest_git_version.mutable?
    refute workflow.latest_git_version.can_mint_doi?

    post "/workflows/#{workflow.id}/mint_doi"

    assert flash[:error].include?('not possible')

    refute AssetDoiLog.was_doi_minted_for?(workflow.class.name, workflow.id, workflow.version)
    assert_nil workflow.latest_git_version.doi
  end

  private

  def mock_datacite_request
    stub_request(:post, 'https://mds.test.datacite.org/metadata').with(basic_auth: ['test', 'test']).to_return(body: 'OK (10.5072/my_test)', status: 201)
    stub_request(:post, 'https://mds.test.datacite.org/doi').with(basic_auth: ['test', 'test']).to_return(body: 'OK', status: 201)
    stub_request(:post, 'https://mds.test.datacite.org/metadata').with(basic_auth: ['invalid', 'test']).to_return(body: '401 Bad credentials', status: 401)
  end

  def asset_url(asset)
    "#{root_url}data_files/#{asset.id}?version=#{asset.version}"
  end

  def login_as(user)
    User.current_user = user
    post '/session', params: { login: user.login, password: generate_user_password }
  end
end
