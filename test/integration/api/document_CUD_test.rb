require 'test_helper'
require 'integration/api_test_helper'

class DocumentCUDTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    admin_login
    @clz = 'document'
    @plural_clz = @clz.pluralize
    @project = @current_user.person.projects.first
    investigation = Factory(:investigation, projects: [@project], contributor: @current_person)
    study = Factory(:study, investigation: investigation, contributor: @current_person)
    @assay = Factory(:assay, study: study, contributor: @current_person)
    @creator = Factory(:person)

    template_file = File.join(ApiTestHelper.template_dir, 'post_max_document.json.erb')
    template = ERB.new(File.read(template_file))
    @to_post = JSON.parse(template.result(binding))

    document = Factory(:document, policy: Factory(:public_policy), contributor: @current_person, creators: [@creator])
    @to_patch = load_template("patch_min_#{@clz}.json.erb", {id: document.id})
  end

  test 'can add content to API-created document' do
    doc = Factory(:api_pdf_document, contributor: @current_person)

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
    doc = Factory(:api_pdf_document, policy: Factory(:public_download_and_no_custom_sharing)) # Created by someone who is not currently logged in

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
    doc = Factory(:document, contributor: @current_person)

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

    template_file = File.join(ApiTestHelper.template_dir, 'post_remote_document.json.erb')
    template = ERB.new(File.read(template_file))
    @to_post = JSON.parse(template.result(binding))
    validate_json_against_fragment @to_post.to_json, "#/definitions/#{@clz.camelize(:lower)}Post"

    assert_difference("#{@clz.classify}.count") do
      post "/#{@plural_clz}.json", params: @to_post
      assert_response :success
    end

    validate_json_against_fragment response.body, "#/definitions/#{@clz.camelize(:lower)}Response"

    h = JSON.parse(response.body)

    hash_comparison(@to_post['data']['attributes'], h['data']['attributes'])
    hash_comparison(populate_extra_attributes(@to_post), h['data']['attributes'])

    hash_comparison(@to_post['data']['relationships'], h['data']['relationships'])
    hash_comparison(populate_extra_relationships(@to_post), h['data']['relationships'])
  end


  test 'returns sensible error objects' do
    skip 'Errors are a WIP'
    template_file = File.join(ApiTestHelper.template_dir, 'post_bad_document.json.erb')
    template = ERB.new(File.read(template_file))
    @to_post = JSON.parse(template.result(binding))

    assert_no_difference("#{@clz.classify}.count") do
      post "/#{@plural_clz}.json", params: @to_post
      #assert_response :unprocessable_entity
    end

    h = JSON.parse(response.body)

    pp h
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
