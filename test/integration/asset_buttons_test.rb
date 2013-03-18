require 'test_helper'


class AssetButtonsTest < ActionController::IntegrationTest
  ASSETS = %w[investigations studies assays data_files models sops samples specimens strains presentations events]
  def setup
    User.current_user = Factory(:user, :login => 'test')
    @current_user = User.current_user
    post '/sessions/create', :login => 'test', :password => 'blah'
  end

  test 'show delete' do
    ASSETS.each do |type_name|
      if type_name == "assays"
        contributor = @current_user.person
        human_name = 'Modelling analysis'
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

  test 'should not delete if item is published' do
    ASSETS.each do |type_name|
      if type_name == "assays"
        contributor = @current_user.person
        human_name = 'Modelling analysis'
      else
        contributor = @current_user
        human_name = type_name.singularize.humanize
      end
      item = Factory(type_name.singularize.to_sym, :contributor => contributor,
                     :policy => Factory(:public_policy))
      assert item.is_published?,"This item is published for the test to pass"
      assert item.can_manage?,"This item is manageable for the test to bemeaningful"
      assert !item.can_delete?,"This item is not deletable for the test to pass"

      get "/#{type_name}/#{item.id}"
      assert_response :success
      assert_select "span.disabled_icon", :text => /Delete #{human_name}/

      delete "/#{type_name}/#{item.id}"
      assert_redirected_to item,'Should redirect to item when not being authorized to delete'
      assert_not_nil flash[:error]
    end
  end
end
