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

    assay = @util.createObisAssay(params, @creator,@zample,sync_options)

    assert assay.valid?

    assert_difference('Assay.count') do
      assert_difference('ExternalAsset.count') do
        assay.save!
      end
    end

  end
end
