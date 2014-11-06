require 'test_helper'

class SuggestedAssayTypeTest < ActiveSupport::TestCase

   test "default_parent_uri" do
      at = Factory :suggested_modelling_analysis_type
      default_parent_class_uri = Seek::Ontologies::ModellingAnalysisTypeReader.instance.default_parent_class_uri.try(:to_s)
      assert_equal  default_parent_class_uri,  at.default_parent_uri

      modelling_at =  Factory :suggested_assay_type
      default_parent_class_uri = Seek::Ontologies::AssayTypeReader.instance.default_parent_class_uri.try(:to_s)
      assert_equal  default_parent_class_uri,  modelling_at.default_parent_uri
   end

  test "label is uniq" do
     at1 = Factory :suggested_assay_type
     at2 = Factory.build(:suggested_assay_type, :label => at1.label)
     ma =  Factory.build(:suggested_modelling_analysis_type, :label => at1.label)
     assert !at2.valid?, "at2 is invalid ,as it has the same label as at1"
     assert !ma.valid?, "modelling analysis ma is invalid ,as it has the same label as at1"
  end

   test "label should not be the same as labels in ontology" do
     label_in_ontology = Seek::Ontologies::AssayTypeReader.instance.class_hierarchy.hash_by_label.keys.first
     suggested_assay_type =  Factory.build(:suggested_assay_type, :label => label_in_ontology)
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

  test "link to related assays" do
    at = Factory :suggested_assay_type
    assay = Factory  :experimental_assay, :suggested_assay_type => at

    assert_equal assay, at.assays.first
    assert_equal at.label, assay.assay_type_label
  end

   test "child assays" do
      parent_at = Factory :suggested_assay_type
      child_at1 = Factory :suggested_assay_type, :parent_id => parent_at.id
      assay1_with_child_at1 = Factory(:experimental_assay, :suggested_assay_type=> child_at1)
      assay2_with_child_at1 = Factory(:experimental_assay, :suggested_assay_type=> child_at1)

      child_at2 = Factory :suggested_assay_type, :parent_id => parent_at.id
      assay1_with_child_at2 = Factory(:experimental_assay, :suggested_assay_type=> child_at2)
      assay2_with_child_at2 = Factory(:experimental_assay, :suggested_assay_type=> child_at2)

      child_child_at1 = Factory :suggested_assay_type, :parent_id => child_at1.id
      assay1_with_child_child_at1 = Factory(:experimental_assay, :suggested_assay_type=> child_child_at1)
      assay2_with_child_child_at1 = Factory(:experimental_assay, :suggested_assay_type=> child_child_at1)

     assert_equal (child_child_at1.assays | child_at1.assays | child_at2.assays).sort, parent_at.get_child_assays.sort
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



end
