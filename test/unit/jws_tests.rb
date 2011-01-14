require File.dirname(__FILE__) + '/../test_helper'

class JWSTests < ActiveSupport::TestCase  
  fixtures :all           
  
  test "is supported" do
    builder = Seek::JWSModelBuilder.new
    model=models(:teusink)
    model.content_blob.dump_data_to_file
    assert builder.is_supported?(model)
    
    model=models(:jws_model)
    model.content_blob.dump_data_to_file
    assert builder.is_supported?(model)
    
    model=models(:model_jws_incompatible)
    model.content_blob.dump_data_to_file
    assert !builder.is_supported?(model)
  end
  
  test "is supported with versioned model" do
    builder = Seek::JWSModelBuilder.new
    model=model_versions(:teusink_v2)
    model.content_blob.dump_data_to_file
    assert builder.is_supported?(model)
    
    model=model_versions(:jws_model_v1)
    model.content_blob.dump_data_to_file
    assert builder.is_supported?(model)
    
    model=model_versions(:model_jws_incompatible_v1)
    model.content_blob.dump_data_to_file
    assert !builder.is_supported?(model)
  end
  
  test "is sbml" do
    builder = Seek::JWSModelBuilder.new
    model=models(:teusink)
    model.content_blob.dump_data_to_file
    assert builder.is_sbml?(model)
    assert !builder.is_dat?(model)
  end
  
  test "is jws dat" do
    builder = Seek::JWSModelBuilder.new
    model=models(:jws_model)
    model.content_blob.dump_data_to_file
    assert !builder.is_sbml?(model)
    assert builder.is_dat?(model)
  end
  
  test "non sbml xml file" do
    builder = Seek::JWSModelBuilder.new
    model=models(:non_sbml_xml)
    model.content_blob.dump_data_to_file
    assert !builder.is_sbml?(model)
    assert !builder.is_dat?(model)
    assert !builder.is_supported?(model)
  end
  
  test "non jws dat file" do
    builder = Seek::JWSModelBuilder.new
    model=models(:non_jws_dat)
    model.content_blob.dump_data_to_file
    assert !builder.is_sbml?(model)
    assert !builder.is_dat?(model)
    assert !builder.is_supported?(model)
  end
  
  test "jws online response handled when errors present" do
    builder = Seek::JWSModelBuilder.new
    model=models(:invalid_sbml_xml)
    params_hash,saved_file,objects_hash,error_keys = builder.builder_content model.versions.first
    assert !error_keys.empty?
  end
  
end