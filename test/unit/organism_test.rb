require File.dirname(__FILE__) + '/../test_helper'

class OrganismTest < ActiveSupport::TestCase
  
  fixtures :organisms,:assays,:models,:bioportal_concepts

  test "assay association" do
    o=organisms(:Saccharomyces_cerevisiae)
    a=assays(:metabolomics_assay)
    assert_equal 1,o.assays.size
    assert o.assays.include?(a)
  end

  test "bioportal_link" do
    o=organisms(:yeast_with_bioportal_concept)
    assert_not_nil o.bioportal_concept,"There should be an associated bioportal concept"
    assert_equal 1132,o.ontology_id
    assert_equal 38802,o.ontology_version_id
    assert_equal "NCBITaxon:4932",o.concept_uri
    
  end

end
