require 'test_helper'
require 'openbis_test_helper'

class OpenbisExternalAssetTest < ActiveSupport::TestCase
  def setup
    mock_openbis_calls
    @endpoint = FactoryBot.create(:openbis_endpoint)

    @asset = OpenbisExternalAsset.new
    @asset.seek_service = @endpoint
  end

  test 'builds from Zample' do
    zample = Seek::Openbis::Zample.new(@endpoint, '20171002172111346-37')
    options = { tomek: false }
    asset = OpenbisExternalAsset.build(zample, options)

    assert_equal @endpoint, asset.seek_service
    assert_equal '20171002172111346-37', asset.external_id

    # 'https://openbis-api.fair-dom.org/openbis',
    # assert_equal @endpoint.web_endpoint, asset.external_service
    assert_equal @endpoint.id.to_s, asset.external_service
    assert_equal '2017-10-02T18:09:34+00:00', asset.external_mod_stamp

    assert_equal 'Seek::Openbis::Zample', asset.external_type
    assert asset.synchronized_at
    assert_equal 'synchronized', asset.sync_state
    assert asset.synchronized?
    assert_equal options, asset.sync_options
    assert_equal 1, asset.version

    refute asset.sync_options_json
    assert asset.valid?
    assert asset.save

    assert asset.sync_options_json
    assert asset.send(:local_content_json)
    assert_same zample, asset.content
  end

  test 'deserializes Zample from content' do
    zample = Seek::Openbis::Zample.new(@endpoint, '20171002172111346-37')
    @asset.external_type = zample.class.to_s
    json = @asset.serialize_content zample
    assert json

    entity = @asset.deserialize_content json
    assert entity
    assert_equal Seek::Openbis::Zample, entity.class
    assert_equal zample, entity
  end

  test 'builds from Dataset' do
    entity = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')
    options = { tomek: false }
    asset = OpenbisExternalAsset.build(entity, options)

    assert_equal @endpoint, asset.seek_service
    assert_equal '20160210130454955-23', asset.external_id

    # 'https://openbis-api.fair-dom.org/openbis'
    # assert_equal @endpoint.web_endpoint, asset.external_service

    assert_equal @endpoint.id.to_s, asset.external_service
    assert_equal '2016-02-10T12:04:55+00:00', asset.external_mod_stamp

    assert_equal 'Seek::Openbis::Dataset', asset.external_type
    assert asset.synchronized_at
    assert_equal 'synchronized', asset.sync_state
    assert asset.synchronized?
    assert_equal options, asset.sync_options
    assert_equal 1, asset.version

    refute asset.sync_options_json
    assert asset.valid?
    assert asset.save

    assert asset.sync_options_json
    assert asset.send(:local_content_json)
    assert_same entity, asset.content
  end

  test 'registered? works' do
    zample = Seek::Openbis::Zample.new(@endpoint, '20171002172111346-37')

    refute OpenbisExternalAsset.registered?(zample)

    asset = OpenbisExternalAsset.new(external_service: zample.openbis_endpoint.id, external_id: zample.perm_id)
    assert asset.save

    assert OpenbisExternalAsset.registered?(zample)
  end

  test 'needs_reindexing is always true for new record' do
    asset = OpenbisExternalAsset.new
    assert asset.needs_reindexing

    zample = Seek::Openbis::Zample.new(@endpoint, '20171002172111346-37')
    options = { tomek: false }
    asset = OpenbisExternalAsset.build(zample, options)

    assert asset.needs_reindexing

    asset.content = zample
    assert asset.needs_reindexing
  end

  test 'find_by_entity works' do
    zample = Seek::Openbis::Zample.new(@endpoint, '20171002172111346-37')

    assert_raises(ActiveRecord::RecordNotFound) do
      OpenbisExternalAsset.find_by_entity(zample)
    end

    asset = OpenbisExternalAsset.new(external_service: zample.openbis_endpoint.id, external_id: zample.perm_id)
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

  test 'openbis_search_terms' do
    dataset = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')

    asset = OpenbisExternalAsset.build(dataset)
    terms = asset.search_terms

    assert_includes terms, '20160210130454955-23'
    assert_includes terms, 'TEST_DATASET_TYPE'
    assert_includes terms, 'for api test'
    assert_includes terms, 'original/autumn.jpg'
    assert_includes terms, 'autumn.jpg'
    assert_includes terms, 'apiuser'

    # values form openbis parametes as well as key:value pairs
    assert_includes terms, 'DataFile_3'
    assert_includes terms, 'SEEK_DATAFILE_ID:DataFile_3'
  end

  test 'openbis_search_terms simplifies rich text content' do
    experiment = Seek::Openbis::Experiment.new(@endpoint, '20171121152132641-51')
    asset = OpenbisExternalAsset.build(experiment)

    terms = asset.search_terms

    goals = terms.select { |t| t.start_with? 'EXPERIMENTAL_GOALS' }.first
    comments = terms.select { |t| t.start_with? 'XMLCOMMENTS' }.first
    assert goals
    assert comments
    # puts goals
    # puts comments

    refute goals.include? 'body'
    refute goals.include? '<body>'
    refute goals.include? '<ul>'
    assert goals.include? 'many circadian clock-associated genes have been identified.'
    assert_equal 'XMLCOMMENTS:My first comment', comments
  end

  test 'removeTAGS cleans html tags' do
    experiment = Seek::Openbis::Experiment.new(@endpoint, '20171121152132641-51')
    asset = OpenbisExternalAsset.build(experiment)

    text = '
<?xml version="1.0" encoding="UTF-8"?>
<body><ul class="big">
 <li style="weight: bold;">In Arabidopsis thaliana, many circadian clock-associated genes have been identified.</li>
</ul></body>
'
    res = asset.remove_tags(text)
    # puts res
    exp = 'In Arabidopsis thaliana, many circadian clock-associated genes have been identified.'
    assert_equal exp, res
  end

  test 'removeTAGS cleans xml coments' do
    experiment = Seek::Openbis::Experiment.new(@endpoint, '20171121152132641-51')
    asset = OpenbisExternalAsset.build(experiment)

    text = '
<root><commentEntry date=\"1511277676686\" person=\"seek\">My first comment</commentEntry></root>
'
    res = asset.remove_tags(text)
    # puts res
    exp = 'My first comment'
    assert_equal exp, res
  end

  test 'removeTAGS escapes <> in text' do
    experiment = Seek::Openbis::Experiment.new(@endpoint, '20171121152132641-51')
    asset = OpenbisExternalAsset.build(experiment)

    text = ' temp < 3 C but > 2'
    res = asset.remove_tags(text)
    # puts res
    exp = 'temp &lt; 3 C but &gt; 2'
    assert_equal exp, res
  end
end
