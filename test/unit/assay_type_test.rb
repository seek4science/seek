require 'test_helper'

class AssayTypeTest < ActiveSupport::TestCase
  fixtures :assay_types

  test "parent and child" do
    parent=assay_types(:parent)

    assert_equal 2,parent.child_assay_types.size
    child1=assay_types(:child1)
    child2=assay_types(:child2)

    assert parent.child_assay_types.include?(child1)
    assert parent.child_assay_types.include?(child2)

    assert_equal parent,child1.parent_assay_type
    assert_equal parent,child2.parent_assay_type
  end
  
end
