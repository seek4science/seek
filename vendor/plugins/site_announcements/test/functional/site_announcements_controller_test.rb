require 'test_helper.rb'
require 'app/controllers/application'
require 'app/controllers/site_announcements_controller'
require 'action_controller/test_process'

class SiteAnnouncementsController; def rescue_action(e) raise e end; end

class SiteAnnouncementsController; def can_manage_announcements?() true end; end
class SiteAnnouncementsController; def login_required() true end; end

class SiteAnnouncementsControllerTest < ActionController::TestCase  
  load_schema
  
  def test_new
    get :new
    assert_response :success
  end
end
