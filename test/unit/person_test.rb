require 'test_helper'

class PersonTest < ActiveSupport::TestCase
  fixtures :people, :projects,:institutions, :work_groups, :people_work_groups
  
  # Replace this with your real tests.
  def test_work_groups
    p=people(:one)
    assert_equal 2,p.work_groups.size
  end
  
  def test_institutions
    p=people(:one)
    assert_equal 2,p.institutions.size
    
    p=people(:two)
    assert_equal 2,p.work_groups.size
    assert_equal 2,p.projects.size
    assert_equal 1,p.institutions.size
  end
  
  def test_projects
    p=people(:one)
    assert_equal 2,p.projects.size
  end
end
