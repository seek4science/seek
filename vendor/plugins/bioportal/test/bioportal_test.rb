require 'test/unit'
require 'bioportal'

class BioportalTest < Test::Unit::TestCase
  
  include BioPortal::RestAPI
  
  def test_search
    res,pages = search "Escherichia coli",:page_size=>10
    assert !res.empty?
    assert pages.to_i>50
    assert_equal 10,res.size
    assert_not_nil(res.find{|r| r[:ontologyId]=="1132"})
  end

  def test_get_concept
    concept = get_concept "38802","NCBITaxon:4932",1,1
    assert_not_nil concept, "concept returned should not be nil"
    assert_equal "Saccharomyces cerevisiae",concept.label
    
    assert concept.synonyms.include?("\"lager beer yeast\""),"synonyms shoudl contain lager beer yeast"
  end

  def test_get_ontology_versions
    ontologies = get_ontologies_versions
    assert_not_nil ontologies
    assert !ontologies.empty?
    assert_not_nil ontologies.find{|o| o.id=="39336"}
    assert_not_nil ontologies.find{|o| o.ontologyId=="1132"}
  end

#  def test_get_categories
#    categories = get_ontology_categories
#    assert_not_nil categories
#    assert !categories.empty?
#    assert_not_nil categories.find{|c| c[:name]=="Plant Anatomy"}
#  end

#  def test_get_groups
#    groups = get_ontology_groups
#    assert_not_nil groups
#    assert !groups.empty?
#    assert_not_nil groups.find{|g| g[:name]=="OBO Foundry"}
#  end

  def test_get_concepts_for_version_id
    concepts = get_concepts_for_ontology_version_id "38802",:limit=>"10"
    assert_not_nil concepts
    #assert !concepts.blank?
    #assert_equal 10,concepts.size
  end

  def test_get_concepts_for_virtual_ontology_id
    concepts = get_concepts_for_virtual_ontology_id "1104",:limit=>"10"
    assert_not_nil concepts
    #assert !concepts.blank?
    #assert_equal 10,concepts.size
  end
  
end
