require 'test_helper'

class JwsUnitTest < ActiveSupport::TestCase

  def setup
    skip("currently skipping jws online tests") if skip_jws_tests?
    WebMock.allow_net_connect!
    @builder = Seek::JWS::Builder.new
  end

  test "jws online response handled when errors present" do
    blob=Factory :invalid_sbml_content_blob
    params_hash,attributions,saved_file,objects_hash,error_keys = @builder.builder_content blob
    assert !error_keys.empty?
    assert error_keys.include?("parameters")
  end if Seek::Config.jws_enabled

  test "jws online response with valid SBML model" do
    blob=Factory :teusink_model_content_blob
    params_hash,attributions,saved_file,objects_hash,error_keys = @builder.builder_content blob
    assert error_keys.empty?
    assert !params_hash.empty?
    assert objects_hash.empty?
    assert_not_nil attributions
    #skipping this assertion whilst waiting for a fix from JWS online
    assert_equal "teusink",attributions.model_name
    assert_not_nil saved_file
  end if Seek::Config.jws_enabled

  test "jws online response with valid JWS Dat model" do
    blob=Factory :teusink_jws_model_content_blob
    params_hash,attributions,saved_file,objects_hash,error_keys = @builder.builder_content blob
    assert error_keys.empty?
    assert !params_hash.empty?
    assert objects_hash.empty?
    assert_not_nil attributions
    assert_equal "teusink20101021091712",attributions.model_name
    assert_not_nil saved_file
  end if Seek::Config.jws_enabled
  
end
