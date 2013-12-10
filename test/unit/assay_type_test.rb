require 'test_helper'

class AssayTypeTest < ActiveSupport::TestCase
  fixtures :assay_types,:assays


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

  test "to tree with root" do
    roots = AssayType.to_tree(assay_types(:experimental_assay_type).id)
    assert_equal 1,roots.size
    assert roots.include?(assay_types(:experimental_assay_type))
  end

  test "to tree" do
    roots=AssayType.to_tree
    assert_equal 10,roots.size
    assert roots.include?(assay_types(:metabolomics))
    assert roots.include?(assay_types(:proteomics))
    assert roots.include?(assay_types(:parent1))
    assert roots.include?(assay_types(:parent2))
    assert roots.include?(assay_types(:assay_type_with_child))
    assert roots.include?(assay_types(:assay_type_with_child_and_assay))
    assert roots.include?(assay_types(:assay_type_with_only_child_assays))
    assert roots.include?(assay_types(:new_parent))
    assert roots.include?(assay_types(:experimental_assay_type))
    assert roots.include?(assay_types(:modelling_assay_type))
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

  test "parents not empty" do
    child1=assay_types(:child1)
    assert !child1.parents.empty?

    assert !AssayType.find(child1.id).parents.empty?
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

  test "has_children" do
    parent=assay_types(:metabolomics)
    assert !parent.has_children?
    parent=assay_types(:parent1)
    assert parent.has_children?
  end

  test "has_parents" do
    child=assay_types(:metabolomics)
    assert !child.has_parents?
    child=assay_types(:child1)
    assert child.has_parents?
  end

  test "assays association" do
    a1=assay_types(:parent1)
    assert a1.assays.empty?
    a2=assay_types(:metabolomics)
    assert a2.assays.include?(assays(:metabolomics_assay))
    assert a2.assays.include?(assays(:metabolomics_assay2))
  end
  
  test "get_all_descendants" do
    parent_assay = AssayType.new(:title=>"Parent")
    c1_assay = AssayType.new(:title=>"Child1")
    c2_assay = AssayType.new(:title=>"Child2")
    gc1_assay = AssayType.new(:title=>"GrandChild1")
    
    parent_assay.children << c1_assay
    parent_assay.children << c2_assay
    c1_assay.children << gc1_assay
    
    assert_equal 3,parent_assay.get_all_descendants.size   
  end

  test "experimental assay type id" do
    id = AssayType.experimental_assay_type_id
    assert_not_nil id
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#ExperimentalAssayType",AssayType.find(id).term_uri
  end

  test "modelling assay type id" do
    id = AssayType.modelling_assay_type_id
    assert_not_nil id
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#ModelAnalysisType",AssayType.find(id).term_uri
  end

  
end
