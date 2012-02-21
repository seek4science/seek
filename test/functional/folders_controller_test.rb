require 'test_helper'

class FoldersControllerTest < ActionController::TestCase
  fixtures :all
  include AuthenticatedTestHelper

  def setup
    @member = Factory :user
    @project = @member.person.projects.first
    login_as @member
  end

  test "routes" do
    assert_generates "/projects/1/folders", {:controller=>"folders",:action=>"index",:project_id=>"1"}
    assert_generates "/projects/1/folders/7", {:controller=>"folders",:action=>"show",:project_id=>"1",:id=>"7"}
  end

  test "access as member" do
    get :index,:project_id=>@project.id
    assert_response :success
  end

  test "defaults created and old items assigned" do
    sop = Factory :sop, :projects=>[@project],:policy=>Factory(:public_policy)
    sop2 = Factory :sop, :projects=>[Factory(:project)],:policy=>Factory(:public_policy)
    assert ProjectFolder.root_folders(@project).empty?

    assert_difference("ProjectFolderAsset.count") do
      get :index,:project_id=>@project.id
    end

    @project.reload
    assert !ProjectFolder.root_folders(@project).empty?
    assert ProjectFolder.new_items_folder(@project).assets.include?(sop)
    assert !ProjectFolder.new_items_folder(@project).assets.include?(sop2)
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

  test "ajax request for folder contents" do
    sop = Factory :sop, :projects=>[@project],:policy=>Factory(:public_policy),:description=>"Ryz9z3Z9h70wzJ243we6k8RO5xI5f3UF"
    folder = Factory :project_folder, :project=>@project
    folder.add_assets(sop)
    folder.save!

    xhr(:post,:display_contents,{:id=>folder.id,:project_id=>folder.project.id})

    assert_response :success

    assert @response.body.match(/Description.*Ryz9z3Z9h70wzJ243we6k8RO5xI5f3UF/)
  end

  test "ajax request for folder contents rejected from non project member" do
    login_as Factory(:user)
    sop = Factory :sop, :projects=>[@project],:policy=>Factory(:public_policy),:description=>"Ryz9z3Z9h70wzJ243we6k8RO5xI5f3UF"
    folder = Factory :project_folder, :project=>@project
    folder.add_assets(sop)
    folder.save!

    xhr(:post,:display_contents,{:id=>folder.id,:project_id=>folder.project.id})
    assert_redirected_to root_path
    assert @response.body.match(/Description.*Ryz9z3Z9h70wzJ243we6k8RO5xI5f3UF/).nil?
  end

  test "authorization on assets" do
    sop = Factory :sop, :projects=>[@project],:policy=>Factory(:public_policy),:description=>"Ryz9z3Z9h70wzJ243we6k8RO5xI5f3UF"
    hidden_sop = Factory :sop,:projects=>[@project],:policy=>Factory(:private_policy),:description=>"viu2q6ng3iZ0ppS5X679pPo11LfF62pS"
    folder = Factory :project_folder, :project=>@project

    disable_authorization_checks do
      folder.add_assets([sop,hidden_sop])
      folder.save!
    end

    xhr(:post,:display_contents,{:id=>folder.id,:project_id=>folder.project.id})

    assert_response :success
    assert @response.body.match(/Ryz9z3Z9h70wzJ243we6k8RO5xI5f3UF/)
    assert @response.body.match(/viu2q6ng3iZ0ppS5X679pPo11LfF62pS/).nil?
  end

end
