require 'test_helper'

class TechnologyTypeTest < ActiveSupport::TestCase
  fixtures :technology_types,:assays

  test "parent and children structure" do
    parent=TechnologyType.new(:title=>"parent")
    c1=TechnologyType.new(:title=>"child1")
    c2=TechnologyType.new(:title=>"child2")
    parent.children << c1
    parent.children << c2
    parent.save
    parent=TechnologyType.find(parent.id)

    assert_equal 2,parent.children.size

    assert_equal c1,parent.children.first
    assert_equal c2,parent.children.last

    assert_equal 1,parent.children.first.parents.size
    assert_equal 1,parent.children.last.parents.size
    
    assert_equal parent,parent.children.first.parents.first
    assert_equal parent,parent.children.last.parents.first

  end

  test "to tree" do
    roots=TechnologyType.to_tree
    assert_equal 9,roots.size
    assert roots.include?(technology_types(:gas_chromatography))
    assert roots.include?(technology_types(:electrophoresis))
    assert roots.include?(technology_types(:chromatography))
    assert roots.include?(technology_types(:parent1))
    assert roots.include?(technology_types(:parent2))
    assert roots.include?(technology_types(:technology_type_with_child_and_assay))
    assert roots.include?(technology_types(:technology_type_with_child))
    assert roots.include?(technology_types(:technology_type_with_only_child_assays))
    assert roots.include?(technology_types(:new_parent))
  end

  test "two parents" do

    c1=TechnologyType.new(:title=>"Child")
    p1=TechnologyType.new(:title=>"Parent1")
    p2=TechnologyType.new(:title=>"Parent1")

    c1.parents << p1
    c1.parents << p2

    c1.save

    assert_equal 2,c1.parents.size
    assert_equal 1,p1.children.size
    assert_equal 1,p1.children.size

    child=TechnologyType.find(c1.id)
    assert_equal 2,child.parents.size
    assert child.parents.include?(p1)
    assert child.parents.include?(p2)

    parent=TechnologyType.find(p1.id)
    assert_equal 1,parent.children.size
    assert parent.children.include?(c1)

  end

  test "parents not empty" do
    child1=technology_types(:child1)
    assert !child1.parents.empty?

    assert !TechnologyType.find(child1.id).parents.empty?
  end

  test "parent and child fixtures" do
    
    parent1=technology_types(:parent1)
    parent2=technology_types(:parent2)
    child1=technology_types(:child1)
    child2=technology_types(:child2)
    child3=technology_types(:child3)

    assert_equal 3,parent1.children.size
    assert_equal 1,parent2.children.size

    assert_equal 1,child1.parents.size
    assert_equal 1,child2.parents.size
    assert_equal 2,child3.parents.size

  end

  test "has_children" do
    parent=technology_types(:electrophoresis)
    assert !parent.has_children?
    parent=technology_types(:parent1)
    assert parent.has_children?
  end

  test "has_parents" do
    child=technology_types(:electrophoresis)
    assert !child.has_parents?
    child=technology_types(:child1)
    assert child.has_parents?
  end
  
  test "get_all_descendants" do
    parent_tt = TechnologyType.new(:title=>"Parent")
    c1_tt = TechnologyType.new(:title=>"Child1")
    c2_tt = TechnologyType.new(:title=>"Child2")
    gc1_tt = TechnologyType.new(:title=>"GrandChild1")
    
    parent_tt.children << c1_tt
    parent_tt.children << c2_tt
    c1_tt.children << gc1_tt
    
    assert_equal 3,parent_tt.get_all_descendants.size   
  end
  
end
