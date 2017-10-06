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

  test 'stores UTF string content that can be retrieved' do
    asset1 = ExternalAsset.new({external_service: 'OpenBIS', external_id: '25'})
    asset1.content = 'Tomekółść'
    assert asset1.save

    asset2 = ExternalAsset.last
    assert_equal asset1, asset2
    assert_equal 'Tomekółść', asset2.content

  end

  test 'updates content on save' do
    asset1 = ExternalAsset.new({external_service: 'OpenBIS', external_id: '25'})
    asset1.content = 'Tomekółść'
    assert asset1.save
    asset1.content = 'Tomek1'
    assert asset1.save

    asset2 = ExternalAsset.last
    assert_equal asset1, asset2
    assert_equal 'Tomek1', asset2.content

    asset1.content = 'Tomek2'
    assert asset1.save
    asset2.reload
    assert_equal 'Tomek2', asset2.content

  end

  test 'content is saved lazy' do

    asset1 = ExternalAsset.new({external_service: 'OpenBIS', external_id: '24'})
    asset1.build_content_blob({ url: 'openb-cos', original_filename: "openbis-file",
                                make_local_copy: false, external_link: false, })


    assert_no_difference('ExternalAsset.count') do
      assert_no_difference('ContentBlob.count') do
        assert asset1.content = "23"
      end
    end

    assert_difference('ExternalAsset.count',1) do
      assert_difference('ContentBlob.count',1) do
        assert asset1.save
      end
    end

  end

end