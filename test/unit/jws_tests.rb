require File.dirname(__FILE__) + '/../test_helper'

class JWSTests < ActiveSupport::TestCase  
  fixtures :all
  
  include Seek::ModelExecution
  
  test "jws execution applet" do
    model=models(:teusink)
    resp=jws_execution_applet model    
    assert resp.include?("applet")
  end
  
  test "jws execution applet biomodel model" do
    model=models(:francos_model)
    resp=jws_execution_applet model
    assert resp.include?("applet")
  end
  
  test "is supported" do
    model=models(:teusink)
    assert Seek::JWSModelBuilder.is_supported?(model)
    
    model=models(:jws_model)
    assert Seek::JWSModelBuilder.is_supported?(model)
    
    model=models(:model_jws_incompatible)
    assert !Seek::JWSModelBuilder.is_supported?(model)
  end
end