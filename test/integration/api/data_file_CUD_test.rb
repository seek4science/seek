require 'test_helper'
require 'integration/api_test_helper'

class DataFileCUDTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    admin_login
    @clz = 'data_file'
    @plural_clz = @clz.pluralize
    @project = @current_user.person.projects.first
    investigation = Factory(:investigation, projects: [@project], contributor: @current_person)
    study = Factory(:study, investigation: investigation, contributor: @current_person)
    @assay = Factory(:assay, study: study, contributor: @current_person)
    @creator = Factory(:person)
    @publication = Factory(:publication, projects: [@project])
    @event = Factory(:event, projects: [@project], policy: Factory(:public_policy))

    template_file = File.join(ApiTestHelper.template_dir, 'post_max_data_file.json.erb')
    template = ERB.new(File.read(template_file))
    @to_post = JSON.parse(template.result(binding))

    data_file = Factory(:data_file, policy: Factory(:public_policy), contributor: @current_person, creators: [@creator])
    @to_patch = load_template("patch_min_#{@clz}.json.erb", {id: data_file.id})
  end

  test 'can add content to API-created data file' do
    df = Factory(:api_pdf_data_file, contributor: @current_person)

    assert df.content_blob.no_content?
    assert df.can_download?(@current_user)
    assert df.can_edit?(@current_user)

    original_md5 = df.content_blob.md5sum
    put data_file_content_blob_path(df, df.content_blob), headers: { 'Accept' => 'application/json', 'RAW_POST_DATA' => File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'a_pdf_file.pdf')) }

    assert_response :success
    blob = df.content_blob.reload
    refute_equal original_md5, blob.reload.md5sum
    refute blob.no_content?
    assert blob.file_size > 0
  end

  test 'can add content to API-created data file using a multipart/form request' do
    df = Factory(:api_txt_data_file, contributor: @current_person)

    assert df.content_blob.no_content?
    assert df.can_download?(@current_user)
    assert df.can_edit?(@current_user)

    put data_file_content_blob_path(df, df.content_blob), params: { file: fixture_file_upload('files/txt_test.txt', 'text/plain') }, headers: { 'Accept' => 'application/json' }

    assert_response :success
    blob = df.content_blob.reload
    refute blob.no_content?
    assert_equal "This is a txt format\n", blob.read.to_s
  end

  test 'cannot add content to API-created data file without permission' do
    df = Factory(:api_pdf_data_file, policy: Factory(:public_download_and_no_custom_sharing)) # Created by someone who is not currently logged in

    assert df.content_blob.no_content?
    assert df.can_download?(@current_user)
    refute df.can_edit?(@current_user)

    put data_file_content_blob_path(df, df.content_blob), headers: { 'Accept' => 'application/json', 'RAW_POST_DATA' => File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'a_pdf_file.pdf')) }

    assert_response :forbidden
    validate_json_against_fragment response.body, '#/definitions/errors'
    blob = df.content_blob.reload
    assert_nil blob.md5sum
    assert blob.no_content?
  end

  test 'cannot add content to API-created data file that already has content' do
    df = Factory(:data_file, contributor: @current_person)

    refute df.content_blob.no_content?
    assert df.can_download?(@current_user)
    assert df.can_edit?(@current_user)

    original_md5 = df.content_blob.md5sum
    put data_file_content_blob_path(df, df.content_blob), headers: { 'Accept' => 'application/json', 'RAW_POST_DATA' => File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'another_pdf_file.pdf')) }

    assert_response :bad_request
    validate_json_against_fragment response.body, '#/definitions/errors'
    blob = df.content_blob.reload
    assert_equal original_md5, blob.md5sum
    assert blob.file_size > 0
  end

  test 'can create data file with remote content' do
    stub_request(:get, 'http://mockedlocation.com/txt_test.txt').to_return(body: File.new("#{Rails.root}/test/fixtures/files/txt_test.txt"),
                                                                           status: 200, headers: { content_type: 'text/plain; charset=UTF-8' })
    stub_request(:head, 'http://mockedlocation.com/txt_test.txt').to_return(status: 200, headers: { content_type: 'text/plain; charset=UTF-8' })

    template_file = File.join(ApiTestHelper.template_dir, 'post_remote_data_file.json.erb')
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
    template_file = File.join(ApiTestHelper.template_dir, 'post_bad_data_file.json.erb')
    template = ERB.new(File.read(template_file))
    @to_post = JSON.parse(template.result(binding))

    assert_no_difference("#{@clz.classify}.count") do
      post "/#{@plural_clz}.json", params: @to_post
      assert_response :unprocessable_entity
      validate_json_against_fragment response.body, '#/definitions/errors'
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

  test 'cannot add overly permissive policy to data file' do
    template_file = File.join(ApiTestHelper.template_dir, 'post_max_data_file.json.erb')
    template = ERB.new(File.read(template_file))
    to_post = JSON.parse(template.result(binding))
    to_post['data']['attributes']['policy']['access'] = 'edit'

    with_config_value(:max_all_visitors_access_type, Policy::VISIBLE) do
      assert_no_difference("#{@clz.classify}.count") do
        post "/#{@plural_clz}.json", params: to_post
        assert_response :unprocessable_entity

        validate_json_against_fragment response.body, '#/definitions/errors'
      end
    end

    h = JSON.parse(response.body)
    errors = h["errors"]

    assert_equal [{"source"=>{"pointer"=>"/data/attributes/policy"},
                   "detail"=>"access_type is too permissive"}],errors
  end
end
