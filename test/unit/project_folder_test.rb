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

end
