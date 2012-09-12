require 'test_helper'

class JwsUnitTest < ActiveSupport::TestCase
  fixtures :all

  def setup
    WebMock.allow_net_connect!
    @builder = Seek::JWS::Builder.new
  end

  test "jws online response handled when errors present" do
    model=models(:invalid_sbml_xml)
    params_hash,attributions,saved_file,objects_hash,error_keys = @builder.builder_content model.versions.first
    assert !error_keys.empty?
    assert error_keys.include?("parameters")
  end if Seek::Config.jws_enabled

  test "jws online response with valid SBML model" do
    model=Factory :teusink_model
    params_hash,attributions,saved_file,objects_hash,error_keys = @builder.builder_content model.versions.first
    assert error_keys.empty?
    assert !params_hash.empty?
    assert objects_hash.empty?
    assert_not_nil attributions
    assert_equal "teusink",attributions.model_name
    assert_not_nil saved_file
  end if Seek::Config.jws_enabled

  test "jws online response with valid JWS Dat model" do
    model=Factory :teusink_jws_model
    params_hash,attributions,saved_file,objects_hash,error_keys = @builder.builder_content model.versions.first
    assert error_keys.empty?
    assert !params_hash.empty?
    assert objects_hash.empty?
    assert_not_nil attributions
    assert_equal "teusink20101021091712",attributions.model_name
    assert_not_nil saved_file
  end if Seek::Config.jws_enabled
  
end