require 'test_helper'

class SpecialAuthCodesAccessTest < ActionDispatch::IntegrationTest
  ASSETS_WITH_AUTH_CODES = %w[data_files events models sops presentations].freeze

  ASSETS_WITH_AUTH_CODES.each do |type_name|
    test "form allows creating temporary access links for #{type_name}" do
      User.with_current_user(Factory(:user, login: 'test')) do
        post '/session', params: { login: 'test', password: generate_user_password }

        get "/#{type_name}/new"
        assert_select 'form div#temporary_links', count: 0

        get "/#{type_name}/#{Factory(type_name.singularize.to_sym, policy: Factory(:public_policy)).id}/manage"
        assert_select 'form div#temporary_links'
      end
    end
  end

  ASSETS_WITH_AUTH_CODES.each do |type_name|
    test "anonymous visitors can use access codes to show or download #{type_name}" do
      item = Factory(type_name.singularize.to_sym, policy: Factory(:private_policy))
      disable_authorization_checks do
        User.with_current_user(item.contributor.user) do
          item.special_auth_codes << Factory(:special_auth_code, asset: item)
        end
      end

      code = CGI.escape(item.special_auth_codes.first.code)
      get "/#{type_name}/#{item.id}?code=#{code}"
      assert_response :success, "failed for asset #{type_name}"

      if item.is_downloadable?
        test_passing_for item, type_name, 'download', code
      end
    end
  end

  ASSETS_WITH_AUTH_CODES.each do |type_name|
    test "anonymous visitors can not see or download #{type_name} without code" do
      item = Factory(type_name.singularize.to_sym, policy: Factory(:private_policy))

      get "/#{type_name}/#{item.id}"
      assert_response :forbidden

      test_failing_for item, type_name, 'download', nil if item.is_downloadable?
    end
  end

  ASSETS_WITH_AUTH_CODES.each do |type_name|
    test "anonymous visitors can see or download #{type_name} with wrong code" do
      item = Factory(type_name.singularize.to_sym, policy: Factory(:private_policy))
      disable_authorization_checks do
        User.with_current_user(item.contributor.user) do
          item.special_auth_codes << Factory(:special_auth_code, asset: item)
        end
      end
      random_code = CGI.escape(SecureRandom.base64(30))
      get "/#{type_name}/#{item.id}?code=#{random_code}"
      assert_response :forbidden

      if item.is_downloadable?
        test_failing_for item, type_name, 'download', random_code
      end
    end
  end

  ASSETS_WITH_AUTH_CODES.each do |type_name|
    test "auth codes allow access to private #{type_name} until they expire" do
      item = Factory(type_name.singularize.to_sym, policy: Factory(:private_policy))

      auth_code = User.with_current_user(item.contributor.user) do
        Factory :special_auth_code, expiration_date: (Time.now + 1.days), asset: item
      end

      # test without code instead of can_...? function
      get "/#{type_name}/#{item.id}"
      assert_response :forbidden

      test_failing_for item, type_name, 'download', nil if item.is_downloadable?

      code = CGI.escape(auth_code.code)
      get "/#{type_name}/#{item.id}?code=#{code}"
      assert_response :success, "failed for asset #{type_name}"

      if item.is_downloadable?
        test_passing_for item, type_name, 'download', code
      end

      User.with_current_user(item.contributor.user) do
        disable_authorization_checks { auth_code.expiration_date = Time.now - 1.days; auth_code.save! }
      end

      item.reload
      get "/#{type_name}/#{item.id}?code=#{code}"
      assert_response :forbidden

      if item.is_downloadable?
        test_failing_for item, type_name, 'download', code
      end
    end
  end

  test 'should be able to explore excel datafile with auth code' do
    item = Factory(:small_test_spreadsheet_datafile, policy: Factory(:private_policy))
    auth_code = User.with_current_user(item.contributor.user) do
      Factory :special_auth_code, expiration_date: (Time.now + 1.days), asset: item
    end

    get "/data_files/#{item.id}/explore"
    assert_redirected_to item
    assert_not_nil flash[:error]

    code = CGI.escape(auth_code.code)
    get "/data_files/#{item.id}/explore?code=#{code}"
    assert_response :success
  end

  test 'should be able to view content of sop with auth code' do
    item = Factory(:pdf_sop, policy: Factory(:private_policy))
    auth_code = User.with_current_user(item.contributor.user) do
      Factory :special_auth_code, expiration_date: (Time.now + 1.days), asset: item
    end

    get "/sops/#{item.id}/content_blobs/#{item.content_blob.id}/view_pdf_content"
    assert_redirected_to item
    assert_not_nil flash[:error]

    code = CGI.escape(auth_code.code)
    get "/sops/#{item.id}/content_blobs/#{item.content_blob.id}/view_pdf_content?code=#{code}"
    assert_response :success
  end

  ASSETS_WITH_AUTH_CODES.each do |type_name|
    test "should display unexpired temporary link of #{type_name} for manager" do
      user = Factory(:user)
      User.with_current_user user do
        item = Factory(type_name.singularize.to_sym, policy: Factory(:private_policy), contributor: user.person)
        disable_authorization_checks do
          item.special_auth_codes << Factory(:special_auth_code, asset: item)
        end

        post '/session', params: { login: user.login, password: user.password }

        get "/#{type_name}/#{item.id}"

        assert_response :success, "failed for asset #{type_name}"
        assert_select 'p > b', text: /Temporary access link:/, count: 1
      end
    end
  end

  ASSETS_WITH_AUTH_CODES.each do |type_name|
    test "should not display unexpired temporary link of #{type_name} for non-manager" do
      user = Factory(:user)
      User.with_current_user user do
        item = Factory(type_name.singularize.to_sym, policy: Factory(:publicly_viewable_policy), contributor: user.person)
        item.special_auth_codes << Factory(:special_auth_code, asset: item)
        user = Factory(:user)

        post '/session', params: { login: user.login, password: user.password }
        get "/#{type_name}/#{item.id}"

        assert_response :success, "failed for asset #{type_name}"
        assert_select 'p > b', text: /Temporary access link:/, count: 0
      end
    end
  end

  private

  def test_failing_for(item, type_name, action, code = nil)
    if Seek::Util.is_multi_file_asset_type?(item.class)
      # download multiple files
      get "/#{type_name}/#{item.id}/#{action}/?code=#{code}"
      assert_redirected_to item
      assert_not_nil flash[:error]

      # download each file
      item.content_blobs.each do |cb|
        get "/#{type_name}/#{item.id}/content_blobs/#{cb.id}/#{action}?code=#{code}"
        assert_redirected_to item
        assert_not_nil flash[:error]
      end
    else
      # download one file asset
      get "/#{type_name}/#{item.id}/content_blobs/#{item.content_blob.id}/#{action}?code=#{code}"
      assert_redirected_to item
      assert_not_nil flash[:error]
    end
  end

  def test_passing_for(item, type_name, action, code = nil)
    if Seek::Util.is_multi_file_asset_type?(item.class)
      # download multiple files
      get "/#{type_name}/#{item.id}/#{action}/?code=#{code}"
      assert_response :success, "failed for asset #{type_name}"

      # download each file
      item.content_blobs.each do |cb|
        get "/#{type_name}/#{item.id}/content_blobs/#{cb.id}/#{action}?code=#{code}"
        assert_response :success, "failed for asset #{type_name}"
      end
    else
      # download one file asset
      get "/#{type_name}/#{item.id}/content_blobs/#{item.content_blob.id}/#{action}?code=#{code}"
      assert_response :success, "failed for asset #{type_name}"
    end
  end
end
