require 'test_helper'

class ProjectFolderTest < ActiveSupport::TestCase


  test "validation" do
    pf = ProjectFolder.new
    assert !pf.valid?
    pf.project = Factory :project
    assert !pf.valid?
    pf.title = "fred"
    assert pf.valid?
    pf.project=nil
    assert !pf.valid?
  end

  test "add child" do
     pf = Factory :project_folder

     pf2 = ProjectFolder.new :title=>"one"
     pf3 = ProjectFolder.new :title=>"two"

     pf.children << pf2
     pf.children << pf3
     assert_equal pf,pf2.parent
     assert_equal pf.project,pf2.project
     assert_equal pf,pf3.parent
     assert_equal pf.project,pf3.project

     pf.save!

     pf.reload

     assert_equal 2,pf.children.count
     assert_equal pf.project, pf.children[0].project
     assert_equal pf.project, pf.children[1].project

     assert_equal pf, pf.children[0].parent
     assert_equal pf, pf.children[1].parent

     assert_equal "one",pf.children[0].title
     assert_equal "two",pf.children[1].title
  end

  test "root folders" do
    project = Factory :project
    assert ProjectFolder.root_folders(project).empty?
    root1=nil
    root2=nil
    assert_difference("ProjectFolder.count",10) do
      root1 = Factory :project_folder,:project=>project
      root2 = Factory :project_folder,:project=>project
      root1.children << Factory(:project_folder,:project=>project)
      root1.children << Factory(:project_folder,:project=>project)
      root1.children << Factory(:project_folder,:project=>project)
      root1.children.first.children << Factory(:project_folder,:project=>project)
      root2.children << Factory(:project_folder,:project=>project)
      root1.children.first.children << Factory(:project_folder,:project=>project)
      root1.children.first.children << Factory(:project_folder,:project=>project)
      root1.children.first.children << Factory(:project_folder,:project=>project)
    end

    roots = ProjectFolder.root_folders project
    assert_equal 2,roots.count
    assert roots.include?(root1)
    assert roots.include?(root2)
  end

  test "initialise defaults" do

    project = Factory :project
    default_file = File.join Rails.root,"test","fixtures","files","default_project_folders.yml"

    root_folders=nil
    assert_difference("ProjectFolder.count",7) do
      root_folders = ProjectFolder.initialize_defaults project,default_file
    end

    assert_equal 3,root_folders.count
    first_root = root_folders.first
    assert_equal "data files",first_root.title
    assert first_root.editable
    assert_equal 1,first_root.children.count
    assert_equal "raw data files",first_root.children.first.title
    assert_equal 0, first_root.children.first.children.count

    second_root = root_folders[1]
    assert_equal "models",second_root.title
    assert second_root.editable
    assert_equal 2,second_root.children.count
    assert_equal "copasi",second_root.children.first.title
    assert_equal "sbml",second_root.children[1].title

    assert_equal 1,second_root.children[1].children.count
    assert_equal "in development",second_root.children[1].children.first.title

    third_root=root_folders[2]
    assert !third_root.editable
    assert "new items",third_root.title

    #don't check the actual contents from the real file, but check it works sanely and exists
    project2 = Factory :project
    root_folders = ProjectFolder.initialize_defaults project2
    assert !root_folders.empty?

    #check exception raised if folders already exist
    folder = Factory :project_folder
    assert_raise Exception do
      ProjectFolder.initialize_defaults folder.project
    end


  end

end
