require 'test_helper'

class PersonTest < ActiveSupport::TestCase
  fixtures :people, :projects,:institutions, :work_groups, :people_work_groups
  
  # Replace this with your real tests.
  def test_work_groups
    assert true
  end
end
