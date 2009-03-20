require 'test_helper'

class ExperimentTest < ActiveSupport::TestCase
  fixtures :experiments,:assays,:topics,:projects,:experiment_types,:assay_types
  
  test "associations" do
    exp=experiments(:metabolomics_exp)
    assert_equal "A Metabolomics Experiment",exp.title

    assert_not_nil exp.assay
    assert_not_nil exp.assay.topic
    assert_not_nil exp.assay.topic.project

    assert_equal "Metabolomics Assay",exp.assay.title
    assert_equal "Metabolomics Topic",exp.assay.topic.title
    assert_equal projects(:sysmo_project),exp.assay.topic.project

    assert_equal experiment_types(:catabolic_response),exp.experiment_type
    assert_equal assay_types(:metabolomics),exp.assay.assay_type
    
    
  end
end
