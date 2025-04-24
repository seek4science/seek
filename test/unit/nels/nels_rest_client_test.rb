require 'test_helper'
require 'rest-client'

class NelsRestClientTest < ActiveSupport::TestCase
  setup do
    # Note, these IDs/tokens/references have been altered so they don't match what is in the real API (even though it is dummy data anyway)
    @rest_client = Nels::Rest::Client.new('fake-access-token')
    @project_id = 91_123_122
    @dataset_id = 91_123_528
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

  test 'get project' do
    VCR.use_cassette('nels/get_project') do
      res = @rest_client.project(@project_id)

      assert_equal 20, res.count
      assert_equal @project_id, res['id']
      assert_equal 'seek_pilot1', res['name']
      assert_equal 3, res['membership_type']
    end
  end

  test 'can get datasets' do
    VCR.use_cassette('nels/get_datasets') do
      res = @rest_client.datasets(@project_id)

      assert_equal 2, res.count
      refute res[0]['islocked']
      assert res[1]['islocked']
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
      refute res['islocked']
      subtype = res['subtypes'].detect { |s| s['type'] == @subtype }
      assert_equal 0, subtype['size']
    end
  end

  test 'get locked dataset' do
    VCR.use_cassette('nels/get_locked_dataset') do
      res = @rest_client.dataset(@project_id, @dataset_id)
      assert_equal @dataset_id, res['id']
      assert res['islocked']
    end
  end

  test 'can create persistent url' do
    VCR.use_cassette('nels/get_persistent_url') do
      url = @rest_client.persistent_url(@project_id, @dataset_id, @subtype)
      assert(%r{https://test-fe\.cbu\.uib\.no/nels/pages/sbi/sbi\.xhtml\?ref=[a-zA-Z0-9]+}, url)
    end
  end

  test 'can get sample metadata' do
    VCR.use_cassette('nels/get_sample_metadata') do
      assert @rest_client.sample_metadata(@reference).size > 1
    end
  end

  test 'check metadata exists' do
    VCR.use_cassette('nels/check_metadata_exists') do
      refute @rest_client.check_metadata_exists(@project_id, @dataset_id, @subtype)
      assert @rest_client.check_metadata_exists(@project_id, @dataset_id + 1, @subtype)
    end
  end

  test 'get sbi_storage_list' do
    VCR.use_cassette('nels/sbi_storage_list') do
      json = @rest_client.sbi_storage_list(@project_id, @dataset_id, 'Storebioinfo/seek_pilot3/Demo Dataset/Analysis/')
      assert_equal 7, json.length
      assert_equal 5, json.select { |x| x['isFolder'] }.length
      last = { 'name' => 'test5', 'size' => 0, 'path' => 'Storebioinfo/seek_pilot3/Demo Dataset/Analysis/test5',
               'project_id' => 91_123_122, 'dataset_id' => 91_123_528, 'refid' => '8cd8932b-805e-4f1b-8f60-2e8103d9700c', 'description' => '', 'islocked' => false, 'membership_type' => 2, 'isFolder' => true }
      assert_equal last, json.last
    end
  end

  test 'download file' do
    filename, path = nil

    VCR.use_cassette('nels/download_file') do
      filename, path = @rest_client.download_file(1_125_299, 1_124_840, 'analysis', '', 'pegion.png')
    end

    assert_equal 'pegion.png', filename
    assert path.start_with?('/tmp/nels-download-')
    assert File.exist?(path)
    File.delete(path)
  end

  test 'upload file' do
    VCR.use_cassette('nels/upload_file') do
      file_path = File.join(Rails.root, 'test', 'fixtures', 'files', 'little_file.txt')
      assert File.exist?(file_path)
      @rest_client.upload_file(1_125_299, 1_124_840, 'analysis', '', 'little_file.txt', file_path)
    end
  end

  test 'upload file with MethodNotAllowed error' do
    VCR.use_cassette('nels/upload_file_405_error') do
      file_path = File.join(Rails.root, 'test', 'fixtures', 'files', 'little_file.txt')
      assert File.exist?(file_path)
      assert_raises RestClient::MethodNotAllowed do
        @rest_client.upload_file(1_125_299, 1_124_840, 'analysis', '', 'little_file.txt', file_path)
      end
    end
  end

  test 'upload file with Unauthorized error' do
    VCR.use_cassette('nels/upload_file_401_error') do
      file_path = File.join(Rails.root, 'test', 'fixtures', 'files', 'little_file.txt')
      assert File.exist?(file_path)
      assert_raises RestClient::Unauthorized do
        @rest_client.upload_file(1_125_299, 1_124_840, 'analysis', '', 'little_file.txt', file_path)
      end
    end
  end

  test 'create dataset' do
    VCR.use_cassette('nels/create_dataset') do
      assert_nothing_raised do
        res = @rest_client.create_dataset(1_125_299, 225, 'test dataset', 'testing creating a dataset')
        assert_equal 200, res.code
      end
    end
  end

  test 'create folder' do
    VCR.configure do |c|
      c.before_http_request do |request|
        raise RestClient::Exceptions::ReadTimeout if JSON.parse(request.body)['method'] == 'add'
      end
    end

    VCR.use_cassette('nels/sbi_storage_list_create_folder') do
      assert_nothing_raised do
        @rest_client.create_folder(1_125_299, 1_125_261, 'Storebioinfo/seek_pilot3/Demo Dataset/Analysis/', 'test')
      end
    end

  ensure
    VCR.configure do |c|
      c.before_http_request.clear
    end
  end
end
