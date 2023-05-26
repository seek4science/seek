require 'test_helper'

class DocumentApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def setup
    user_login
    @project = @current_user.person.projects.first
    investigation = FactoryBot.create(:investigation, projects: [@project], contributor: current_person)
    study = FactoryBot.create(:study, investigation: investigation, contributor: current_person)
    @assay = FactoryBot.create(:assay, study: study, contributor: current_person)
    @workflow = FactoryBot.create(:workflow, projects: [@project], contributor: current_person)
    @creator = FactoryBot.create(:person)
    @document = FactoryBot.create(:document, policy: FactoryBot.create(:public_policy), contributor: current_person, creators: [@creator])
  end

  test 'can add content to API-created document' do
    doc = FactoryBot.create(:api_pdf_document, contributor: current_person)

    assert doc.content_blob.no_content?
    assert doc.can_download?(@current_user)
    assert doc.can_edit?(@current_user)

    original_md5 = doc.content_blob.md5sum
    put document_content_blob_path(doc, doc.content_blob), headers: { 'Accept' => 'application/json', 'RAW_POST_DATA' => File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'a_pdf_file.pdf')) }

    assert_response :success
    blob = doc.content_blob.reload
    refute_equal original_md5, blob.reload.md5sum
    refute blob.no_content?
    assert blob.file_size > 0
  end

  test 'cannot add content to API-created document without permission' do
    doc = FactoryBot.create(:api_pdf_document, policy: FactoryBot.create(:public_download_and_no_custom_sharing)) # Created by someone who is not currently logged in

    assert doc.content_blob.no_content?
    assert doc.can_download?(@current_user)
    refute doc.can_edit?(@current_user)

    put document_content_blob_path(doc, doc.content_blob), headers: { 'Accept' => 'application/json', 'RAW_POST_DATA' => File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'a_pdf_file.pdf')) }

    assert_response :forbidden
    blob = doc.content_blob.reload
    assert_nil blob.md5sum
    assert blob.no_content?
  end

  test 'cannot add content to API-created document that already has content' do
    doc = FactoryBot.create(:document, contributor: current_person)

    refute doc.content_blob.no_content?
    assert doc.can_download?(@current_user)
    assert doc.can_edit?(@current_user)

    original_md5 = doc.content_blob.md5sum
    put document_content_blob_path(doc, doc.content_blob), headers: { 'Accept' => 'application/json', 'RAW_POST_DATA' => File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'another_pdf_file.pdf')) }

    assert_response :bad_request
    blob = doc.content_blob.reload
    assert_equal original_md5, blob.md5sum
    assert blob.file_size > 0
  end

  test 'can create document with remote content' do
    stub_request(:get, 'http://mockedlocation.com/txt_test.txt').to_return(body: File.new("#{Rails.root}/test/fixtures/files/txt_test.txt"),
                                                                           status: 200, headers: { content_type: 'text/plain; charset=UTF-8' })
    stub_request(:head, 'http://mockedlocation.com/txt_test.txt').to_return(status: 200, headers: { content_type: 'text/plain; charset=UTF-8' })

    template = load_template('post_remote_document.json.erb')
    api_post_test(template)
  end

  test 'returns sensible error objects' do
    skip 'Errors are a WIP'
    to_post = load_template('post_bad_document.json.erb')

    assert_no_difference(-> { model.count }) do
      post "/#{plural_name}.json", params: to_post
      #assert_response :unprocessable_entity
    end

    h = JSON.parse(response.body)

    errors = h["errors"]

    assert errors.any?
    assert_equal "can't be blank", fetch_errors(errors, '/data/relationships/projects')[0]['detail']
    assert_equal "can't be blank", fetch_errors(errors, '/data/attributes/title')[0]['detail']
    policy_errors = fetch_errors(errors, '/data/attributes/policy').map { |p| p['detail'] }
    assert_includes policy_errors, "permissions contributor can't be blank"
    assert_includes policy_errors, "permissions access_type can't be blank"
    refute fetch_errors(errors, '/data/attributes/description').any?
    refute fetch_errors(errors, '/data/attributes/potato').any?
  end
end
