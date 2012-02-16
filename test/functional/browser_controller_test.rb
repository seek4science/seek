require 'test_helper'

class BrowserControllerTest < ActionController::TestCase
  fixtures :all
  include AuthenticatedTestHelper

  def setup
    @member = Factory :user
    @project = @member.person.projects.first
    login_as @member
  end

  test "routes" do
    assert_generates "/projects/1/browser", {:controller=>"browser",:action=>"index",:project_id=>"1"}
  end

  test "access as member" do
    get :index,:project_id=>@project.id
    assert_response :success
  end

  test "defaults created" do
    assert ProjectFolder.root_folders(@project).empty?

    get :index,:project_id=>@project.id

    assert !ProjectFolder.root_folders(@project).empty?
  end


  test "defaults not created if exist" do
    folder=Factory :project_folder,:project=>@project
    assert_equal 1,ProjectFolder.root_folders(@project).count
    assert_no_difference("ProjectFolder.count") do
      get :index,:project_id=>@project.id
    end
    assert_equal 1,ProjectFolder.root_folders(@project).count
  end


  test "blocked access as non member" do
    login_as(:quentin)
    get :index,:project_id=>@project.id
    assert_redirected_to root_path
    assert_not_nil flash[:error]
  end

  test "should not show when logged out" do
    logout
    get :index,:project_id=>@project.id
    assert_redirected_to login_path
  end
end
