require 'test_helper'

class SuggestedTechnologyTypeTest < ActiveSupport::TestCase
  test 'new label is unique and cannot repeat with labels defined in ontology' do
    tt1 = FactoryBot.create :suggested_technology_type
    tt2 = FactoryBot.build(:suggested_technology_type, label: tt1.label)
    assert !tt2.valid?, 'tt2 is invalid ,as it has the same label as tt1'
  end

  test 'its only one parent is either from ontology or from suggested assay types' do
    # ontology parent
    uri = 'http://jermontology.org/ontology/JERMOntology#Gas_chromatography'
    ontology_class = Seek::Ontologies::TechnologyTypeReader.instance.class_hierarchy.hash_by_uri[uri]
    tt = FactoryBot.create :suggested_technology_type, ontology_uri: uri
    assert_equal 1, tt.parents.count
    assert_equal ontology_class, tt.parent

    # ontology children include suggested, but subclasses do not
    assert ontology_class.children.include?(tt)
    assert !ontology_class.subclasses.include?(tt)
    # suggested parent
    tt1 = FactoryBot.create :suggested_technology_type
    tt2 = FactoryBot.create :suggested_technology_type, parent_id: tt1.id
    assert_equal 1, tt1.parents.count
    assert_equal tt1, tt2.parent
    assert tt1.children.include?(tt2)

    # default parent
    tt = FactoryBot.create :suggested_technology_type
    assert_equal tt.default_parent_uri, tt.ontology_uri
  end

  test 'all term types' do
    types = SuggestedTechnologyType.all_term_types
    assert_equal ['technology'], types.sort
  end

  test 'link to related assays' do
    tt = FactoryBot.create :suggested_technology_type
    assay = FactoryBot.create :experimental_assay, suggested_technology_type: tt

    assert_equal assay, tt.assays.first
    assert_equal tt.label, assay.technology_type_label
  end

  test 'traverse hierarchy for parent' do
    parent = FactoryBot.create :suggested_technology_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#Binding'
    child = FactoryBot.create :suggested_technology_type, parent: parent, ontology_uri: nil
    child_child = FactoryBot.create :suggested_technology_type, parent: child, ontology_uri: nil
    ontology_parent = parent.parent
    assert_equal 'http://jermontology.org/ontology/JERMOntology#Binding', parent.ontology_uri
    assert_equal 'http://jermontology.org/ontology/JERMOntology#Binding', child.ontology_uri
    assert_equal 'http://jermontology.org/ontology/JERMOntology#Binding', child_child.ontology_uri
    assert_equal ontology_parent, parent.ontology_parent
    assert_equal ontology_parent, child.ontology_parent
    assert_equal ontology_parent, child_child.ontology_parent
  end

  test 'child assays' do
    parent_tt = FactoryBot.create :suggested_technology_type
    child_tt1 = FactoryBot.create :suggested_technology_type, parent_id: parent_tt.id
    assay1_with_child_tt1 = FactoryBot.create(:experimental_assay, suggested_technology_type: child_tt1)
    assay2_with_child_tt1 = FactoryBot.create(:experimental_assay, suggested_technology_type: child_tt1)

    child_tt2 = FactoryBot.create :suggested_technology_type, parent_id: parent_tt.id
    assay1_with_child_tt2 = FactoryBot.create(:experimental_assay, suggested_technology_type: child_tt2)
    assay2_with_child_tt2 = FactoryBot.create(:experimental_assay, suggested_technology_type: child_tt2)

    child_child_tt1 = FactoryBot.create :suggested_technology_type, parent_id: child_tt1.id
    assay1_with_child_child_tt1 = FactoryBot.create(:experimental_assay, suggested_technology_type: child_child_tt1)
    assay2_with_child_child_tt1 = FactoryBot.create(:experimental_assay, suggested_technology_type: child_child_tt1)

    assert_equal (child_child_tt1.assays | child_tt1.assays | child_tt2.assays).sort, parent_tt.get_child_assays.sort
  end

  test 'user can only edit his own technology type but not others, and admins can edit/delete any suggested technology type' do
    admin = FactoryBot.create :user, person: FactoryBot.create(:admin)
    owner = FactoryBot.create :user
    other_user = FactoryBot.create :user

    tt = FactoryBot.create :suggested_technology_type, contributor_id: owner.person.id

    User.current_user = owner
    # owner can edit, cannot delete
    assert tt.can_edit?
    assert !tt.can_destroy?
    # others cannot edit, cannot delete
    User.current_user = other_user
    assert !tt.can_edit?
    assert !tt.can_destroy?
    # admins can edit, can delete
    User.current_user = admin
    assert tt.can_edit?
    assert tt.can_destroy?
  end

  test 'generated uri' do
    tt = FactoryBot.create :suggested_technology_type
    assert_equal "suggested_technology_type:#{tt.id}", tt.uri
  end

  test 'parent cannot be self' do
    child = FactoryBot.create :suggested_technology_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#Binding'
    assert child.valid?
    child.parent = child
    refute child.valid?
  end

  test 'parent cannot be a child' do
    top = FactoryBot.create :suggested_technology_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#Binding'
    child1 = FactoryBot.create :suggested_technology_type, parent: top
    child2 = FactoryBot.create :suggested_technology_type, parent: child1
    child3 = FactoryBot.create :suggested_technology_type, parent: child2
    top.reload
    assert top.valid?

    top.parent = child1
    refute top.valid?

    top.parent = child2
    refute top.valid?

    top.parent = child3
    refute top.valid?

    top.parent = FactoryBot.create :suggested_technology_type
    assert top.valid?
  end

  test 'all children' do
    top = FactoryBot.create :suggested_technology_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#Binding'
    child1 = FactoryBot.create :suggested_technology_type, parent: top
    child2 = FactoryBot.create :suggested_technology_type, parent: child1
    child3 = FactoryBot.create :suggested_technology_type, parent: child2
    top.reload

    assert_includes top.all_children, child1
    assert_includes top.all_children, child2
    assert_includes top.all_children, child3
  end

  test 'children' do
    top = FactoryBot.create :suggested_technology_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#Binding'
    child1 = FactoryBot.create :suggested_technology_type, parent: top
    child2 = FactoryBot.create :suggested_technology_type, parent: child1
    child3 = FactoryBot.create :suggested_technology_type, parent: child2
    top.reload

    assert_includes top.children, child1
    refute_includes top.children, child2
    refute_includes top.children, child3
  end

  test 'update parent after destroy' do
    top = FactoryBot.create :suggested_technology_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#Binding'
    child1 = FactoryBot.create :suggested_technology_type, parent: top
    child2 = FactoryBot.create :suggested_technology_type, parent: child1
    child3 = FactoryBot.create :suggested_technology_type, parent: child2
    top.reload

    child1.destroy

    top.reload
    child2.reload
    child3.reload
    assert_includes top.children, child2
    assert_includes child2.children, child3
    assert_equal top, child2.parent

    child2.destroy

    top.reload
    child3.reload

    assert_includes top.children, child3
    assert_equal top, child3.parent
  end

  test 'updates new parent ontology uri when deleting old parent' do
    top = FactoryBot.create :suggested_technology_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#Binding'
    child1 = FactoryBot.create :suggested_technology_type, parent: top, ontology_uri: nil
    child2 = FactoryBot.create :suggested_technology_type, parent: child1, ontology_uri: nil
    assert_equal 'http://jermontology.org/ontology/JERMOntology#Binding', top.ontology_uri
    assert_nil child1[:ontology_uri]
    assert_nil child2[:ontology_uri]

    top.destroy
    child1.reload
    child2.reload
    assert_equal 'http://jermontology.org/ontology/JERMOntology#Binding', child1.ontology_uri
    assert_nil child2[:ontology_uri]

    # check it only affects the children when the item being destroyed hangs from an ontology term
    top = FactoryBot.create :suggested_technology_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#Binding'
    child1 = FactoryBot.create :suggested_technology_type, parent: top, ontology_uri: nil
    child2 = FactoryBot.create :suggested_technology_type, parent: child1, ontology_uri: nil

    child1.destroy
    top.reload
    child2.reload
    assert_equal 'http://jermontology.org/ontology/JERMOntology#Binding', top.ontology_uri
    assert_nil child2[:ontology_uri]
  end

  test 'updating a suggested tech type should update associated assays' do
    type = FactoryBot.create :suggested_technology_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#UPLC'
    assay = FactoryBot.create(:experimental_assay, suggested_technology_type: type)
    assay2 = FactoryBot.create(:experimental_assay, suggested_technology_type: type)

    type.reload
    assert_equal [assay, assay2].sort, type.assays.sort
    assert_equal 'http://jermontology.org/ontology/JERMOntology#UPLC', assay.technology_type_uri
    assert_equal 'http://jermontology.org/ontology/JERMOntology#UPLC', assay2.technology_type_uri

    RdfGenerationQueue.destroy_all

    # checks that rdf generation jobs have been created, to update the RDF for the assays
    assert_enqueued_jobs(1, only: RdfGenerationJob) do
      assert_difference('RdfGenerationQueue.count', 2) do
        type.ontology_uri = 'http://jermontology.org/ontology/JERMOntology#Binding'
        type.save!
        assay.reload
        assay2.reload

        assert_equal 'http://jermontology.org/ontology/JERMOntology#Binding', assay.technology_type_uri
        assert_equal 'http://jermontology.org/ontology/JERMOntology#Binding', assay2.technology_type_uri
      end
    end
    assert_equal [assay, assay2].sort, RdfGenerationQueue.last(2).map(&:item).sort
  end

  test 'assay adopts ontology uri if suggested type destroyed' do
    type = FactoryBot.create :suggested_technology_type, ontology_uri: 'http://jermontology.org/ontology/JERMOntology#UPLC'
    assay = FactoryBot.create(:experimental_assay, suggested_technology_type: type)
    type.reload
    assert_equal 'http://jermontology.org/ontology/JERMOntology#UPLC', assay.technology_type_uri

    RdfGenerationQueue.destroy_all

    # checks that rdf generation jobs have been created, to update the RDF for the assays
    assert_enqueued_jobs(1, only: RdfGenerationJob) do
      assert_difference('RdfGenerationQueue.count', 1) do
        type.destroy
        assay.reload

        assert_nil assay.suggested_assay_type
        assert_equal 'http://jermontology.org/ontology/JERMOntology#UPLC', assay.technology_type_uri
      end
    end
  end
end
