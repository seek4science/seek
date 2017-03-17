require 'test_helper'

class ModelExtractionTest < ActiveSupport::TestCase
  include Seek::Models::ModelExtraction

  def test_model_contents_for_search
    model = Factory :teusink_model
    contents = model_contents_for_search(model)

    assert contents.include?('KmPYKPEP')
    assert contents.include?('F16P')
  end

  def test_extract_sbml_species
    model = Factory :teusink_model
    assert contains_sbml?(model)
    species = model.species
    assert species.include?('Glyc')
    assert !species.include?('KmPYKPEP')
    assert_equal 22, species.count

    # should be able to gracefully handle non sbml
    model = Factory :non_sbml_xml_model
    assert_equal [], model.species
  end

  def test_sbml_parameter_extraction
    model = Factory :teusink_model
    assert contains_sbml?(model)
    params = model.parameters_and_values
    assert !params.empty?
    assert params.keys.include?('KmPYKPEP')
    assert_equal '1306.45', params['VmPGK']

    # should be able to gracefully handle non sbml
    model = Factory :non_sbml_xml_model
    assert_equal({}, model.parameters_and_values)
  end

  def test_extract_jwsdat_species
    model = Factory :teusink_jws_model
    assert contains_jws_dat?(model)
    species = model.species
    assert species.include?('F16P')
    assert !species.include?('KmPYKPEP')
    assert_equal 14, species.count
  end

  def test_jwsdat_parameter_extraction
    model = Factory :teusink_jws_model
    assert contains_jws_dat?(model)
    params = model.parameters_and_values
    assert !params.empty?
    assert_equal 97, params.keys.count
    assert params.keys.include?('KmPYKPEP')
    assert_equal '1306.45', params['VmPGK']
  end
end
