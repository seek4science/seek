require 'test_helper'


class ModelProcessingTest < ActiveSupport::TestCase
  fixtures :all
  
  include Seek::ModelProcessing

  def test_sbml_parameter_extraction
    model = models(:teusink)
    assert is_sbml?(model)
    params = extract_model_parameters_and_values model
    assert !params.empty?
    assert params.keys.include?("KmPYKPEP")
    assert_equal "1306.45",params["VmPGK"]
  end

end