require 'test_helper'

class InstitutionTest < ActiveSupport::TestCase
  fixtures :institutions,:projects,:work_groups
  # Replace this with your real tests.
  def test_delete_inst_deletes_workgroup
    assert_equal 2, WorkGroup.find(:all).size
    assert_equal 2,Institution.find(:all).size
    
    i=Institution.find(1)
    assert_equal 1,i.work_groups.size
    i.destroy
    assert_equal 1,Institution.find(:all).size
    assert_equal 1, WorkGroup.find(:all).size, "the workgroup should also have been destroyed"
  end
end
