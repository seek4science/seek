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
      assert response.key?(:items), 'Response should contain :items key'
      assert response[:items].is_a?(Array), ':items should be an array'
      assert response[:items].any?, ':items array should not be empty'

      first_item = response[:items].first

      assert first_item.key?(:name), 'Each item should have a :name key'
      assert first_item.key?(:id), 'Each item should have an :id key'
      assert first_item.key?(:type), 'Each item should have a :type key'
      assert first_item.key?(:country), 'Each item should have a :country key'
      assert first_item.key?(:webpage), 'Each item should have a :webpage key'
    end
  end

  def test_fetch_by_id_with_vcr
    VCR.use_cassette('ror/fetch_by_id') do
      response = @client.fetch_by_id('03vek6s52')
      puts response.inspect

      assert_equal '03vek6s52', response[:id]
      assert_equal 'Harvard University', response[:name]
      assert_equal 'education', response[:type]
      assert_equal 'Universidad de Harvard', response[:altNames]
      assert_equal 'United States', response[:country]
      assert_equal 'US', response[:countrycode]
      assert_equal 'Cambridge', response[:city]
      assert_equal 'https://www.harvard.edu', response[:webpage]
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
      assert_empty response[:items]
    end
  end

  def test_fussy_search_with_vcr
    VCR.use_cassette('ror/fussy_search_harvard_by_name') do
      response = @client.query_name('Harv')
      assert_equal 20, response[:items].size
    end
  end
end
