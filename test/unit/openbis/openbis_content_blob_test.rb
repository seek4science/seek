require 'test_helper'
require 'openbis_test_helper'

# ContentBlob related tests specific to OpenBIS
class OpenbisContentBlobTest < ActiveSupport::TestCase
  def setup
    mock_openbis_calls
  end

  test 'openbis?' do
    stub_request(:head, 'http://www.abc.com').to_return(
      headers: { content_length: 500, content_type: 'text/plain' }, status: 200)

    refute Factory(:txt_content_blob).openbis?
    refute Factory(:binary_content_blob).openbis?
    refute Factory(:url_content_blob, make_local_copy: false).openbis?
    assert Factory(:url_content_blob, make_local_copy: false, url: 'openbis:1:dataset:2222').openbis?
  end

  test 'openbis? handles bad url' do
    blob = Factory(:url_content_blob,url:'http://url with spaces/another space.doc')
    refute blob.openbis?
  end

  test 'openbis dataset' do
    blob = openbis_linked_content_blob
    dataset = blob.openbis_dataset
    refute_nil dataset
    assert_equal '20160210130454955-23', dataset.perm_id
    assert_equal 549_820, dataset.size
    assert_equal 3, dataset.dataset_files.count
  end

  test 'search terms' do
    blob = openbis_linked_content_blob
    assert_empty blob.url_search_terms, 'url search terms should be empty'
    terms = blob.search_terms

    assert_includes terms, 'TEST_DATASET_TYPE'
    assert_includes terms, 'original/autumn.jpg'
    assert_includes terms, '20151216143716562-2'
    assert_includes terms, 'for api test'
    assert_includes terms, 'autumn.jpg'
    assert_includes terms, 'apiuser'
  end

end
