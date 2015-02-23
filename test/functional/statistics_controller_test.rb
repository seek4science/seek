require 'test_helper'

class StatisticsControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  def test_content_statistic
    user = Factory :user
    login_as user
    get :index
    assert_response :success
    assert_select "h1",:text=>/Statistics/, :count=>1
    assert_select "h3",:text=>/Content statistics/, :count=>1
  end

  test "anonymous_user_cannot_view_content_statistic" do
    logout
    get :index
    assert_response :success
    assert_select "h3",:text=>/Content statistics/, :count=>0
  end

  test "application status" do
    with_config_value :application_name,"Euro SEEK" do
      with_config_value :solr_enabled,true do
        logout
        get :application_status
        assert_response :success

        assert_select "div#application_status",:text=>/Euro SEEK is running/
        assert_select "div#application_status",:text=>/search is enabled/
        assert_select "div#application_status",:text=>/[0-9] delayed jobs running/
      end
    end
  end

end