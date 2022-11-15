require 'test_helper'

class BioToolsClientTest < ActiveSupport::TestCase

  setup do
    @rest_client = BioTools::Client.new
  end

  test 'can query tools' do
    VCR.use_cassette('bio_tools/query_python') do
      res = @rest_client.filter('python')

      assert_equal 10, res['list'].length
      assert_equal 6215, res['count']
      assert_equal 'biopython', res['list'].first['biotoolsID']
      assert_nil res['previous']
      assert_equal '?page=2', res['next']
    end
  end

  test 'can query tools page 2' do
    VCR.use_cassette('bio_tools/query_python_page_2') do
      res = @rest_client.filter('python', page: 2)

      assert_equal 10, res['list'].length
      assert_equal 6215, res['count']
      assert_equal 'de-sim', res['list'].first['biotoolsID']
      assert_equal '?page=1', res['previous']
      assert_equal '?page=3', res['next']
    end
  end
end
