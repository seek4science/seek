require 'test_helper'


class SpecialAuthCodesAccessTest < ActionController::IntegrationTest
  ASSETS_WITH_AUTH_CODES = %w[data_files events models sops samples specimens presentations]

  ASSETS_WITH_AUTH_CODES.each do |type_name|
    test "form allows creating temporary access links for #{type_name}" do
      User.current_user = Factory(:user, :login => 'test')
      post '/sessions/create', :login => 'test', :password => 'blah'

      get "/#{type_name}/new"
      assert_select "form div#temporary_links", :count => 0

      get "/#{type_name}/#{Factory(type_name.singularize.to_sym, :policy => Factory(:public_policy)).id}/edit"
      assert_select "form div#temporary_links"
    end
  end

  ASSETS_WITH_AUTH_CODES.each do |type_name|
    test "anonymous visitors can use access codes to show or download #{type_name}" do

      item = Factory(type_name.singularize.to_sym, :policy => Factory(:private_policy))
      item.special_auth_codes << Factory(:special_auth_code, :asset => item)

      code = CGI::escape(item.special_auth_codes.first.code)
      get "/#{type_name}/show/#{item.id}?code=#{code}"
      assert_response :success, "failed for asset #{type_name}"

      if item.is_downloadable?
        get "/#{type_name}/download/#{item.id}?code=#{code}"
        assert_response :success, "failed for asset #{type_name}"
      end
    end
  end
end
