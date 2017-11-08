require 'test_helper'

class OrganismTest < ActiveSupport::TestCase
  fixtures :all

  test 'assay association' do
    o = organisms(:Saccharomyces_cerevisiae)
    a = assays(:metabolomics_assay)
    assert_equal 1, o.assays.size
    assert o.assays.include?(a)
  end

  test 'ncbi_uri' do
    org = Factory(:organism, bioportal_concept: Factory(:bioportal_concept))
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/2287', org.ncbi_uri

    org = Factory(:organism, concept_uri: 'http://purl.bioontology.org/ontology/NCBITAXON/2104')
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/2104', org.ncbi_uri

    org = Factory(:organism, concept_uri: 'http://identifiers.org/taxonomy/2104')
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/2104', org.ncbi_uri

    org = Factory(:organism, concept_uri: 'http://purl.obolibrary.org/obo/NCBITaxon_2387')
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/2387', org.ncbi_uri

    org = Factory(:organism)
    assert_nil org.ncbi_uri
  end

  test 'ncbi_id' do
    org = Factory(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: 'http://purl.obolibrary.org/obo/NCBITaxon_2287'))
    assert_equal 'http://purl.obolibrary.org/obo/NCBITaxon_2287', org.concept_uri
    assert_equal 2287, org.ncbi_id

    org = Factory(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: 'http://purl.obolibrary.org/obo/NCBITaxon_1111'))
    assert_equal 1111, org.ncbi_id

    org = Factory(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: 'http://purl.bioontology.org/ontology/NCBITAXON/2104'))
    assert_equal 2104, org.ncbi_id

    org = Factory(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: 'http://identifiers.org/taxonomy/9606'))
    assert_equal 9606, org.ncbi_id

    org = Factory(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: 'https://identifiers.org/taxonomy/9606'))
    assert_equal 9606, org.ncbi_id

    org = Factory(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: nil))
    assert_nil org.ncbi_id
  end

  test 'validate concept uri' do
    org = Factory.build(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: 'http://purl.obolibrary.org/obo/NCBITaxon_2287'))
    assert org.valid?

    org = Factory.build(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: 'https://purl.obolibrary.org/obo/NCBITaxon_2287'))
    assert org.valid?

    org = Factory.build(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: 'http://identifiers.org/taxonomy/9606'))
    assert org.valid?

    org = Factory.build(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: 'https://identifiers.org/taxonomy/9606'))
    assert org.valid?

    org = Factory.build(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: 'http://purl.bioontology.org/ontology/NCBITAXON/2104'))
    assert org.valid?

    org = Factory.build(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: 'https://purl.bioontology.org/ontology/NCBITAXON/2104'))
    assert org.valid?

    org = Factory.build(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: nil))
    assert org.valid?

    org = Factory.build(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: '2104'))
    refute org.valid?

    org = Factory.build(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: 'wibble'))
    refute org.valid?

    org = Factory.build(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: 'http://somewhere/123'))
    refute org.valid?

    org = Factory.build(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: 'purl.bioontology.org/ontology/NCBITAXON/2104'))
    refute org.valid?

    org = Factory.build(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: 'https://purl.bioontology.org/ontology/NCBITAXON/wibble'))
    refute org.valid?

    org = Factory.build(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: 'https://purl.bioontology.org/ontology/NCBITAXON/a123'))
    refute org.valid?

    org = Factory.build(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: 'https://purl.bioontology.org/ontology/NCBITAXON/123a'))
    refute org.valid?

    org = Factory.build(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: 'https://purl.obolibrary.org/obo/NCBITaxon_wibble'))
    refute org.valid?

    org = Factory.build(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: 'https://purl.obolibrary.org/obo/NCBITaxon_123a'))
    refute org.valid?
  end

  test 'to_rdf' do
    object = Factory(:assay_organism).organism
    object.bioportal_concept = Factory(:bioportal_concept)
    object.save
    rdf = object.to_rdf

    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count >= 1
      assert_equal RDF::URI.new("http://localhost:3000/organisms/#{object.id}"), reader.statements.first.subject
      assert reader.has_triple? ["http://localhost:3000/organisms/#{object.id}", Seek::Rdf::JERMVocab.NCBI_ID, 'http://purl.bioontology.org/ontology/NCBITAXON/2287']
    end
  end

  test 'can create' do
    User.current_user = nil
    refute Organism.can_create?

    User.current_user = Factory(:person).user
    refute Organism.can_create?

    User.current_user = Factory(:project_administrator).user
    assert Organism.can_create?

    User.current_user = Factory(:programme_administrator).user
    assert Organism.can_create?

    # only if the programme is activated
    person = Factory(:programme_administrator)
    programme = person.administered_programmes.first
    programme.is_activated = false
    disable_authorization_checks { programme.save! }
    User.current_user = person.user
    refute Organism.can_create?
  end

  test 'can_view' do
    o = Factory(:organism)
    assert o.can_view?
    assert o.can_view?(nil)
    assert o.can_view?(Factory(:user))
  end

  test 'searchable_terms' do
    o = organisms(:Saccharomyces_cerevisiae)
    assert o.searchable_terms.include?('Saccharomyces cerevisiae')
  end

  test 'bioportal_link' do
    o = Factory(:organism, bioportal_concept: Factory(:bioportal_concept))
    assert_not_nil o.bioportal_concept, 'There should be an associated bioportal concept'
    assert_equal 'NCBITAXON', o.ontology_id
    assert_equal 'http://purl.obolibrary.org/obo/NCBITaxon_2287', o.concept_uri
  end

  test 'assigning terms to organism with no concept by default' do
    o = organisms(:Saccharomyces_cerevisiae)
    assert_nil o.ontology_id
    assert_nil o.concept_uri
    o.ontology_id = 'NCBITAXON'

    o.concept_uri = 'http://purl.obolibrary.org/obo/NCBITaxon_2287'
    o.save!
    o = Organism.find(o.id)
    assert_equal 'NCBITAXON', o.ontology_id
    assert_equal 'http://purl.obolibrary.org/obo/NCBITaxon_2287', o.concept_uri
  end

  test 'dependent destroyed' do
    User.with_current_user Factory(:admin) do
      o = organisms(:yeast_with_bioportal_concept)
      concept = o.bioportal_concept
      assert_not_nil BioportalConcept.find_by_id(concept.id)
      o.destroy
      assert_nil BioportalConcept.find_by_id(concept.id)
    end
  end

  test 'can_delete?' do
    project_administrator = Factory(:project_administrator)
    admin = Factory(:admin)
    non_admin = Factory(:user)
    o = organisms(:yeast)
    refute o.can_delete?(admin)
    refute o.can_delete?(project_administrator)
    refute o.can_delete?(non_admin)
    o = organisms(:human)
    assert o.can_delete?(admin)
    assert o.can_delete?(project_administrator)
    refute o.can_delete?(non_admin)
    o = organisms(:organism_linked_project_only)
    refute o.can_delete?(admin)
    refute o.can_delete?(project_administrator)
    refute o.can_delete?(non_admin)
  end

  test "can't create organism with duplicate concept uri" do
    org = Factory(:organism, concept_uri: 'http://purl.bioontology.org/ontology/NCBITAXON/562')
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/562', org.concept_uri
    assert org.valid?
    assert org.errors.none?

    org2 = FactoryGirl.build(:organism, concept_uri: 'http://purl.bioontology.org/ontology/NCBITAXON/562')

    refute org2.valid?
    refute org2.save
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/562', org2.concept_uri
    refute org2.errors.none?
    assert org2.errors[:concept_uri].any?
  end

  test 'convert ncbi id' do
    org = Factory.build(:organism, concept_uri: '1234')
    org.convert_ncbi_id
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/1234', org.concept_uri

    org = Factory.build(:organism, concept_uri: nil)
    org.convert_ncbi_id
    assert_nil org.convert_ncbi_id

    org = Factory.build(:organism, concept_uri: 'http://purl.bioontology.org/ontology/NCBITAXON/562')
    org.convert_ncbi_id
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/562', org.concept_uri

    org = Factory.build(:organism, concept_uri: 'wibble')
    org.convert_ncbi_id
    assert_equal 'wibble', org.concept_uri
  end

  test 'test uuid generated' do
    o = Factory.build(:organism)
    assert_nil o.attributes['uuid']
    o.save
    refute_nil o.attributes['uuid']
  end

  test "uuid doesn't change" do
    x = Factory :organism
    x.save
    uuid = x.attributes['uuid']
    x.save
    assert_equal x.uuid, uuid
  end
end
