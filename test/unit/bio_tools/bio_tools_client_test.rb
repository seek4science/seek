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

  test 'can generate tool url' do
    assert_equal 'https://bio.tools/galaxy', BioTools::Client.tool_url('galaxy')
    assert_equal 'https://bio.tools/cufluxsampler.jl', BioTools::Client.tool_url('cufluxsampler.jl')
    assert_equal 'https://bio.tools/bio.tools', BioTools::Client.tool_url('bio.tools')
  end

  test 'can match tool id from url' do
    assert_equal 'galaxy', BioTools::Client.match_id('https://bio.tools/galaxy')
    assert_equal 'cufluxsampler.jl', BioTools::Client.match_id('https://bio.tools/cufluxsampler.jl')
    assert_equal 'bio.tools', BioTools::Client.match_id('https://bio.tools/bio.tools')
    assert_nil BioTools::Client.match_id('https://some-other-website.website')
    assert_nil BioTools::Client.match_id('galaxy')
  end
end
