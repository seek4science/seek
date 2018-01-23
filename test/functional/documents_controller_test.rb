require 'test_helper'
require 'minitest/mock'

class DocumentsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  # include RestTestCases # TODO: Enable me
  include SharingFormTestHelper
  include RdfTestCases
  include MockHelper
  include HtmlHelper

  def rest_api_test_object
    @object = Factory(:public_document)
  end

  test 'should get index' do
    FactoryGirl.create_list(:public_document, 3)

    get :index

    assert_response :success
    assert assigns(:documents).any?
  end

  test "shouldn't show hidden items in index" do
    visible_doc = Factory(:public_document)
    hidden_doc = Factory(:private_document)

    get :index, page: 'all'

    assert_response :success
    assert_includes assigns(:documents), visible_doc
    assert_not_includes assigns(:documents), hidden_doc
  end

  test 'should show' do
    visible_doc = Factory(:public_document)

    get :show, id: visible_doc

    assert_response :success
  end

  test 'should not show hidden document' do
    hidden_doc = Factory(:private_document)

    get :show, id: hidden_doc

    assert_response :forbidden
  end

  test 'should get new' do
    login_as(Factory(:person))

    get :new
    assert_response :success
    assert_select 'h1', text: "New #{I18n.t('document')}"
  end

  test 'should get edit' do
    login_as(Factory(:person))

    get :new
    assert_response :success
    assert_select 'h1', text: "New #{I18n.t('document')}"
  end

  test 'should create document' do
    person = Factory(:person)
    login_as(person)

    assert_difference('ActivityLog.count') do
      assert_difference('Document.count') do
        assert_difference('Document::Version.count') do
          assert_difference('ContentBlob.count') do
            post :create, document: { title: 'Document', project_ids: [person.projects.first.id]},
                 content_blobs: [valid_content_blob], policy_attributes: valid_sharing
          end
        end
      end
    end

    assert_redirected_to document_path(assigns(:document))
  end

  test 'should update document' do
    person = Factory(:person)
    document = Factory(:document, contributor: person)
    assay = Factory(:assay, contributor: person)
    login_as(person)

    assert document.assays.empty?

    assert_difference('ActivityLog.count') do
      put :update, id: document.id, document: { title: 'Different title', project_ids: [person.projects.first.id]},
          assay_ids: [assay.id]
    end

    assert_redirected_to document_path(assigns(:document))
    assert_equal 'Different title', assigns(:document).title
    assert_includes assigns(:document).assays, assay
  end

  test 'should destroy document' do
    person = Factory(:person)
    document = Factory(:document, contributor: person)
    login_as(person)

    assert_difference('Document.count', -1) do
      assert_no_difference('ContentBlob.count') do
        delete :destroy, id: document
      end
    end

    assert_redirected_to documents_path
  end

  private

  def valid_document
    { title: 'Test', project_ids: [projects(:sysmo_project).id] }
  end

  def valid_content_blob
    { data: file_for_upload, data_url: '' }
  end

  def file_for_upload
    ActionDispatch::Http::UploadedFile.new(filename: 'doc.pdf',
                                           content_type: 'application/pdf',
                                           tempfile: fixture_file_upload('files/a_pdf_file.pdf'))
  end

end
