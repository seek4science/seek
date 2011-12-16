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
  
end