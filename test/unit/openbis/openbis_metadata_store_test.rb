require 'test_helper'
require 'openbis_test_helper'

class OpenbisMetadataStoreTest < ActiveSupport::TestCase
  def setup
    @openbis_endpoint = FactoryBot.create(:openbis_endpoint)
    @store = @openbis_endpoint.metadata_store
  end

  test 'endpoint key' do
    key = @store.send(:endpoint_key)
    # changed as the same cache should be used between updates
    # assert_equal "#{@openbis_endpoint.id}/#{@openbis_endpoint.updated_at.utc}",key
    assert_equal "#{@openbis_endpoint.id}/cache", key

    # needs to handle new_record? case
    ep = OpenbisEndpoint.new(
      as_endpoint: 'https://openbis-api.fair-dom.org/openbis/openbis',
      dss_endpoint: 'https://openbis-api.fair-dom.org/datastore_server',
      web_endpoint: 'https://openbis-api.fair-dom.org/openbis',
      username: 'wibble',
      password: 'wobble'
    )
    key = ep.metadata_store.send(:endpoint_key)
    assert_equal 'new/919e25e0023c0973c8025bd5c7aa3852ba3f8e94c2b5af29fed7bd073890cd62', key
  end

  test 'filestore_path' do
    path = @store.send(:filestore_path)
    key = @store.send(:endpoint_key) # this value already tested
    assert_equal File.join(Rails.root, 'tmp/testing-filestore/openbis-metadata', key), path
  end

  test 'caching' do
    refute @store.exist?('fish')
    assert_equal 'cat', @store.fetch('fish') { 'cat' }
    assert @store.exist?('fish')
  end

  test 'clear' do
    # works on new as well
    @store.clear

    assert_equal 'cat', @store.fetch('fish') { 'cat' }
    assert_equal 'rabbit', @store.fetch('dog') { 'rabbit' }
    assert @store.exist?('fish')
    assert @store.exist?('dog')
    @store.clear
    refute @store.exist?('fish')
    refute @store.exist?('dog')
  end

  test 'cleanup cleans only expired' do
    # making fresh so it wont have content
    openbis_endpoint = FactoryBot.create(:openbis_endpoint)
    assert 122 > openbis_endpoint.refresh_period_mins
    store = openbis_endpoint.metadata_store

    # works on new as well
    store.cleanup

    assert_equal 'v1', store.fetch('k1') { 'v1' }
    assert store.exist?('k1')

    store.cleanup
    assert store.exist?('k1')

    # sleep(65.seconds)
    travel 122.minutes do
      assert_equal 'v2', store.fetch('k2') { 'v2' }
      store.cleanup
      refute store.exist?('k1')
      assert store.exist?('k2')
    end
  end

  test 'automaticaly expires entries' do
    # making fresh so it wont have content
    openbis_endpoint = FactoryBot.create(:openbis_endpoint)
    assert 122 > openbis_endpoint.refresh_period_mins
    store = openbis_endpoint.metadata_store

    assert_equal 'v1', store.fetch('k1') { 'v1' }

    assert_equal 'v1', store.fetch('k1') { 'v2' }

    travel 122.minutes do
      assert_equal 'v3', store.fetch('k2') { 'v3' }
      assert_equal 'v2a', store.fetch('k1') { 'v2a' }
      assert_equal 'v3', store.fetch('k2') { 'v4' }
    end
  end
end
