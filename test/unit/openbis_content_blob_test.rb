require 'test_helper'

# ContentBlob related tests specific to OpenBIS
class OpenbisContentBlobTest < ActiveSupport::TestCase

  test 'openbis?' do
    stub_request(:head, 'http://www.abc.com').to_return(
        :headers => {:content_length => 500, :content_type => 'text/plain'}, :status => 200)

    refute Factory(:txt_content_blob).openbis?
    refute Factory(:binary_content_blob).openbis?
    refute Factory(:url_content_blob,make_local_copy:false).openbis?
    assert Factory(:url_content_blob,make_local_copy:false,url:'openbis:1:dataset:2222').openbis?
  end

  test 'openbis dataset' do
    blob = openbis_linked_content_blob
    dataset = blob.openbis_dataset
    refute_nil dataset
    assert_equal '20160210130454955-23',dataset.perm_id
    assert_equal 549820,dataset.size
    assert_equal 3,dataset.dataset_files.count
  end

  test 'search terms' do
    blob = openbis_linked_content_blob
    assert_empty blob.url_search_terms,'url search terms should be empty'
    terms = blob.search_terms

    assert_includes terms,'TEST_DATASET_TYPE'
    assert_includes terms,'original/autumn.jpg'
    assert_includes terms,'20151216143716562-2'
    assert_includes terms,'for api test'

  end

  private

  def openbis_linked_content_blob
    endpoint = OpenbisEndpoint.new(project:Factory(:project),
                                  dss_endpoint:'https://openbis-api.fair-dom.org/datastore_server',
                                  as_endpoint:'https://openbis-api.fair-dom.org/openbis/openbis',
                                  username:'apiuser',password:'apiuser',space_perm_id:'API-SPACE')
    disable_authorization_checks{endpoint.save!}
    refute_nil endpoint.space

    Factory(:url_content_blob,make_local_copy:false,url:"openbis:#{endpoint.id}:dataset:20160210130454955-23")

  end

end