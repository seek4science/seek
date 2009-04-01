require 'test_helper'

class ExperimentTest < ActiveSupport::TestCase
  fixtures :experiments,:assays,:topics,:projects,:experiment_types,:assay_types
  
  test "associations" do
    exp=experiments(:metabolomics_exp)
    assert_equal "A Metabolomics Experiment",exp.title

    assert_not_nil exp.assays
    assert_equal 1,exp.assays.size    
    assert_not_nil exp.topic.project

    assert_equal "Metabolomics Assay",exp.assays.first.title    
    assert_equal projects(:sysmo_project),exp.topic.project

    assert_equal experiment_types(:catabolic_response),exp.experiment_type
    assert_equal assay_types(:metabolomics),exp.assays.first.assay_type
    
    
  end
end
