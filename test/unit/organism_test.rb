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

  test "searchable_terms" do
    o=organisms(:Saccharomyces_cerevisiae)
    assert o.searchable_terms.include?("Saccharomyces cerevisiae")
  end
 
  test "bioportal_link" do
    o=organisms(:yeast_with_bioportal_concept)
    assert_not_nil o.bioportal_concept,"There should be an associated bioportal concept"
    assert_equal 1132,o.ontology_id
    assert_equal 38802,o.ontology_version_id
    assert_equal "NCBITaxon:4932",o.concept_uri    
  end

  test "assigning terms to organism with no concept by default" do
    o=organisms(:Saccharomyces_cerevisiae)
    assert_equal nil,o.ontology_id
    assert_equal nil,o.ontology_version_id
    assert_equal nil,o.concept_uri
    o.ontology_id=4
    o.ontology_version_id=5
    o.concept_uri="abc"
    o.save!
    o=Organism.find(o.id)
    assert_equal 4,o.ontology_id
    assert_equal 5,o.ontology_version_id
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
    admin = Factory(:admin)
    non_admin=Factory(:user)
    o=organisms(:yeast)
    assert !o.can_delete?(admin)
    o=organisms(:human)
    assert o.can_delete?(admin)
    assert !o.can_delete?(non_admin)
    o=organisms(:organism_linked_project_only)
    assert !o.can_delete?(admin)
  end

#  test "get concept" do
#    o=organisms(:yeast_with_bioportal_concept)
#    concept=o.concept({:maxchildren=>5,:light=>0,:refresh=>true})
#    assert_not_nil concept
#    assert_equal "NCBITaxon:4932",concept[:id]
#    assert !concept[:synonyms].empty?
#    assert !concept[:children].empty?
#    assert !concept[:parents].empty?
#    assert_equal 38802,concept[:ontology_version_id]
#  end

#  test "get ontology" do
#    o=organisms(:yeast_with_bioportal_concept)
#    ontology=o.ontology({:maxchildren=>5,:light=>0,:refresh=>true})
#    assert_not_nil ontology
#    assert_equal "1132",ontology[:ontology_id]
#  end

end
