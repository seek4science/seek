require File.dirname(__FILE__) + '/../test_helper'

class HomeControllerTest < ActionController::TestCase
  fixtures :people, :users

  include AuthenticatedTestHelper
  def setup
    login_as(:quentin)
  end

  def test_title
    get :index
    assert_select "title",:text=>/Sysmo SEEK.*/, :count=>1
  end

end
