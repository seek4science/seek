require 'test_helper'
require 'jws_online_test_helper'

class JwsInteractionModuleTest < ActiveSupport::TestCase

  include Seek::Jws::Interaction
  include JwsOnlineTestHelper

  test "determine_csrf_token" do
    token = determine_csrf_token
    refute_nil token
    assert token.length > 5
    assert_match /^[a-zA-Z0-9]+$/,token
  end

  test "upload model blob" do
    model = Factory(:teusink_model)
    blob = model.content_blobs.first
    slug = upload_model_blob(blob)
    refute_nil slug
    assert_match /^[a-zA-Z0-9-]+$/,slug
  end

  test "upload model blob using https" do
    with_config_value :jws_online_root,"https://jws2.sysmo-db.org" do
      model = Factory(:teusink_model)
      blob = model.content_blobs.first
      slug = upload_model_blob(blob)
      refute_nil slug
      assert_match /^[a-zA-Z0-9-]+$/,slug
    end
  end

  test "extract_slug_from_url" do
    assert_equal "frog",extract_slug_from_url("http://jws2.sysmo-db.org/models/frog")
    assert_equal "frog",extract_slug_from_url("http://jws2.sysmo-db.org/models/frog/")
    assert_equal "frog",extract_slug_from_url("http://jws2.sysmo-db.org/models/frog/simulate")

    assert_equal "carrot-2",extract_slug_from_url("https://jws2.sysmo-db.org/models/carrot-2")
    assert_equal "carrot-2",extract_slug_from_url("https://jws2.sysmo-db.org/models/carrot-2/")
    assert_equal "carrot-2",extract_slug_from_url("https://jws2.sysmo-db.org/models/carrot-2/simulate/anything/else")

    assert_equal "fish-soup",extract_slug_from_url("http://10.10.10.10/models/fish-soup")
    assert_equal "fish-soup",extract_slug_from_url("http://10.10.10.10/models/fish-soup/")
    assert_equal "fish-soup",extract_slug_from_url("http://10.10.10.10/models/fish-soup/simulate")
  end

  test "model_simulate_url_from_slug" do
    expected="http://jws2.sysmo-db.org/models/bob-2/simulate?embedded=1"
    assert_equal expected,model_simulate_url_from_slug("bob-2")
  end


end