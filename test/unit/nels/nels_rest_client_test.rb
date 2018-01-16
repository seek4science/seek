require 'test_helper'

class NelsRestClientTest < ActiveSupport::TestCase

  setup do
    # Note, these IDs/tokens/references have been altered so they don't match what is in the real API (even though it is dummy data anyway)
    @rest_client = Nels::Rest::Client.new('fake-access-token')
    @project_id = 91123122
    @dataset_id = 91123528
    @subtype = 'reads'
    @reference = 'xMTEyMzEyMjoxMTIzNTI4OnJlYWRz'
  end

  test 'can get user info' do
    VCR.use_cassette('nels/get_user_info') do
      res = @rest_client.user_info

      assert_equal 'Finn Bacall', res['name']
    end
  end

  test 'can get projects' do
    VCR.use_cassette('nels/get_projects') do
      res = @rest_client.projects

      assert_equal 2, res.count
      project = res.detect { |p| p['id'] == @project_id }
      assert_equal 'seek_pilot1', project['name']
    end
  end

  test 'can get datasets' do
    VCR.use_cassette('nels/get_datasets') do
      res = @rest_client.datasets(@project_id)

      assert_equal 2, res.count
      dataset = res.detect { |d| d['id'] == @dataset_id }
      assert_equal 'Illumina-sequencing-dataset', dataset['name']
      assert_equal 'Illumina_seq_data', dataset['type']
    end
  end

  test 'can get specific dataset' do
    VCR.use_cassette('nels/get_dataset') do
      res = @rest_client.dataset(@project_id, @dataset_id)

      assert_equal @dataset_id, res['id']
      assert_equal 2, res['subtypes'].count
      subtype = res['subtypes'].detect { |s| s['type'] == @subtype }
      assert_equal 0, subtype['size']
    end
  end

  test 'can create persistent url' do
    VCR.use_cassette('nels/get_persistent_url') do
      url = @rest_client.persistent_url(@project_id, @dataset_id, @subtype)
      assert /https:\/\/test-fe\.cbu\.uib\.no\/nels\/pages\/sbi\/sbi\.xhtml\?ref\=[a-zA-Z0-9]+/, url
    end
  end

  test 'can get sample metadata' do
    VCR.use_cassette('nels/get_sample_metadata') do
      assert @rest_client.sample_metadata(@reference).size > 1
    end
  end

end
