require 'test_helper'

class ProgrammesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  #for now just admins can create programmes, later we will change this
  test "new page accessible admin" do
    login_as(Factory(:admin))
    get :new
    assert_response :success
  end

  test "new page not accessible to non admin" do
    login_as(Factory(:person))
    get :new
    assert_redirected_to :root
    refute_nil flash[:error]
  end


  test "edit page accessible to admin" do
    login_as(Factory(:admin))
    p = Factory(:programme)
    get :edit, :id=>p
    assert_response :success

  end

  test "edit page not accessible to non-admin" do
    login_as(Factory(:person))
    p = Factory(:programme)
    get :edit, :id=>p
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test "should show index" do
    get :index
    assert_response :success
  end

  test "should get show" do
    p = Factory(:programme)
    get :show,:id=>p
    assert_response :success
  end

end
