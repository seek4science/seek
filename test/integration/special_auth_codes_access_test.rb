require 'test_helper'


class SpecialAuthCodesAccessTest < ActionController::IntegrationTest
  ASSETS_WITH_AUTH_CODES = %w[data_files events models sops samples specimens presentations]

  test 'form allows creating temporary access links' do
    User.current_user = Factory(:user, :login => 'test')
    post '/sessions/create', :login => 'test', :password => 'blah'
    ASSETS_WITH_AUTH_CODES.each do |type_name|
      get "/#{type_name}/new"
      assert_select "form div#temporary_links", :count => 0

      get "/#{type_name}/#{Factory(type_name.singularize.to_sym, :policy => Factory(:public_policy)).id}/edit"
      assert_select "form div#temporary_links"
    end
  end

  test 'anonymous visitors can use access codes to show or download an item' do
    ASSETS_WITH_AUTH_CODES.each do |type_name|
      item = Factory(type_name.singularize.to_sym, :policy => Factory(:private_policy))
      item.special_auth_codes << Factory(:special_auth_code, :asset => item)

      code = CGI::escape(item.special_auth_codes.first.code)
      get "/#{type_name}/show/#{item.id}?code=#{code}"
      assert_response :success

      if item.is_downloadable?
        get "/#{type_name}/download/#{item.id}?code=#{code}"
        assert_response :success
      end
    end
  end
end
