require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  
  fixtures :projects, :institutions, :work_groups
  
  #checks that the dependent work_groups are destoryed when the project s
  def test_delete_work_groups_when_project_deleted
    assert_equal 2, WorkGroup.find(:all).size
    p=Project.find(2)
    assert_equal 1,p.work_groups.size
    p.destroy
    assert_equal 1,WorkGroup.find(:all).size
    wg=WorkGroup.find(:all).first
    assert_same 1,wg.project_id
  end
  
end
