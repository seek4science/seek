require File.dirname(__FILE__) + '/test_helper.rb'
require 'app/controllers/site_announcements_controller'
require 'action_controller/test_process'

class SiteAnnouncementsController; def rescue_action(e) raise e end; end

class SiteAnnouncementsControllerTest < Test::Unit::TestCase
  def setup
    @controller = SiteAnnouncementsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new

    ActionController::Routing::Routes.draw do |map|
      map.resources :site_announcements
    end
  end

  def test_new
    get :new
    assert_response :success
  end
end
