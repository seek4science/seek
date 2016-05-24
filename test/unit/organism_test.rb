require 'test_helper'

class OrganismTest < ActiveSupport::TestCase
  
  fixtures :organisms,:assays,:models,:bioportal_concepts,:assay_organisms,:studies

  test "assay association" do
    o=organisms(:Saccharomyces_cerevisiae)
    a=assays(:metabolomics_assay)
    assert_equal 1,o.assays.size
    assert o.assays.include?(a)
  end

  test "ncbi_uri" do
    org = Factory(:organism,:bioportal_concept=>Factory(:bioportal_concept))
    assert_equal "http://purl.obolibrary.org/obo/NCBITaxon_2287",org.ncbi_uri

    org = Factory(:organism)

    assert_nil org.ncbi_uri
  end

  test "ncbi_id" do
    org = Factory(:organism,:bioportal_concept=>Factory(:bioportal_concept))
    assert_equal "http://purl.obolibrary.org/obo/NCBITaxon_2287",org.ncbi_uri
    assert_equal 2287,org.ncbi_id
  end

  test "to_rdf" do
    object = Factory(:assay_organism).organism
    object.bioportal_concept = Factory(:bioportal_concept)
    object.save
    rdf = object.to_rdf

    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count >= 1
      assert_equal RDF::URI.new("http://localhost:3000/organisms/#{object.id}"), reader.statements.first.subject
      assert reader.has_triple? ["http://localhost:3000/organisms/#{object.id}",Seek::Rdf::JERMVocab.NCBI_ID,"http://purl.obolibrary.org/obo/NCBITaxon_2287"]
    end
  end

  test "can create" do
    User.current_user=nil
    refute Organism.can_create?

    User.current_user = Factory(:person).user
    refute Organism.can_create?

    User.current_user = Factory(:project_administrator).user
    assert Organism.can_create?

    User.current_user = Factory(:programme_administrator).user
    assert Organism.can_create?

    #only if the programme is activated
    person = Factory(:programme_administrator)
    programme = person.administered_programmes.first
    programme.is_activated=false
    disable_authorization_checks{programme.save!}
    User.current_user = person.user
    refute Organism.can_create?
  end

  test "can_view" do
    o=Factory(:organism)
    assert o.can_view?
    assert o.can_view?(nil)
    assert o.can_view?(Factory(:user))
  end

  test "searchable_terms" do
    o=organisms(:Saccharomyces_cerevisiae)
    assert o.searchable_terms.include?("Saccharomyces cerevisiae")
  end
 
  test "bioportal_link" do
    o=Factory(:organism,:bioportal_concept=>Factory(:bioportal_concept))
    assert_not_nil o.bioportal_concept,"There should be an associated bioportal concept"
    assert_equal "NCBITAXON",o.ontology_id
    assert_equal "http://purl.obolibrary.org/obo/NCBITaxon_2287",o.concept_uri
  end

  test "assigning terms to organism with no concept by default" do
    o=organisms(:Saccharomyces_cerevisiae)
    assert_equal nil,o.ontology_id
    assert_equal nil,o.concept_uri
    o.ontology_id="NCBITAXON"

    o.concept_uri="abc"
    o.save!
    o=Organism.find(o.id)
    assert_equal "NCBITAXON",o.ontology_id
    assert_equal "abc",o.concept_uri
  end

  test "dependent destroyed" do
    User.with_current_user Factory(:admin) do
      o=organisms(:yeast_with_bioportal_concept)
      concept=o.bioportal_concept
      assert_not_nil BioportalConcept.find_by_id(concept.id)
      o.destroy
      assert_nil BioportalConcept.find_by_id(concept.id)
    end
  end
  
  test "can_delete?" do
    project_administrator = Factory(:project_administrator)
    admin = Factory(:admin)
    non_admin=Factory(:user)
    o=organisms(:yeast)
    refute o.can_delete?(admin)
    refute o.can_delete?(project_administrator)
    refute o.can_delete?(non_admin)
    o=organisms(:human)
    assert o.can_delete?(admin)
    assert o.can_delete?(project_administrator)
    refute o.can_delete?(non_admin)
    o=organisms(:organism_linked_project_only)
    refute o.can_delete?(admin)
    refute o.can_delete?(project_administrator)
    refute o.can_delete?(non_admin)
  end

  test "can't create organism with duplicate concept uri" do
    org = Factory(:organism, concept_uri: 'http://purl.bioontology.org/ontology/NCBITAXON/562')
    assert_equal "http://purl.bioontology.org/ontology/NCBITAXON/562", org.concept_uri
    assert org.valid?
    assert org.errors.none?

    org2 = FactoryGirl.build(:organism, concept_uri: 'http://purl.bioontology.org/ontology/NCBITAXON/562')

    refute org2.valid?
    refute org2.save
    assert_equal "http://purl.bioontology.org/ontology/NCBITAXON/562", org2.concept_uri
    refute org2.errors.none?
    assert org2.errors[:concept_uri].any?
  end

end
