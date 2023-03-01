require 'test_helper'

class GalaxyClientTest < ActiveSupport::TestCase
  GALAXY_EU = 'https://usegalaxy.eu/api'
  GALAXY_AUS = 'https://usegalaxy.org.au/api'

  test 'can fetch galaxy tools' do
    eu_client = Galaxy::Client.new(GALAXY_EU)
    aus_client = Galaxy::Client.new(GALAXY_AUS)
    VCR.use_cassette('galaxy/fetch_tools_trimmed') do
      tools = eu_client.tools
      assert_equal 2, tools.length
      get_data = tools.detect { |t| t['id'] == 'get_data' }
      assert get_data
      ena = get_data['elems'].detect { |e| e['id'] == 'toolshed.g2.bx.psu.edu/repos/iuc/enasearch_search_data/enasearch_search_data/0.1.1.0' }
      assert ena

      tools = aus_client.tools
      assert_equal 2, tools.length
      vcfbcf = tools.detect { |t| t['id'] == 'vcfbcf' }
      assert vcfbcf
      bcftools = vcfbcf['elems'].detect { |e| e['id'] == 'toolshed.g2.bx.psu.edu/repos/iuc/bcftools_plugin_fill_tags/bcftools_plugin_fill_tags/1.15.1+galaxy3' }
      assert bcftools
    end
  end

  test 'raises exceptions on bad status' do
    stub_request(:any, 'http://mocked404.com/api/tools').to_return(status: 404)
    stub_request(:any, 'http://mocked500.com/api/tools').to_return(status: 500)

    error_client_404 = Galaxy::Client.new('http://mocked404.com/api')
    assert_raises(RestClient::NotFound) do
      error_client_404.tools
    end

    error_client_500 = Galaxy::Client.new('http://mocked500.com/api')
    assert_raises(RestClient::InternalServerError) do
      error_client_500.tools
    end
  end
end
