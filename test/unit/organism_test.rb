require 'test_helper'

class OrganismTest < ActiveSupport::TestCase
  
  fixtures :organisms,:assays,:models

  test "assay association" do
    o=organisms(:Saccharomyces_cerevisiae)
    a=assays(:metabolomics_assay)
    assert_equal 1,o.assays.size
    assert o.assays.include?(a)
  end
  
end
