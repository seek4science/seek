require File.dirname(__FILE__) + '/../test_helper'

class JWSTests < ActiveSupport::TestCase  
  fixtures :all           
  
  test "is supported" do
    builder = Seek::JWSModelBuilder.new
    model=models(:teusink)
    assert builder.is_supported?(model)
    
    model=models(:jws_model)
    assert builder.is_supported?(model)
    
    model=models(:model_jws_incompatible)
    assert !builder.is_supported?(model)
  end
  
  test "is supported with versioned model" do
    builder = Seek::JWSModelBuilder.new
    model=model_versions(:teusink_v2)
    assert builder.is_supported?(model)
    
    model=model_versions(:jws_model_v1)
    assert builder.is_supported?(model)
    
    model=model_versions(:model_jws_incompatible_v1)
    assert !builder.is_supported?(model)
  end
  
  test "is sbml" do
    builder = Seek::JWSModelBuilder.new
    model=models(:teusink)
    assert builder.is_sbml?(model)
    assert !builder.is_dat?(model)
  end
  
  test "is jws dat" do
    builder = Seek::JWSModelBuilder.new
    model=models(:jws_model)
    assert !builder.is_sbml?(model)
    assert builder.is_dat?(model)
  end
  
end