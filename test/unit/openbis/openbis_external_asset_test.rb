require 'test_helper'
require 'openbis_test_helper'

class OpenbisExternalAssetTest < ActiveSupport::TestCase

  def setup
    mock_openbis_calls
    @endpoint = Factory(:openbis_endpoint)

    @asset = OpenbisExternalAsset.new
    @asset.seek_service = @endpoint

  end

  test 'builds from Zample' do

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

  test 'deserializes Zample from content' do


    zample = Seek::Openbis::Zample.new(@endpoint, '20171002172111346-37')
    @asset.external_type = "#{zample.class}"
    json = @asset.serialize_content zample
    assert json

    entity = @asset.deserialize_content json
    assert entity
    assert_equal Seek::Openbis::Zample, entity.class
    assert_equal zample, entity


  end


  test 'registered? works' do

    zample = Seek::Openbis::Zample.new(@endpoint, '20171002172111346-37')

    refute OpenbisExternalAsset.registered?(zample)

    asset = OpenbisExternalAsset.new({external_service: zample.openbis_endpoint.web_endpoint, external_id: zample.perm_id})
    assert asset.save

    assert OpenbisExternalAsset.registered?(zample)

  end

  test 'find_by_entity works' do

    zample = Seek::Openbis::Zample.new(@endpoint, '20171002172111346-37')

    assert_raises( ActiveRecord::RecordNotFound ) {
      OpenbisExternalAsset.find_by_entity(zample)
    }

    asset = OpenbisExternalAsset.new({external_service: zample.openbis_endpoint.web_endpoint, external_id: zample.perm_id})
    assert asset.save

    assert OpenbisExternalAsset.find_by_entity(zample)

  end

  test 'find_or_create_by_entity finds or creates' do

    zample = Seek::Openbis::Zample.new(@endpoint, '20171002172111346-37')

    asset = OpenbisExternalAsset.find_or_create_by_entity(zample)
    assert asset
    assert asset.is_a? OpenbisExternalAsset
    refute asset.persisted?
    assert asset.new_record?
    assert_same asset.content, zample

    assert asset.save!

    asset = OpenbisExternalAsset.find_or_create_by_entity(zample)
    assert asset
    assert asset.is_a? OpenbisExternalAsset
    assert asset.persisted?
    refute asset.new_record?
    assert_equal asset.content, zample
  end

end