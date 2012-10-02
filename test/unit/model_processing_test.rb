require 'test_helper'


class ModelProcessingTest < ActiveSupport::TestCase
  
  include Seek::ModelProcessing

  def test_contains_sbml
    model = Factory :teusink_model
    assert contains_sbml?(model)
    assert contains_sbml?(model.latest_version)
    assert !contains_jws_dat?(model)
  end

  def test_contains_jws_dat
    model = Factory :teusink_jws_model
    assert !contains_sbml?(model)
    assert contains_jws_dat?(model)
    assert contains_jws_dat?(model.latest_version)
  end

  test "contains no longer relies on extension" do
    model=Factory :teusink_model
    model.original_filename = "teusink.txt"
    model.content_blobs.first.dump_data_to_file
    assert model.contains_sbml?
    assert !model.contains_jws_dat?
    assert model.is_jws_supported?

    model = Factory :teusink_jws_model
    model.original_filename = "jws.txt"
    model.content_blobs.first.dump_data_to_file
    assert !model.contains_sbml?
    assert model.contains_jws_dat?
    assert model.is_jws_supported?
  end

  def test_is_jws_supported
    model = Factory :teusink_jws_model
    assert is_jws_supported?(model)
    assert is_jws_supported?(model.latest_version)

    model = Factory :teusink_jws_model
    assert is_jws_supported?(model)
  end

  def test_extract_sbml_species
    model = Factory :teusink_model
    assert contains_sbml?(model)
    species = model.species
    assert species.include?("Glyc")
    assert !species.include?("KmPYKPEP")
    assert_equal 22,species.count

    #should be able to gracefully handle non sbml
    model = Factory :non_sbml_xml_model
    assert_equal [],model.species
  end

  def test_sbml_parameter_extraction
    model = Factory :teusink_model
    assert contains_sbml?(model)
    params = model.parameters_and_values
    assert !params.empty?
    assert params.keys.include?("KmPYKPEP")
    assert_equal "1306.45",params["VmPGK"]

    #should be able to gracefully handle non sbml
    model = Factory :non_sbml_xml_model
    assert_equal({},model.parameters_and_values)
  end

  def test_extract_jwsdat_species
    model = Factory :teusink_jws_model
    assert contains_jws_dat?(model)
    species = model.species
    assert species.include?("F16P")
    assert !species.include?("KmPYKPEP")
    assert_equal 14,species.count
  end

  def test_jwsdat_parameter_extraction
    model = Factory :teusink_jws_model
    assert contains_jws_dat?(model)
    params = model.parameters_and_values
    assert !params.empty?
    assert_equal 97,params.keys.count
    assert params.keys.include?("KmPYKPEP")
    assert_equal "1306.45",params["VmPGK"]
  end

end