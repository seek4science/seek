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

  test "update" do
    login_as(Factory(:admin))
    prog = Factory(:programme,:description=>"ggggg")
    put :update, :id=>prog, :programme=>{:title=>"fish"}
    prog = assigns(:programme)
    refute_nil prog
    assert_redirected_to prog
    assert_equal "fish",prog.title
    assert_equal "ggggg",prog.description
  end

  test "edit page accessible to admin" do
    login_as(Factory(:admin))
    p = Factory(:programme)
    Factory(:avatar,:owner=>p)
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
    p = Factory(:programme,:projects=>[Factory(:project),Factory(:project)])
    avatar = Factory(:avatar,:owner=>p)
    p.avatar = avatar
    p.save!
    Factory(:programme)

    get :index
    assert_response :success
  end

  test "should get show" do
    p = Factory(:programme,:projects=>[Factory(:project),Factory(:project)])
    avatar = Factory(:avatar,:owner=>p)
    p.avatar = avatar
    p.save!

    get :show,:id=>p
    assert_response :success
  end

  test "update to default avatar" do
    p = Factory(:programme,:projects=>[Factory(:project),Factory(:project)])
    avatar = Factory(:avatar,:owner=>p)
    p.avatar = avatar
    p.save!
    login_as(Factory(:admin))
    put :update, :id=>p, :programme=>{:avatar_id=>"0"}
    prog = assigns(:programme)
    refute_nil prog
    assert_nil prog.avatar
  end

  test "can be disabled" do
    p = Factory(:programme,:projects=>[Factory(:project),Factory(:project)])
    with_config_value :programmes_enabled,false do
      get :show,:id=>p
      assert_redirected_to :root
      refute_nil flash[:error]
    end
  end

end
