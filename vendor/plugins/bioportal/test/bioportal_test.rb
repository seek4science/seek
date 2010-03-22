require 'test/unit'
require 'bioportal'

class BioportalTest < Test::Unit::TestCase
  
  include BioPortal::RestAPI
  
  def test_search
    res,pages = search "Escherichia coli",:page_size=>10
    assert !res.empty?
    assert pages>50
    assert_equal 10,res.size
    assert_not_nil(res.find{|r| r[:ontology_id]=="1132"})
  end

  def test_get_concept
    concept = get_concept "38802","NCBITaxon:4932",{:light=>true}
    assert_not_nil concept, "concept returned should not be nil"
    assert_equal "Saccharomyces cerevisiae",concept[:label]

    assert concept[:synonyms].include?("\"lager beer yeast\""),"synonyms should contain lager beer yeast"
    assert_not_nil concept[:instances],"There should be an instances field returned"
  end

  def test_override_base_url
    class << self
      def bioportal_base_rest_url
        "http://google.com/fred"
      end
    end
    assert_raise(OpenURI::HTTPError) { get_concept "38802","NCBITaxon:4932",{:light=>true}  }
  end

  def test_get_ontology_versions
    ontologies = get_ontology_versions
    assert_not_nil ontologies
    assert !ontologies.empty?
    assert_not_nil ontologies.first[:id]
    assert_not_nil ontologies.find{|o| o[:ontology_id]=="1132"}
    assert_not_nil ontologies.first[:date_created],"date_created should be set"
    assert_not_nil ontologies.first[:status_id],"status_id should be set"
    assert_not_nil ontologies.first[:description],"description shoudl be set"
    assert_not_nil ontologies.first[:label],"label should be set"
    assert_not_nil ontologies.first[:is_foundry],"is_foundry should be set"
    assert_not_nil ontologies.first[:version_number],"version_number should be set"
    assert_not_nil ontologies.first[:contact_name],"contact_name should be set"
    assert_not_nil ontologies.first[:contact_email],"contact_email should be set"
    assert_not_nil ontologies.first[:format],"format should be set"
  end

  def test_get_concepts_for_version_id
    concepts,pages = get_concepts_for_ontology_version_id("38802",:pagesize=>"10")
    assert_not_nil concepts,"concepts should not be nil"
    assert !concepts.empty?,"concepts should not be empty"
    assert_not_nil concepts.first[:label],"there should be the label set on the first concept"
    assert pages>10,"There should be more than 10 pages"
 
    assert_equal 10,concepts.size,"there should be 10 concepts"
  end

  def test_get_ontology_details
    ontology = get_ontology_details "38802"
    assert_not_nil ontology
    assert_equal "38802",ontology[:id]
    assert_equal "1132",ontology[:ontology_id]
    assert_not_nil ontology[:label],"label should be set"
    assert_not_nil ontology[:format],"format should be set"
    assert_not_nil ontology[:date_created],"date_created should be set"
    assert_not_nil ontology[:status_id],"status_id should be set"
    assert_not_nil ontology[:description],"description shoudl be set"
    assert_not_nil ontology[:label],"label should be set"
    assert_not_nil ontology[:is_foundry],"is_foundry should be set"
    assert_not_nil ontology[:version_number],"version_number should be set"
    assert_not_nil ontology[:contact_name],"contact_name should be set"
    assert_not_nil ontology[:contact_email],"contact_email should be set"
    assert_not_nil ontology[:format],"format should be set"    
    assert_not_nil ontology[:is_view],"is_view should be set"
  end
  #
  #  def test_get_concepts_for_virtual_ontology_id
  #    concepts = get_concepts_for_virtual_ontology_id "1104",:limit=>"10"
  #    assert_not_nil concepts
  #    #assert !concepts.blank?
  #    #assert_equal 10,concepts.size
  #  end
  
end
