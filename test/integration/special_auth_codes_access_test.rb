require 'test_helper'


class SpecialAuthCodesAccessTest < ActionController::IntegrationTest
  ASSETS_WITH_AUTH_CODES = %w[data_files events models sops samples specimens presentations]

  def setup
    User.current_user = Factory(:user, :login => 'test')
    post '/sessions/create', :login => 'test', :password => 'blah'
    Seek::Config.is_virtualliver = true
  end

  test 'form allows creating temporary access links' do
    ASSETS_WITH_AUTH_CODES.each do |type_name|
      p type_name
      get "/#{type_name}/new"
      assert_select "form div#temporary_links"

      get "/#{type_name}/#{Factory(type_name.singularize.to_sym, :policy => Factory(:public_policy)).id}/edit"
        assert_select "form div#temporary_links"
    end
  end

  test 'anonymous visitors can use access codes to show or download an item' do
    ASSETS_WITH_AUTH_CODES.each do |type_name|
      item = Factory(type_name.singularize.to_sym, :contributor => User.current_user)
      item.special_auth_codes << Factory(:special_auth_code, :asset => item)
      p type_name
      get "/sessions/destroy"

      get "/#{type_name}/show/#{item.id}?code=#{item.special_auth_codes.first.code}"
      assert_response :success

      if item.is_downloadable?
        get "/#{type_name}/download/#{item.id}?code=#{item.special_auth_codes.first.code}"
        assert_response :success
      end
    end
  end
end
