require 'test_helper'

class ModelTypeHandlingTest < ActiveSupport::TestCase
  include Seek::Models::ModelTypeHandling

  def test_contains_xgmml
    model = Factory :xgmml_model
    assert model.contains_xgmml?
    assert contains_xgmml?(model)
  end

  def test_xgmml_content_blops
    model = Factory :model, content_blobs: [Factory(:xgmml_content_blob), Factory(:teusink_model_content_blob)]
    assert_equal 2, model.content_blobs.size
    assert_equal 1, model.xgmml_content_blobs.size
    assert model.xgmml_content_blobs.first.is_xgmml?
  end

  def test_contains_sbml
    model = Factory :teusink_model
    assert contains_sbml?(model)
    assert contains_sbml?(model.latest_version)
    assert !contains_jws_dat?(model)
  end

  def test_sbml_content_blops
    model = Factory :model, content_blobs: [Factory(:xgmml_content_blob), Factory(:teusink_model_content_blob)]
    assert_equal 2, model.content_blobs.size
    assert_equal 1, model.sbml_content_blobs.size
    assert model.sbml_content_blobs.first.is_sbml?
  end

  def test_contains_jws_dat
    model = Factory :teusink_jws_model
    assert !contains_sbml?(model)
    assert contains_jws_dat?(model)
    assert contains_jws_dat?(model.latest_version)
  end

  def test_jws_dat_content_blops
    model = Factory :model, content_blobs: [Factory(:teusink_jws_model_content_blob), Factory(:teusink_model_content_blob)]
    assert_equal 2, model.content_blobs.size
    assert_equal 1, model.jws_dat_content_blobs.size
    assert model.jws_dat_content_blobs.first.is_jws_dat?
  end

  test 'contains no longer relies on extension' do
    model = Factory :teusink_model
    model.original_filename = 'teusink.txt'
    model.content_blobs.first.dump_data_to_file
    assert model.contains_sbml?
    assert !model.contains_jws_dat?
    assert model.is_jws_supported?

    model = Factory :teusink_jws_model
    model.original_filename = 'jws.txt'
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

    model = Factory :model, content_blobs: [Factory(:xgmml_content_blob), Factory(:teusink_model_content_blob)]
    assert model.is_jws_supported?

    model = Factory :model, content_blobs: [Factory(:xgmml_content_blob), Factory(:non_sbml_xml_content_blob)]
    assert !model.is_jws_supported?
  end
end
