require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  
  fixtures :projects, :institutions, :work_groups, :group_memberships, :people, :users
  
  #checks that the dependent work_groups are destoryed when the project s
  def test_delete_work_groups_when_project_deleted
    n_wg=WorkGroup.find(:all).size
    p=Project.find(2)
    assert_equal 1,p.work_groups.size
        
    p.work_groups.first.people=[]
    p.save!
    p.destroy
    
    assert_equal n_wg-1,WorkGroup.find(:all).size
    wg=WorkGroup.find(:all).first
    assert_same 1,wg.project_id
  end

  def test_projects_with_userless_people
    projects=Project.with_userless_people
    assert_not_nil projects, "The list should not be nil"
    assert projects.instance_of?(Array),"The results should be an array"
    assert projects.size>0, "There should be some projects in the list"
    p1 = projects(:one)    
    assert projects.include?(p1),"The list of projects that have userless people should include Project :one"
    p2 = projects(:two)      
    assert !projects.include?(p2), "Project :two should not be in the list of projects without users"
    p4 = projects(:four)
    assert !projects.include?(p4), "Project :four should not be included as it does not contain any people"
  end

  def test_userless_people
    proj1=projects(:one)
    assert_not_nil proj1.userless_people
    assert proj1.userless_people.size>0
    p3=people(:three)
    assert proj1.userless_people.include?(p3),"Project :one should include person :three as a userless person"

    proj2=projects(:two)
    assert_not_nil proj2.userless_people, "Even though a project does not contain userless people, it should return an empty list, not nil"
    assert_equal 0,proj2.userless_people.size,"Project :two should contain NO userless people"
    
  end

  def test_can_be_edited_by
    u=users(:can_edit)
    p=projects(:three)
    assert p.can_be_edited_by?(u),"Project :three should be editable by user :can_edit"

    p=projects(:four)
    assert !p.can_be_edited_by?(u),"Project :three should not be editable by user :can_edit as he is not a member"

    u=users(:quentin)
    assert p.can_be_edited_by?(u),"Project :three should be editable by user :quentin as he's an admin"
  end

  def test_cant_be_edited_by
    u=users(:cant_edit)
    p=projects(:three)
    assert !p.can_be_edited_by?(u),"Project :three should not be editable by user :cant_edit"
  end
  
end
