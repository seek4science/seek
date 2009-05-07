require 'test_helper'

class AssayTypeTest < ActiveSupport::TestCase
  fixtures :assay_types

#  test "parent and child" do
#    parent=assay_types(:parent)
#
#    assert_equal 2,parent.child_assay_types.size
#    child1=assay_types(:child1)
#    child2=assay_types(:child2)
#
#    assert parent.child_assay_types.include?(child1)
#    assert parent.child_assay_types.include?(child2)
#
#    assert_equal parent,child1.parent_assay_type
#    assert_equal parent,child2.parent_assay_type
#  end

  test "parent and children structure" do
    parent=AssayType.new(:title=>"parent")
    c1=AssayType.new(:title=>"child1")
    c2=AssayType.new(:title=>"child2")
    parent.children << c1
    parent.children << c2
    parent.save
    parent=AssayType.find(parent.id)

    assert_equal 2,parent.children.size

    assert_equal c1,parent.children.first
    assert_equal c2,parent.children.last

    assert_equal 1,parent.children.first.parents.size
    assert_equal 1,parent.children.last.parents.size
    
    assert_equal parent,parent.children.first.parents.first
    assert_equal parent,parent.children.last.parents.first

  end

  test "two parents" do

    c1=AssayType.new(:title=>"Child")
    p1=AssayType.new(:title=>"Parent1")
    p2=AssayType.new(:title=>"Parent1")

    c1.parents << p1
    c1.parents << p2

    c1.save

    assert_equal 2,c1.parents.size
    assert_equal 1,p1.children.size
    assert_equal 1,p1.children.size

    child=AssayType.find(c1.id)
    assert_equal 2,child.parents.size
    assert child.parents.include?(p1)
    assert child.parents.include?(p2)

    parent=AssayType.find(p1.id)
    assert_equal 1,parent.children.size
    assert parent.children.include?(c1)

  end

  test "parent and child fixtures" do
    
    parent1=assay_types(:parent1)
    parent2=assay_types(:parent2)
    child1=assay_types(:child1)
    child2=assay_types(:child2)
    child3=assay_types(:child3)

    assert_equal 3,parent1.children.size
    assert_equal 1,parent2.children.size

    assert_equal 1,child1.parents.size
    assert_equal 1,child2.parents.size
    assert_equal 2,child3.parents.size

  end
  
end
