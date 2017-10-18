require 'test_helper'
require 'openbis_test_helper'

class OpenbisExternalAssetTest < ActiveSupport::TestCase

  def setup
    mock_openbis_calls
    @endpoint = Factory(:openbis_endpoint)
  end

  test 'can create from Zample' do

    zample = Seek::Openbis::Zample.new(@endpoint, '20171002172111346-37')
    options = {tomek: false}
    asset = OpenbisExternalAsset.build(zample, options)

    assert_equal @endpoint, asset.seek_service
    assert_equal '20171002172111346-37', asset.external_id

    assert_equal 'https://openbis-api.fair-dom.org/openbis', asset.external_service
    assert_equal '2017-10-02T18:09:34+00:00', asset.external_mod_stamp

    assert_equal 'Seek::Openbis::Zample', asset.external_type
    assert asset.synchronized_at
    assert_equal 'synchronized', asset.sync_state
    assert asset.synchronized?
    assert_equal  options, asset.sync_options
    assert_equal 1, asset.version

    refute asset.sync_options_json
    assert asset.valid?
    assert asset.save

    assert asset.sync_options_json
    assert asset.local_content_json
    assert_same zample, asset.content
  end


end