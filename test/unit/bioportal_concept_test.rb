require 'test_helper'

class BioportalConceptTest < ActiveSupport::TestCase
  # test to make sure the BioportalConcept model is visible to the application
  def test_integrated
    bc = BioportalConcept.new
    assert_equal 'NCBITAXON', bc.ontology_id = 'NCBITAXON'
    assert_equal 'http://purl.obolibrary.org/obo/NCBITaxon_992344', bc.concept_uri = 'http://purl.obolibrary.org/obo/NCBITaxon_992344'
    assert_equal 'yaml', bc.cached_concept_yaml = 'yaml'

    assert bc.save!
  end
end
