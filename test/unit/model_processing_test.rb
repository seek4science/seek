require 'test_helper'


class ModelProcessingTest < ActiveSupport::TestCase
  fixtures :all
  
  include Seek::ModelProcessing

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

  test "is supported no longer relies on extension" do
    model=models(:teusink)
    model.original_filename = "teusink.txt"
    model.content_blob.dump_data_to_file
    assert model.is_sbml?
    assert !model.is_dat?
    assert model.is_jws_supported?

    model=models(:jws_model)
    model.original_filename = "jws.txt"
    model.content_blob.dump_data_to_file
    assert !model.is_sbml?
    assert model.is_dat?
    assert model.is_jws_supported?
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

  def test_extract_sbml_species
    model = models(:teusink)
    assert is_sbml?(model)
    species = model.species
    assert species.include?("Glyc")
    assert !species.include?("KmPYKPEP")
    assert_equal 22,species.count

    #should be able to gracefully handle non sbml
    model = models(:non_sbml_xml)
    assert_equal [],model.species
  end

  def test_sbml_parameter_extraction
    model = models(:teusink)
    assert is_sbml?(model)
    params = model.parameters_and_values
    assert !params.empty?
    assert params.keys.include?("KmPYKPEP")
    assert_equal "1306.45",params["VmPGK"]

    #should be able to gracefully handle non sbml
    model = models(:non_sbml_xml)
    assert_equal({},model.parameters_and_values)
  end

  def test_extract_jwsdat_species
    model = models(:jws_model)
    assert is_dat?(model)
    species = model.species
    assert species.include?("F16P")
    assert !species.include?("KmPYKPEP")
    assert_equal 14,species.count
  end

  def test_jwsdat_parameter_extraction
    model = models(:jws_model)
    assert is_dat?(model)
    params = model.parameters_and_values
    assert !params.empty?
    assert_equal 97,params.keys.count
    assert params.keys.include?("KmPYKPEP")
    assert_equal "1306.45",params["VmPGK"]
  end

end