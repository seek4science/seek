require 'test_helper'

class ContentBlobsControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:quentin)
  end

  test "should find_and_auth_asset for get_pdf" do
    sop1 = Factory(:pdf_sop, :policy => Factory(:all_sysmo_downloadable_policy))

    get :get_pdf, :sop_id => sop1.id, :id => sop1.content_blob.id
    assert_response :success

    sop2 = Factory(:pdf_sop, :policy => Factory(:private_policy))
    get :get_pdf, :sop_id => sop2.id, :id => sop2.content_blob.id
    assert_redirected_to sop2
    assert_not_nil flash[:error]
  end

  test "should find_and_auth_asset for download" do
    sop1 = Factory(:pdf_sop, :policy => Factory(:all_sysmo_downloadable_policy))

    get :download, :sop_id => sop1.id, :id => sop1.content_blob.id
    assert_response :success

    sop2 = Factory(:pdf_sop, :policy => Factory(:private_policy))
    get :download, :sop_id => sop2.id, :id => sop2.content_blob.id
    assert_redirected_to sop2
    assert_not_nil flash[:error]
  end

  test "should find_and_auth_content_blob for get_pdf" do
    sop1 = Factory(:pdf_sop, :policy => Factory(:all_sysmo_downloadable_policy))
    sop2 = Factory(:pdf_sop, :policy => Factory(:private_policy))

    get :get_pdf, :sop_id => sop1.id, :id => sop1.content_blob.id
    assert_response :success

    get :get_pdf, :sop_id => sop1.id, :id => sop2.content_blob.id
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test "should find_and_auth_content_blob for download" do
    sop1 = Factory(:pdf_sop, :policy => Factory(:all_sysmo_downloadable_policy))
    sop2 = Factory(:pdf_sop, :policy => Factory(:private_policy))

    get :download, :id => sop1.id, :content_blob_id => sop1.content_blob.id
    assert_response :success

    get :download, :id => sop1.id, :content_blob_id => sop2.content_blob.id
    assert_redirected_to :root
    assert_not_nil flash[:error]
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
