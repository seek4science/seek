require 'test_helper'

class RorClientTest < ActiveSupport::TestCase

  def setup
    @client = Ror::Client.new
  end

  def test_extract_ror_id
    assert_equal '04rcqnp59', @client.extract_ror_id('https://ror.org/04rcqnp59')
    assert_nil @client.extract_ror_id(nil)
    assert_nil @client.extract_ror_id('invalid_url')
    assert_nil @client.extract_ror_id('https://example.com/04rcqnp59')
  end

  def test_query_name_with_vcr
    VCR.use_cassette('ror/query_harvard_by_name') do
      response = @client.query_name('Harvard')
      assert response.key?('items'), 'Response should contain items key'
      assert response['items'].is_a?(Array), 'Items should be an array'
      assert response['items'].any?, 'Items array should not be empty'
    end
  end

  def test_fetch_by_id_with_vcr
    VCR.use_cassette('ror/fetch_by_id') do
      response = @client.fetch_by_id('03vek6s52')
      assert_equal 'https://ror.org/03vek6s52', response['id']
      assert_equal 'Harvard University', response['name']
      assert_equal 'Cambridge', response.dig('addresses', 0, 'city')
      assert_equal 'US', response.dig('country', 'country_code')
      assert_equal 'https://www.harvard.edu', response.dig('links', 0)
    end
  end

  def test_fetch_by_invalid_id_with_vcr
    VCR.use_cassette('ror/fetch_invalid_id') do
      response = @client.fetch_by_id('invalid_id')
      assert_equal "'invalid_id' is not a valid ROR ID", response[:error]
    end
  end

  test "returns an empty result when querying a nonexistent institution" do
    VCR.use_cassette("ror/ror_nonexistent_institution") do
      response = @client.query_name('nonexistentuniversity123')
      assert_equal 0, response["number_of_results"]
      assert_empty response["items"]
    end
  end

  def test_fussy_search_with_vcr
    VCR.use_cassette('ror/fussy_search_harvard_by_name') do
      response = @client.query_name('Harv')
      assert_equal 54, response['number_of_results']
    end
  end


end
