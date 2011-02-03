require 'test_helper'

class WorkGroupTest < ActiveSupport::TestCase
  fixtures :people, :projects,:institutions, :work_groups, :group_memberships
  
  def test_people
    wg=WorkGroup.find(1)
    assert_equal 2,wg.people.size
  end
  
  def test_cannot_destroy_with_people
    wg=WorkGroup.find(1)
    assert !wg.people.empty?
    
    
    #todo how to check message?
    assert_raise(Exception) {wg.destroy}
  end
  
  def test_can_destroy_with_no_people  
    wg=WorkGroup.find(1)
    wg.people=[]
    assert wg.people.empty?
    wg.destroy
  end
  
  def test_description
    wg=work_groups(:one)
    assert_equal "Project1 at Institution1",wg.description
  end
  
end

