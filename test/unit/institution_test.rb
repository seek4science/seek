require 'test_helper'

class InstitutionTest < ActiveSupport::TestCase
  fixtures :institutions,:projects,:work_groups,:users,:group_memberships, :people
  # Replace this with your real tests.
  def test_delete_inst_deletes_workgroup
    n_wg = WorkGroup.find(:all).size
    n_inst = Institution.find(:all).size
    
    i=Institution.find(1)
    
    assert_equal 1,i.work_groups.size

    i.work_groups.first.people=[]
    i.destroy
    assert_equal (n_inst-1),Institution.find(:all).size
    assert_equal (n_wg-1), WorkGroup.find(:all).size, "the workgroup should also have been destroyed"
  end

  def test_ordered_by_name
    assert Institution.find(:all).sort_by {|i| i.name.downcase} == Institution.find(:all) || Institution.all.sort_by {|i|i.name} == Institution.all
  end

  def test_avatar_key
    i=institutions(:one)
    assert_nil i.avatar_key
    assert i.defines_own_avatar?
  end

  def test_title_trimmed
    i=Institution.new(:title=>" an institution")
    i.save!
    assert_equal("an institution",i.title) 
  end
  
  def test_update_first_letter
    i=Institution.new(:name=>"an institution")
    i.save
    assert_equal "A",i.first_letter
  end

  def test_can_be_edited_by
    u=users(:can_edit)
    i=institutions(:two)
    assert i.can_be_edited_by?(u),"Institution :two should be editable by user :can_edit"

    i=institutions(:one)
    assert !i.can_be_edited_by?(u),"Institution :one should not be editable by user :can_edit as he is not a member"

    u=users(:project_manager)
    i=institutions(:two)
    assert i.can_be_edited_by?(u),"Institution :two should be editable by user :project_manager"

    i=institutions(:one)
    assert !i.can_be_edited_by?(u),"Institution :one should not be editable by user :project_manager as he is not a member"

    u=users(:quentin)
    assert i.can_be_edited_by?(u),"Institution :one should be editable by user :quentin as he's an admin"

    u=users(:cant_edit)
    i=institutions(:two)
    assert !i.can_be_edited_by?(u),"Institution :two should not be editable by user :cant_edit"
  end

  def test_valid
    i=institutions(:one)
    assert i.valid?

    i.name=nil
    assert !i.valid?

    i.name=""
    assert !i.valid?

    i.name="Name"
    assert i.valid?

    i.web_page=nil
    assert i.valid?

    i.web_page=""
    assert i.valid?

    i.web_page="sdfsdf"
    assert !i.valid?

    i.web_page="http://google.com"
    assert i.valid?

    i.web_page="https://google.com"
    assert i.valid?

    i.web_page="http://google.com/fred"
    assert i.valid?

    i.web_page="http://google.com/fred?param=bob"
    assert i.valid?

    i.web_page="http://www.mygrid.org.uk/dev/issues/secure/IssueNavigator.jspa?reset=true&mode=hide&sorter/order=DESC&sorter/field=priority&resolution=-1&pid=10051&fixfor=10110"
    assert i.valid?


  end

  test "test uuid generated" do
    i = institutions(:one)
    assert_nil i.attributes["uuid"]
    i.save
    assert_not_nil i.attributes["uuid"]
  end 
  
  test "uuid doesn't change" do
    x = institutions(:one)
    x.save
    uuid = x.attributes["uuid"]
    x.save
    assert_equal x.uuid, uuid
  end
end
