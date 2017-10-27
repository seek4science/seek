require 'test_helper'
require 'openbis_test_helper'

class SeekUtilTest < ActiveSupport::TestCase
  fixtures :studies

  def setup
    mock_openbis_calls
    @endpoint = Factory(:openbis_endpoint)
    @util = Seek::Openbis::SeekUtil.new
    @study = studies(:junk_study)
    @zample = Seek::Openbis::Zample.new(@endpoint, '20171002172111346-37')
    @creator = Factory(:person)
  end

  test 'setup work' do
    assert @util
    assert @study
    assert  @zample
    assert @creator
  end

  test 'creates valid assay with dependent external_asset that can be saved' do

    params = { study_id: @study.id}
    sync_options = {link_datasets: '1'}

    asset = OpenbisExternalAsset.build(@zample, sync_options)

    assay = @util.createObisAssay(params, @creator,asset)

    assert assay.valid?

    assert_difference('Assay.count') do
      assert_difference('ExternalAsset.count') do
        assay.save!
      end
    end


    assert_equal "OpenBIS #{@zample.perm_id}", assay.title
    assert_equal @creator, assay.contributor
    assert_same asset, assay.external_asset
  end

  test 'creates valid datafile with dependent external_assed that can be saved' do
    dataset = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')
    assert dataset

    asset = OpenbisExternalAsset.build(dataset)

    df = @util.createObisDataFile(asset)

    assert df.valid?

    assert_difference('DataFile.count') do
      assert_difference('ExternalAsset.count') do
        df.save!
      end
    end
  end
end
