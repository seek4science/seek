require 'test_helper'

class ExternalAssetTest < ActiveSupport::TestCase

  test 'can create' do

    asset = ExternalAsset.new({external_service: 'OpenBIS', external_id: '23'})

    assert asset.save
  end



  test 'validation fails if service and external id are not unique' do

    asset1 = ExternalAsset.new({external_service: 'OpenBIS', external_id: '23'})
    assert asset1.save

    asset2 = ExternalAsset.new({external_service: 'OpenBIS', external_id: '23'})
    refute asset2.valid?

    asset2 = ExternalAsset.new({external_service: 'OpenBIS1', external_id: '23'})
    assert asset2.valid?

    asset2 = ExternalAsset.new({external_service: 'OpenBIS', external_id: '231'})
    assert asset2.valid?

  end

  test 'save fails in db if service and external id are not unique' do

    asset1 = ExternalAsset.new({external_service: 'OpenBIS', external_id: '23'})
    assert asset1.save

    asset2 = ExternalAsset.new({external_service: 'OpenBIS', external_id: '23'})
    assert_raises(Exception) {
      asset2.save validate:false
    }

    asset2 = ExternalAsset.new({external_service: 'OpenBIS1', external_id: '23'})
    assert asset2.save validate:false

    asset2 = ExternalAsset.new({external_service: 'OpenBIS', external_id: '231'})
    assert asset2.save validate:false

  end

  test 'build_content sets the relationship that is persisted upon save' do

    asset1 = ExternalAsset.new({external_service: 'OpenBIS', external_id: '24'})
    asset1.build_content_blob({ url: 'openb-cos', original_filename: "openbis-file",
                                make_local_copy: false, external_link: false, })

    refute asset1.content_blob.nil?

    assert_difference('ExternalAsset.count') do
      assert_difference('ContentBlob.count') do
        assert asset1.save
      end
    end

    assert ExternalAsset.exists? asset1.id
    assert ContentBlob.exists? asset1.content_blob.id
    assert_equal asset1, ContentBlob.find(asset1.content_blob.id).asset
  end

  test 'content_blob is deleted with exteranl asset' do

    asset1 = ExternalAsset.new({external_service: 'OpenBIS', external_id: '24'})
    asset1.build_content_blob({ url: 'openb-cos', original_filename: "openbis-file",
                                make_local_copy: false, external_link: false, })

    assert_difference('ExternalAsset.count') do
      assert_difference('ContentBlob.count') do
        assert asset1.save
      end
    end

    assert_difference('ExternalAsset.count',-1) do
      assert_difference('ContentBlob.count',-1) do
        assert asset1.destroy
      end
    end

    refute ContentBlob.exists? asset1.content_blob.id

  end

  test 'stores UTF string in local_content_json that can be retrieved' do
    asset1 = ExternalAsset.new({external_service: 'OpenBIS', external_id: '25'})
    asset1.local_content_json = 'Tomekółść'
    assert asset1.save

    asset2 = ExternalAsset.last
    assert_equal asset1, asset2
    assert_equal 'Tomekółść', asset2.local_content_json

  end

  test 'updates local_content_json on save' do
    asset1 = ExternalAsset.new({external_service: 'OpenBIS', external_id: '25'})
    asset1.local_content_json = 'Tomekółść'
    assert asset1.save
    asset1.local_content_json = 'Tomek1'
    assert asset1.save

    asset2 = ExternalAsset.last
    assert_equal asset1, asset2
    assert_equal 'Tomek1', asset2.local_content_json

    asset1.local_content_json = 'Tomek2'
    assert asset1.save
    asset2.reload
    assert_equal 'Tomek2', asset2.local_content_json

  end

  test 'content is saved lazy' do

    asset1 = ExternalAsset.new({external_service: 'OpenBIS', external_id: '24'})
    asset1.build_content_blob({ url: 'openb-cos', original_filename: "openbis-file",
                                make_local_copy: false, external_link: false, })


    assert_no_difference('ExternalAsset.count') do
      assert_no_difference('ContentBlob.count') do
        assert asset1.local_content_json = "23"
      end
    end

    assert_difference('ExternalAsset.count',1) do
      assert_difference('ContentBlob.count',1) do
        assert asset1.save
      end
    end

  end

  test 'options are serialized before saving and read back' do
    asset1 = ExternalAsset.new({external_service: 'OpenBIS', external_id: '24'})
    opt = {tomek: 2}
    asset1.sync_options = opt

    #refute asset1.sync_options_json

    assert asset1.save
    #assert_equal '{"tomek":2}', asset1.sync_options_json

    #asset1.sync_options = nil
    asset2 = ExternalAsset.find(asset1.id)
    assert_equal opt, asset2.sync_options

    opt = {}
    asset1.sync_options = opt
    assert asset1.save

    asset2 = ExternalAsset.find(asset1.id)
    assert_equal opt, asset2.sync_options

  end



  test 'content_changed is true after settng content value' do
    asset1 = ExternalAsset.new({external_service: 'OpenBIS', external_id: '25'})
    refute asset1.content_changed

    asset1.content = {'key1': 'value1'}
    assert asset1.content_changed
  end

  test 'needs_reindexing tracks mod stamp and content setting' do
    asset1 = ExternalAsset.new({external_service: 'OpenBIS', external_id: '25'})
    refute asset1.needs_reindexing
    assert asset1.save

    asset1.external_mod_stamp = 'X'
    assert asset1.needs_reindexing
    asset1.save

    asset1.external_mod_stamp = 'X'
    refute asset1.needs_reindexing

    asset1.external_mod_stamp = 'Y'
    assert asset1.needs_reindexing
    asset1.save

    asset1.external_mod_stamp = 'Y'
    refute asset1.needs_reindexing
    asset1.content = {'key1': 'value1'}
    asset1.external_mod_stamp = 'Y'
    assert asset1.needs_reindexing

    asset1.save
  end

  test 'extract_mod_stamp gives object hash' do

    asset = ExternalAsset.new({external_service: 'OpenBIS', external_id: '23'})

    assert_equal '-1', asset.extract_mod_stamp(nil)

    obj = {key1: 'value1'}
    assert_equal obj.hash.to_s, asset.extract_mod_stamp(obj)

    class TmpH
      def hash
        12
      end
    end

    obj = TmpH.new
    assert_equal '12', asset.extract_mod_stamp(obj)

  end

  test 'local_json_content can be read multiple times' do
    asset = ExternalAsset.new({external_service: 'OpenBIS', external_id: '23'})
    obj = {key1: 'value1'}
    asset.content = obj
    asset.save

    assert_equal obj.to_json, asset.local_content_json
    assert_equal obj.to_json, asset.local_content_json
    assert_equal obj.to_json, asset.local_content_json

  end

  test 'detect_change compares mod stamps' do
    asset = ExternalAsset.new({external_service: 'OpenBIS', external_id: '23'})
    obj = {key1: 'value1'}
    asset.content = obj

    refute asset.detect_change(obj, nil)
    asset.save
    refute asset.detect_change(obj, obj.to_json)

    asset.external_mod_stamp = 'X'
    assert asset.detect_change(obj, obj.to_json)


  end

  test 'save triggers reindexing if content changed' do

    assert Seek::Config.solr_enabled
    assay = Factory :assay

    asset1 = ExternalAsset.new({external_service: 'OpenBIS', external_id: '25'})
    assay.external_asset = asset1
    assert assay.save

    asset1.content = {'key1': 'value1'}
    asset1.external_mod_stamp = "ALA"
    asset1.sync_options = {'sync': false}

    Delayed::Job.destroy_all
    assert_difference('Delayed::Job.count', 1) do
      asset1.save
    end
    assert ReindexingQueue.exists?(item: assay)

    # to reload and clear field
    assay = Assay.find(assay.id)

    asset1 = assay.external_asset
    asset1.sync_options = {'sync': false}
    asset1.synchronized_at = DateTime.now

    assert_no_difference('Delayed::Job.count') do
      asset1.save
    end

    asset1.content = {'key1': 'value1'}
    Delayed::Job.destroy_all
    assert_difference('Delayed::Job.count', 1) do
      asset1.save
    end
    assert ReindexingQueue.exists?(item: assay)

  end

  class TmpJson1
    attr_reader :json
    def  initialize
      @json = 'Ha'
    end

    def to_json
      raise 'should not be called'
    end

  end

  class TmpJson2
    attr_reader :json
    def  initialize
      @json = {'Ha' => 1}
    end

    def to_json
      raise 'should not be called'
    end

  end


  test 'serialize calls defaults json methods, fields' do
    asset1 = ExternalAsset.new({external_service: 'OpenBIS', external_id: '24'})

    assert_equal '[2,3]', asset1.serialize_content([2, 3])
    assert_equal '{"t":false}', asset1.serialize_content({t: false})
    assert_equal 'Ha', asset1.serialize_content(TmpJson1.new)
    assert_equal '{"Ha":1}', asset1.serialize_content(TmpJson2.new)

  end

  test 'setting content object updates state' do
    asset1 = ExternalAsset.new({external_service: 'OpenBIS', external_id: '24'})

    obj = {key: 123}
    asset1.content = obj

    assert asset1.synchronized_at
    assert_equal 'synchronized', asset1.sync_state
    assert asset1.synchronized?
    assert_equal 1, asset1.version

    assert_same obj, asset1.content
    assert asset1.save
    assert_equal '{"key":123}', asset1.local_content_json

  end

  test 'accessing content deserialized local json if synchronized' do
    asset1 = ExternalAsset.new({external_service: 'OpenBIS', external_id: '24'})

    obj = {"tomek"=> 'yes'}
    asset1.sync_state = :synchronized
    asset1.local_content_json = obj.to_json
    assert asset1.save

    assert_equal obj, asset1.content
    asset2 = ExternalAsset.find(asset1.id)
    assert_equal obj, asset2.content

  end

  test 'accessing content triggers not implemented fetching if state is not synchronized' do
    asset1 = ExternalAsset.new({external_service: 'OpenBIS', external_id: '24'})

    obj = {"tomek"=> 'yes'}
    asset1.content = obj
    asset1.sync_state = :refresh

    assert_raises(Exception) do
      assert_equal obj, asset1.content
    end


  end

  class ExternalWithRemote < ExternalAsset

    attr_accessor :expected, :expected_date

    def extract_mod_stamp(content_object)
      @expected_date
    end

    def fetch_externally
      @expected
    end

  end

  test 'accessing content triggers fetching if state is not synchronized' do
    asset1 = ExternalWithRemote.new({external_service: 'OpenBIS', external_id: '24'})

    asset1.expected = {"remote" => 'yes'}
    asset1.expected_date = '12345'
    obj = {"tomek"=> 'no'}
    asset1.content = obj
    asset1.sync_state = :refresh

    obj = asset1.content
    assert_equal '12345', asset1.external_mod_stamp
    assert_equal asset1.expected, obj
    assert asset1.synchronized?

    asset1.expected = {"hope" => 'yes'}
    asset1.sync_state = :failed
    assert_equal asset1.expected, asset1.content
    assert asset1.synchronized?

  end


end