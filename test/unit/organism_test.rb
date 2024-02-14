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
    org = FactoryBot.create(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept))
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/2287', org.ncbi_uri

    org = FactoryBot.create(:organism, concept_uri: 'http://purl.bioontology.org/ontology/NCBITAXON/2104')
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/2104', org.ncbi_uri

    org = FactoryBot.create(:organism, concept_uri: 'http://identifiers.org/taxonomy/2105')
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/2105', org.ncbi_uri

    org = FactoryBot.create(:organism, concept_uri: 'http://purl.obolibrary.org/obo/NCBITaxon_2387')
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/2387', org.ncbi_uri

    org = FactoryBot.create(:organism)
    assert_nil org.ncbi_uri
  end

  test 'ncbi_id' do
    org = FactoryBot.create(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: 'http://purl.obolibrary.org/obo/NCBITaxon_2287'))
    assert_equal 'http://purl.obolibrary.org/obo/NCBITaxon_2287', org.concept_uri
    assert_equal 2287, org.ncbi_id

    org = FactoryBot.create(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: 'http://purl.obolibrary.org/obo/NCBITaxon_1111'))
    assert_equal 1111, org.ncbi_id

    org = FactoryBot.create(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: 'http://purl.bioontology.org/ontology/NCBITAXON/2104'))
    assert_equal 2104, org.ncbi_id

    org = FactoryBot.create(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: 'http://identifiers.org/taxonomy/9606'))
    assert_equal 9606, org.ncbi_id

    org = FactoryBot.create(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: 'https://identifiers.org/taxonomy/9607'))
    assert_equal 9607, org.ncbi_id

    org = FactoryBot.create(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: nil))
    assert_nil org.ncbi_id
  end

  test 'validate concept uri' do
    org = FactoryBot.build(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: 'http://purl.obolibrary.org/obo/NCBITaxon_2287'))
    assert org.valid?

    org = FactoryBot.build(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: 'https://purl.obolibrary.org/obo/NCBITaxon_2287'))
    assert org.valid?

    org = FactoryBot.build(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: 'http://identifiers.org/taxonomy/9606'))
    assert org.valid?

    org = FactoryBot.build(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: 'https://identifiers.org/taxonomy/9606'))
    assert org.valid?

    org = FactoryBot.build(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: 'http://purl.bioontology.org/ontology/NCBITAXON/2104'))
    assert org.valid?

    org = FactoryBot.build(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: 'https://purl.bioontology.org/ontology/NCBITAXON/2104'))
    assert org.valid?

    org = FactoryBot.build(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: nil))
    assert org.valid?

    org = FactoryBot.build(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: '2104'))
    refute org.valid?

    org = FactoryBot.build(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: 'wibble'))
    refute org.valid?

    org = FactoryBot.build(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: 'http://somewhere/123'))
    refute org.valid?

    org = FactoryBot.build(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: 'purl.bioontology.org/ontology/NCBITAXON/2104'))
    refute org.valid?

    org = FactoryBot.build(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: 'https://purl.bioontology.org/ontology/NCBITAXON/wibble'))
    refute org.valid?

    org = FactoryBot.build(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: 'https://purl.bioontology.org/ontology/NCBITAXON/a123'))
    refute org.valid?

    org = FactoryBot.build(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: 'https://purl.bioontology.org/ontology/NCBITAXON/123a'))
    refute org.valid?

    org = FactoryBot.build(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: 'https://purl.obolibrary.org/obo/NCBITaxon_wibble'))
    refute org.valid?

    org = FactoryBot.build(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: 'https://purl.obolibrary.org/obo/NCBITaxon_123a'))
    refute org.valid?
  end

  test 'to_rdf' do
    object = FactoryBot.create(:assay_organism).organism
    object.bioportal_concept = FactoryBot.create(:bioportal_concept)
    object.save
    rdf = object.to_rdf

    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count >= 1
      assert_equal RDF::URI.new("http://localhost:3000/organisms/#{object.id}"), reader.statements.first.subject
      assert reader.has_triple? ["http://localhost:3000/organisms/#{object.id}", Seek::Rdf::JermVocab.NCBI_ID, RDF::Literal::AnyURI.new('http://purl.bioontology.org/ontology/NCBITAXON/2287')]
    end
  end

  test 'can create' do
    User.current_user = nil
    refute Organism.can_create?

    User.current_user = FactoryBot.create(:person).user
    refute Organism.can_create?

    User.current_user = FactoryBot.create(:project_administrator).user
    assert Organism.can_create?

    User.current_user = FactoryBot.create(:programme_administrator).user
    assert Organism.can_create?

    # only if the programme is activated
    person = FactoryBot.create(:programme_administrator)
    programme = person.administered_programmes.first
    programme.is_activated = false
    disable_authorization_checks { programme.save! }
    User.current_user = person.user
    refute Organism.can_create?
  end

  test 'can_view' do
    o = FactoryBot.create(:organism)
    assert o.can_view?
    assert o.can_view?(nil)
    assert o.can_view?(FactoryBot.create(:user))
  end

  test 'searchable_terms' do
    o = organisms(:Saccharomyces_cerevisiae)
    assert o.searchable_terms.include?('Saccharomyces cerevisiae')
  end

  test 'bioportal_link' do
    o = FactoryBot.create(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept))
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
    User.with_current_user FactoryBot.create(:admin) do
      o = organisms(:yeast_with_bioportal_concept)
      concept = o.bioportal_concept
      assert_not_nil BioportalConcept.find_by_id(concept.id)
      o.destroy
      assert_nil BioportalConcept.find_by_id(concept.id)
    end
  end

  test 'can_delete?' do
    project_administrator = FactoryBot.create(:project_administrator)
    admin = FactoryBot.create(:admin)
    non_admin = FactoryBot.create(:user)
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
    org = FactoryBot.create(:organism, concept_uri: 'http://purl.bioontology.org/ontology/NCBITAXON/562')
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/562', org.concept_uri
    assert org.valid?
    assert org.errors.none?

    org2 = FactoryBot.build(:organism, concept_uri: 'http://purl.bioontology.org/ontology/NCBITAXON/562')

    refute org2.valid?
    refute org2.save
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/562', org2.concept_uri
    refute org2.errors.none?
    assert org2.errors[:concept_uri].any?
  end

  test 'convert concept uri' do
    org = FactoryBot.build(:organism, concept_uri: '1234')
    org.convert_concept_uri
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/1234', org.concept_uri

    org = FactoryBot.build(:organism, concept_uri: nil)
    org.convert_concept_uri
    assert_nil org.convert_concept_uri

    org = FactoryBot.build(:organism, concept_uri: 'http://purl.bioontology.org/ontology/NCBITAXON/562')
    org.convert_concept_uri
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/562', org.concept_uri

    org = FactoryBot.build(:organism, concept_uri: 'NCBITaxon:1314')
    org.convert_concept_uri
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/1314', org.concept_uri

    org = FactoryBot.build(:organism, concept_uri: 'ncbitaxon:1314')
    org.convert_concept_uri
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/1314', org.concept_uri

    org = FactoryBot.build(:organism, concept_uri: 'https://identifiers.org/taxonomy/5622')
    org.convert_concept_uri
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/5622', org.concept_uri

    org = FactoryBot.build(:organism, concept_uri: 'http://identifiers.org/taxonomy/5622')
    org.convert_concept_uri
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/5622', org.concept_uri

    org = FactoryBot.build(:organism, concept_uri: ' http://identifiers.org/taxonomy/5622 ')
    org.convert_concept_uri
    assert_equal 'http://purl.bioontology.org/ontology/NCBITAXON/5622', org.concept_uri

    org = FactoryBot.build(:organism, concept_uri: 'wibble')
    org.convert_concept_uri
    assert_equal 'wibble', org.concept_uri

    org = FactoryBot.build(:organism, concept_uri: nil)
    org.convert_concept_uri
    assert_nil org.concept_uri
  end

  test 'test uuid generated' do
    o = FactoryBot.build(:organism)
    assert_nil o.attributes['uuid']
    o.save
    refute_nil o.attributes['uuid']
  end

  test "uuid doesn't change" do
    x = FactoryBot.create :organism
    x.save
    uuid = x.attributes['uuid']
    x.save
    assert_equal x.uuid, uuid
  end

  test 'ncbi_id nil for organism with blank concept id or ontology id' do
    x = FactoryBot.create(:organism_with_blank_concept)
    assert_equal '', x.bioportal_concept.concept_uri
    assert_nil x.ncbi_id
    assert_nil x.ncbi_uri

    o = FactoryBot.create(:organism,concept_uri:'')
    assert_nil o.ncbi_id
    assert_nil o.ncbi_uri
  end

  test 'can have more than one organism with no concept' do
    FactoryBot.create(:organism, concept_uri: '')
    org = FactoryBot.build(:organism, concept_uri: '')

    assert org.valid?
  end

  test 'none blank concept uris must be unique' do
    o = FactoryBot.create(:organism, concept_uri: 'http://purl.bioontology.org/ontology/NCBITAXON/562')
    assert o.valid?
    o2 = FactoryBot.build(:organism, concept_uri: 'http://purl.bioontology.org/ontology/NCBITAXON/562')
    refute o2.valid?
  end

  test 'related_publications' do
    o1 = FactoryBot.create(:organism)
    a1 = FactoryBot.create(:assay,organisms:[o1])
    a2 = FactoryBot.create(:assay,organisms:[o1])
    m1 = FactoryBot.create(:model,organism:o1)
    pub1 = FactoryBot.create(:publication, assays:[a1,a2])
    pub2 = FactoryBot.create(:publication, models:[m1])

    o1.reload
    assert_equal [pub1,pub2].sort,o1.related_publications.sort
  end

end
