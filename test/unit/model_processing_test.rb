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

  def test_is_sbml
    model = models(:teusink)
    assert is_sbml?(model)
    assert is_sbml?(model.latest_version)
    assert !is_dat?(model)
    assert is_sbml?(model.content_blob)
    assert !is_dat?(model.content_blob)
  end

  def test_is_dat
    model = models(:jws_model)
    assert !is_sbml?(model)
    assert is_dat?(model)
    assert is_dat?(model.latest_version)
    assert !is_sbml?(model.content_blob)
    assert is_dat?(model.content_blob)
  end

  def test_is_jws_supported
    model = models(:jws_model)
    assert is_jws_supported?(model)
    assert is_jws_supported?(model.latest_version)
    assert is_jws_supported?(model.content_blob)

    model = models(:teusink)
    assert is_jws_supported?(model)
    assert is_jws_supported?(model.content_blob)
  end



end