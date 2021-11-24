require 'test_helper'

class StatisticsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  test 'admin can view statistics' do
    user = Factory :admin
    login_as user
    get :index
    assert_response :success
    assert_select 'h1', text: /Statistics/, count: 1
    assert_select 'h3', text: /Content statistics/, count: 1
  end

  test 'normal user cannot view statistics' do
    user = Factory :user
    login_as user
    get :index
    assert_response :redirect
  end

  test 'anonymous user cannot view content statistics' do
    logout
    get :index
    assert_response :redirect
  end

  test 'application status' do
    ApplicationStatus.delete_all
    soffice = Seek::Config.soffice_available? ? 'running' : 'not running'
    with_config_value :instance_name, 'Euro SEEK' do
      with_config_value :solr_enabled, true do
        logout
        assert_difference('ApplicationStatus.count') do
          get :application_status
        end
        assert_response :success
        assert_match(/Euro SEEK is running \| search is enabled \| [0-9] delayed jobs running \| soffice is #{soffice}/, @response.body)
      end
    end
  end
end
