require 'test/unit'
require 'bioportal'

class BioportalTest < Test::Unit::TestCase
  
  include BioPortal::RestAPI
  
#  def test_search
#    res,pages = search "Escherichia coli",:page_size=>10
#    assert !res.empty?
#    assert pages.to_i>50
#    assert_equal 10,res.size
#    assert_not_nil(res.find{|r| r[:ontologyId]=="1132"})
#  end
#
#  def test_get_concept
#    concept = get_concept "38802","NCBITaxon:4932",{:light=>true}
#    assert_not_nil concept, "concept returned should not be nil"
#    assert_equal "Saccharomyces cerevisiae",concept[:label]
#
#    assert concept[:synonyms].include?("\"lager beer yeast\""),"synonyms should contain lager beer yeast"
#  end

#  def test_get_ontology_versions
#    ontologies = get_ontology_versions
#    assert_not_nil ontologies
#    assert !ontologies.empty?
#    assert_not_nil ontologies.first[:id]
#    assert_not_nil ontologies.find{|o| o[:ontology_id]=="1132"}
#    assert_not_nil ontologies.first[:date_created],"date_created should be set"
#    assert_not_nil ontologies.first[:status_id],"status_id should be set"
#    assert_not_nil ontologies.first[:description],"description shoudl be set"
#    assert_not_nil ontologies.first[:label],"label should be set"
#    assert_not_nil ontologies.first[:is_foundry],"is_foundry should be set"
#    assert_not_nil ontologies.first[:version_number],"version_number should be set"
#    assert_not_nil ontologies.first[:contact_name],"contact_name should be set"
#    assert_not_nil ontologies.first[:contact_email],"contact_email should be set"
#    assert_not_nil ontologies.first[:format],"format should be set"
#  end

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
    concepts = get_concepts_for_ontology_version_id("38802",:limit=>"10")
    assert_not_nil concepts,"concepts should not be nil"
    assert !concepts.empty?,"concepts should not be empty"
    assert_not_nil concepts.first[:label],"there should be the label set on the first concept"
 
    assert_equal 10,concepts.size,"there should be 10 concepts"
  end
#
#  def test_get_concepts_for_virtual_ontology_id
#    concepts = get_concepts_for_virtual_ontology_id "1104",:limit=>"10"
#    assert_not_nil concepts
#    #assert !concepts.blank?
#    #assert_equal 10,concepts.size
#  end
  
end
