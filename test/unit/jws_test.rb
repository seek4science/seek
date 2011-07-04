require 'test_helper'

class JwsTest < ActiveSupport::TestCase
  fixtures :all

  def setup
    WebMock.allow_net_connect!
    @builder = Seek::JWS::OneStop.new
  end
  
  test "is supported" do
    model=models(:teusink)
    model.content_blob.dump_data_to_file
    assert @builder.is_supported?(model)
    
    model=models(:jws_model)
    model.content_blob.dump_data_to_file
    assert @builder.is_supported?(model)
    
    model=models(:model_jws_incompatible)
    model.content_blob.dump_data_to_file
    assert !@builder.is_supported?(model)
  end

  test "is supported no longer relies on extension" do
    model=models(:teusink)
    model.original_filename = "teusink.txt"
    model.content_blob.dump_data_to_file
    assert @builder.is_sbml?(model)
    assert !@builder.is_dat?(model)
    assert @builder.is_supported?(model)

    model=models(:jws_model)
    model.original_filename = "jws.txt"
    model.content_blob.dump_data_to_file
    assert !@builder.is_sbml?(model)
    assert @builder.is_dat?(model)
    assert @builder.is_supported?(model)
  end
  
  test "is supported with versioned model" do
    model=model_versions(:teusink_v2)
    model.content_blob.dump_data_to_file
    assert @builder.is_supported?(model)
    
    model=model_versions(:jws_model_v1)
    model.content_blob.dump_data_to_file
    assert @builder.is_supported?(model)
    
    model=model_versions(:model_jws_incompatible_v1)
    model.content_blob.dump_data_to_file
    assert !@builder.is_supported?(model)
  end
  
  test "is sbml" do
    model=models(:teusink)
    model.content_blob.dump_data_to_file
    assert @builder.is_sbml?(model)
    assert !@builder.is_dat?(model)
  end
  
  test "is jws dat" do
    model=models(:jws_model)
    model.content_blob.dump_data_to_file
    assert !@builder.is_sbml?(model)
    assert @builder.is_dat?(model)
  end
  
  test "non sbml xml file" do
    model=models(:non_sbml_xml)
    model.content_blob.dump_data_to_file
    assert !@builder.is_sbml?(model)
    assert !@builder.is_dat?(model)
    assert !@builder.is_supported?(model)
  end
  
  test "non jws dat file" do
    model=models(:non_jws_dat)
    model.content_blob.dump_data_to_file
    assert !@builder.is_sbml?(model)
    assert !@builder.is_dat?(model)
    assert !@builder.is_supported?(model)
  end
  
  test "jws online response handled when errors present" do
    WebMock.allow_net_connect!
    model=models(:invalid_sbml_xml)
    params_hash,attributions,saved_file,objects_hash,error_keys = @builder.builder_content model.versions.first
    assert !error_keys.empty?
    assert error_keys.include?("parameters")
  end if Seek::Config.jws_enabled
  
end