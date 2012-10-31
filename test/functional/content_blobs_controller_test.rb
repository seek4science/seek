require 'test_helper'

class ContentBlobsControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:quentin)
  end

  test 'get_pdf' do
    ms_word_sop = Factory(:doc_sop, :policy => Factory(:all_sysmo_downloadable_policy))
    pdf_path = ms_word_sop.content_blob.filepath('pdf')
    FileUtils.rm pdf_path if File.exists?(pdf_path)
    assert !File.exists?(pdf_path)
    assert ms_word_sop.can_download?

    get :get_pdf, {:sop_id => ms_word_sop.id, :id => ms_word_sop.content_blob.id}
    assert_response :success
    assert File.exists?(ms_word_sop.content_blob.filepath)
    assert File.exists?(pdf_path)
  end

  test 'get_pdf from url' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/a_pdf_file.pdf","http://somewhere.com/piccy.pdf"
    pdf_sop = Factory(:sop,
                      :policy => Factory(:all_sysmo_downloadable_policy),
                      :content_blob => Factory(:pdf_content_blob, :data => nil, :url => "http://somewhere.com/piccy.pdf"))

    get :get_pdf, {:sop_id => pdf_sop.id, :id => pdf_sop.content_blob.id}

    assert_response :success
    #the file is fetched on fly, instead of saving locally
    assert !File.exists?(pdf_sop.content_blob.filepath)
    assert !File.exists?(pdf_sop.content_blob.filepath('pdf'))
  end

  test 'get_pdf of a doc file from url' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/ms_word_test.doc","http://somewhere.com/piccy.doc"
    doc_sop = Factory(:sop,
                      :policy => Factory(:all_sysmo_downloadable_policy),
                      :content_blob => Factory(:doc_content_blob, :data => nil, :url => "http://somewhere.com/piccy.doc"))

    get :get_pdf, {:sop_id => doc_sop.id, :id => doc_sop.content_blob.id}
    assert_response :success
    #the file is fetched on fly, instead of saving locally
    assert !File.exists?(doc_sop.content_blob.filepath)
    assert !File.exists?(doc_sop.content_blob.filepath('pdf'))
  end
end
