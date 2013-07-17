require 'test_helper'


class AssetButtonsTest < ActionController::IntegrationTest
  ASSETS = %w[investigations studies assays data_files models sops samples specimens strains presentations events]
  def setup
    User.current_user = Factory(:user, :login => 'test')
    @current_user = User.current_user
    post '/session', :login => 'test', :password => 'blah'
  end

  test 'show delete' do
    ASSETS.each do |type_name|
      if type_name == "assays"
        contributor = @current_user.person
        human_name = I18n.t('assays.modelling_analysis').humanize
      else
        contributor = @current_user
        human_name = type_name.singularize.humanize
      end
      item = Factory(type_name.singularize.to_sym, :contributor => contributor,
                                                   :policy => Factory(:all_sysmo_viewable_policy))
      assert item.can_delete?, "This item is deletable for the test to pass"

      get "/#{type_name}/#{item.id}"
      assert_response :success
      assert_select "span.icon" do
        assert_select "a", :text => /Delete #{human_name}/
      end

        delete "/#{type_name}/#{item.id}"
      assert_redirected_to eval("#{type_name}_path"),'Should redirect to index page after deleting'
      assert_nil flash[:error]
    end
  end

end
