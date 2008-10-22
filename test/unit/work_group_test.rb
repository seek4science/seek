require 'test_helper'
 

class WorkGroupTest < ActiveSupport::TestCase
  fixtures :people, :projects,:institutions, :work_groups, :people_work_groups
  
  def test_people
    wg=WorkGroup.find(1)
    assert_equal 2,wg.people.size
  end
  
  def test_cannot_destroy_with_people
    wg=WorkGroup.find(1)
    assert !wg.people.empty?
    p=wg.people.first
    assert_equal 1,p.work_groups.size
    
    #todo how to check message?
    assert_raise(Exception) {wg.destroy}
  end
  
  def test_can_destroy_with_no_people  
    wg=WorkGroup.find(1)
    wg.people=[]
    assert wg.people.empty?
    wg.destroy
  end
  
end

