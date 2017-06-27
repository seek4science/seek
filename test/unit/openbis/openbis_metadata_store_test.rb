require 'test_helper'
require 'openbis_test_helper'

class OpenbisMetadataStoreTest < ActiveSupport::TestCase

  def setup
    @openbis_endpoint = Factory(:openbis_endpoint)
    @store = @openbis_endpoint.metadata_store
  end

  test 'endpoint key' do
    key = @store.send(:endpoint_key)
    assert_equal "#{@openbis_endpoint.id}/#{@openbis_endpoint.updated_at.utc}",key

    # needs to handle new_record? case
    ep = OpenbisEndpoint.new(
        as_endpoint: 'https://openbis-api.fair-dom.org/openbis/openbis',
        dss_endpoint: 'https://openbis-api.fair-dom.org/datastore_server',
        web_endpoint: 'https://openbis-api.fair-dom.org/openbis',
        username: 'wibble',
        password: 'wobble')
    key = ep.metadata_store.send(:endpoint_key)
    assert_equal 'new/919e25e0023c0973c8025bd5c7aa3852ba3f8e94c2b5af29fed7bd073890cd62',key
  end

  test 'filestore_path' do
    path = @store.send(:filestore_path)
    key = @store.send(:endpoint_key) #this value already tested
    assert_equal File.join(Rails.root,'tmp/testing-filestore/openbis-metadata',key),path
  end

  test 'caching' do
    refute @store.exist?('fish')
    assert_equal 'cat', @store.fetch('fish'){'cat'}
    assert @store.exist?('fish')
  end

  test 'clear' do
    assert_equal 'cat', @store.fetch('fish'){'cat'}
    assert_equal 'rabbit', @store.fetch('dog'){'rabbit'}
    assert @store.exist?('fish')
    assert @store.exist?('dog')
    @store.clear
    refute @store.exist?('fish')
    refute @store.exist?('dog')
  end

end