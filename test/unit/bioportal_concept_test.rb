require 'test_helper'

class BioportalConceptTest < ActiveSupport::TestCase
  
  #test to make sure the BioportalConcept model is visible to the application
  def test_integrated
    bc=BioportalConcept.new
    assert_equal 1,bc.ontology_id=1
    assert_equal 1,bc.ontology_version_id=1
    assert_equal "zzz",bc.concept_uri="zzz"
    assert_equal "yaml",bc.cached_concept_yaml="yaml"

    assert bc.save!
  end
    
end
