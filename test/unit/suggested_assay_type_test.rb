require 'test_helper'

class SuggestedAssayTypeTest < ActiveSupport::TestCase

  test "label is uniq" do
    at1 = Factory :suggested_assay_type
    at2 = Factory.build(:suggested_assay_type, :label => at1.label)
    ma = Factory.build(:suggested_modelling_analysis_type, :label => at1.label)
    assert !at2.valid?, "at2 is invalid ,as it has the same label as at1"
    assert !ma.valid?, "modelling analysis ma is invalid ,as it has the same label as at1"
  end

  test "label should not be the same as labels in ontology" do
    label_in_ontology = Seek::Ontologies::AssayTypeReader.instance.class_hierarchy.hash_by_label.keys.first
    suggested_assay_type = Factory.build(:suggested_assay_type, :label => label_in_ontology)
    suggested_modelling_analysis = Factory.build(:suggested_modelling_analysis_type, :label => label_in_ontology)
    assert !suggested_assay_type.valid?, "label #{suggested_assay_type.label} already exists"
    assert !suggested_modelling_analysis.valid?, "label #{suggested_modelling_analysis.label} already exists"
  end

  test "its only one parent is either from ontology or from suggested assay types" do
    #ontology parent
    uri = "http://www.mygrid.org.uk/ontology/JERMOntology#Gene_expression_profiling"
    ontology_class = Seek::Ontologies::AssayTypeReader.instance.class_hierarchy.hash_by_uri[uri]
    at = Factory :suggested_assay_type, :ontology_uri => uri
    assert_equal 1, at.parents.count
    assert_equal ontology_class, at.parent
    assert_equal true, ontology_class.children.include?(at)
    #suggested parent
    at1 = Factory :suggested_assay_type
    at2 = Factory :suggested_assay_type, :parent_id => at1.id
    assert_equal 1, at2.parents.count
    assert_equal at1, at2.parent
    assert_equal true, at1.children.include?(at2)

    # default parent
    at = Factory :suggested_assay_type
    assert_equal at.default_parent_uri, at.ontology_uri
  end

  test "all term types" do
    types = SuggestedAssayType.all_term_types
    assert_equal ["assay", "modelling_analysis"], types.sort
  end

  test "ontology_parent" do
    type = Factory(:suggested_assay_type, :parent_uri => "http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics")
    parent = type.ontology_parent
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics", parent.uri
    assert_equal "Fluxomics", parent.label
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics", type.ontology_uri
  end

  test "term type" do
    type = Factory(:suggested_assay_type, :parent_uri => "http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics")
    assert_equal "assay", type.term_type
  end


  test "link to related assays" do
    at = Factory :suggested_assay_type
    assay = Factory :experimental_assay, :suggested_assay_type => at

    assert_equal assay, at.assays.first
    assert_equal at.label, assay.assay_type_label
  end

  test "assays" do
    top = Factory :suggested_assay_type, :ontology_uri => "http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics"
    child1 = Factory :suggested_assay_type, :parent => top, :ontology_uri=>nil
    child2 = Factory :suggested_assay_type, :parent => child1, :ontology_uri=>nil

    assay = Factory(:experimental_assay, :suggested_assay_type => child2)
    assay2 = Factory(:experimental_assay, :suggested_assay_type => top)


    assert_includes top.assays,assay
    assert_includes child1.assays,assay
    assert_includes child2.assays,assay

    assert_includes top.assays,assay2
    refute_includes child1.assays,assay2
    refute_includes child2.assays,assay2


  end

  test "parent cannot be self" do
    child = Factory :suggested_assay_type, :ontology_uri => "http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics"
    assert child.valid?
    child.parent=child
    refute child.valid?
  end

  test "parent cannot be a child" do
    top = Factory :suggested_assay_type, :ontology_uri => "http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics"
    child1 = Factory :suggested_assay_type, :parent => top
    child2 = Factory :suggested_assay_type, :parent => child1
    child3 = Factory :suggested_assay_type, :parent => child2
    top.reload
    assert top.valid?

    top.parent=child1
    refute top.valid?

    top.parent=child2
    refute top.valid?

    top.parent=child3
    refute top.valid?

    top.parent=Factory :suggested_assay_type
    assert top.valid?
  end

  test "all children" do
    top = Factory :suggested_assay_type, :ontology_uri => "http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics"
    child1 = Factory :suggested_assay_type, :parent => top
    child2 = Factory :suggested_assay_type, :parent => child1
    child3 = Factory :suggested_assay_type, :parent => child2
    top.reload

    assert_includes top.all_children, child1
    assert_includes top.all_children, child2
    assert_includes top.all_children, child3
  end

  test "children" do
    top = Factory :suggested_assay_type, :ontology_uri => "http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics"
    child1 = Factory :suggested_assay_type, :parent => top
    child2 = Factory :suggested_assay_type, :parent => child1
    child3 = Factory :suggested_assay_type, :parent => child2
    top.reload

    assert_includes top.children, child1
    refute_includes top.children, child2
    refute_includes top.children, child3
  end

  test "new type has nil ontology uri and ontology_parent" do
    assert_nil SuggestedAssayType.new.ontology_uri
    assert_nil SuggestedAssayType.new.ontology_parent
  end

  test "traverse hierarchy for parent" do
    parent = Factory :suggested_assay_type, :ontology_uri => "http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics"
    child = Factory :suggested_assay_type, :parent => parent, :ontology_uri => nil
    child_child = Factory :suggested_assay_type, :parent => child, :ontology_uri => nil
    ontology_parent = parent.parent
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics", parent.ontology_uri
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics", child.ontology_uri
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics", child_child.ontology_uri
    assert_equal ontology_parent, parent.ontology_parent
    assert_equal ontology_parent, child.ontology_parent
    assert_equal ontology_parent, child_child.ontology_parent
  end

  test "user can only edit his own assay type but not others, and admins can edit/delete any suggested assay type" do
    admin = Factory :user, :person => Factory(:admin)
    owner= Factory :user
    other_user = Factory :user

    at = Factory :suggested_assay_type, :contributor_id => owner.person.id
    User.current_user = owner
    refute owner.is_admin?

    #owner can edit, cannot delete
    assert_equal true, at.can_edit?
    assert_equal false, at.can_destroy?

    #others cannot edit, cannot delete
    User.current_user = other_user
    assert_equal false, at.can_edit?
    assert_equal false, at.can_destroy?

    #admins can edit, can delete
    User.current_user = admin
    assert_equal true, at.can_edit?
    assert_equal true, at.can_destroy?
  end

  test "generated uri" do
    at = Factory :suggested_assay_type
    assert_equal "suggested_assay_type:#{at.id}", at.uri
  end

  test "join parent and children after destroy" do
    top = Factory :suggested_assay_type, :ontology_uri => "http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics"
    child1 = Factory :suggested_assay_type, :parent => top
    child2 = Factory :suggested_assay_type, :parent => child1
    child3 = Factory :suggested_assay_type, :parent => child2
    top.reload

    child1.destroy

    top.reload
    child2.reload
    child3.reload
    assert_includes top.children,child2
    assert_includes child2.children,child3
    assert_equal top,child2.parent

    child2.destroy

    top.reload

    child3.reload
    assert_includes top.children,child3
    assert_equal top,child3.parent

  end

  test "updates new parent ontology uri when deleting old parent" do
    top = Factory :suggested_assay_type, :ontology_uri => "http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics"
    child1 = Factory :suggested_assay_type, :parent => top, :ontology_uri=>nil
    child2 = Factory :suggested_assay_type, :parent => child1, :ontology_uri=>nil
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics",top.ontology_uri
    assert_nil child1[:ontology_uri]
    assert_nil child2[:ontology_uri]

    top.destroy
    child1.reload
    child2.reload
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics",child1.ontology_uri
    assert_nil child2[:ontology_uri]

    #check it only affects the children when the item being destroyed hangs from an ontology term
    top = Factory :suggested_assay_type, :ontology_uri => "http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics"
    child1 = Factory :suggested_assay_type, :parent => top, :ontology_uri=>nil
    child2 = Factory :suggested_assay_type, :parent => child1, :ontology_uri=>nil

    child1.destroy
    top.reload
    child2.reload
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics",top.ontology_uri
    assert_nil child2[:ontology_uri]


  end


end
