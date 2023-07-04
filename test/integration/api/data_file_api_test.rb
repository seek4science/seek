require 'test_helper'

class DataFileApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def setup
    user_login
    FactoryBot.create(:data_types_controlled_vocab) unless SampleControlledVocab::SystemVocabs.data_types_controlled_vocab
    FactoryBot.create(:data_formats_controlled_vocab) unless SampleControlledVocab::SystemVocabs.data_formats_controlled_vocab
    @project = @current_user.person.projects.first
    investigation = FactoryBot.create(:investigation, projects: [@project], contributor: current_person)
    study = FactoryBot.create(:study, investigation: investigation, contributor: current_person)
    @assay = FactoryBot.create(:assay, study: study, contributor: current_person)
    @creator = FactoryBot.create(:person)
    @publication = FactoryBot.create(:publication, projects: [@project])
    @event = FactoryBot.create(:event, projects: [@project], policy: FactoryBot.create(:public_policy))
    @data_file = FactoryBot.create(:data_file, policy: FactoryBot.create(:public_policy), contributor: current_person, creators: [@creator])
    @workflow = FactoryBot.create(:workflow, projects: [@project], policy: FactoryBot.create(:public_policy))
  end

  test 'can add content to API-created data file' do
    df = FactoryBot.create(:api_pdf_data_file, contributor: current_person)

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
    df = FactoryBot.create(:api_txt_data_file, contributor: current_person)

    assert df.content_blob.no_content?
    assert df.can_download?(@current_user)
    assert df.can_edit?(@current_user)

    put data_file_content_blob_path(df, df.content_blob), params: { file: fixture_file_upload('txt_test.txt', 'text/plain') }, headers: { 'Accept' => 'application/json' }

    assert_response :success
    blob = df.content_blob.reload
    refute blob.no_content?
    assert_equal "This is a txt format\n", blob.read.to_s
  end

  test 'cannot add content to API-created data file without permission' do
    df = FactoryBot.create(:api_pdf_data_file, policy: FactoryBot.create(:public_download_and_no_custom_sharing)) # Created by someone who is not currently logged in

    assert df.content_blob.no_content?
    assert df.can_download?(@current_user)
    refute df.can_edit?(@current_user)

    put data_file_content_blob_path(df, df.content_blob), headers: { 'Accept' => 'application/json', 'RAW_POST_DATA' => File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'a_pdf_file.pdf')) }

    assert_response :forbidden
    validate_json response.body, '#/components/schemas/forbiddenResponse'
    blob = df.content_blob.reload
    assert_nil blob.md5sum
    assert blob.no_content?
  end

  test 'cannot add content to API-created data file that already has content' do
    df = FactoryBot.create(:data_file, contributor: current_person)

    refute df.content_blob.no_content?
    assert df.can_download?(@current_user)
    assert df.can_edit?(@current_user)

    original_md5 = df.content_blob.md5sum
    put data_file_content_blob_path(df, df.content_blob), headers: { 'Accept' => 'application/json', 'RAW_POST_DATA' => File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'another_pdf_file.pdf')) }

    assert_response :bad_request
    validate_json response.body, '#/components/schemas/badRequestResponse'
    blob = df.content_blob.reload
    assert_equal original_md5, blob.md5sum
    assert blob.file_size > 0
  end

  test 'can create data file with remote content' do
    stub_request(:get, 'http://mockedlocation.com/txt_test.txt').to_return(body: File.new("#{Rails.root}/test/fixtures/files/txt_test.txt"),
                                                                           status: 200, headers: { content_type: 'text/plain; charset=UTF-8' })
    stub_request(:head, 'http://mockedlocation.com/txt_test.txt').to_return(status: 200, headers: { content_type: 'text/plain; charset=UTF-8' })

    template = load_template('post_remote_data_file.json.erb')
    api_post_test(template)
  end

  test 'returns sensible error objects' do
    skip 'Errors are a WIP'
    to_post = load_template('post_bad_data_file.json.erb')

    assert_no_difference(-> { model.count }) do
      post "/#{plural_name}.json", params: to_post
      assert_response :unprocessable_entity
      validate_json response.body, '#/components/schemas/unprocessableEntityResponse'
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
    to_post = load_template('post_max_data_file.json.erb')
    to_post['data']['attributes']['policy']['access'] = 'edit'

    with_config_value(:max_all_visitors_access_type, Policy::VISIBLE) do
      assert_no_difference(-> { model.count }) do
        post "/#{plural_name}.json", params: to_post
        assert_response :unprocessable_entity
        validate_json response.body, '#/components/schemas/unprocessableEntityResponse'
      end
    end

    h = JSON.parse(response.body)
    errors = h["errors"]

    assert_equal [{ "source" => { "pointer" => "/data/attributes/policy" },
                    "detail" => "access_type is too permissive" }], errors
  end
end
