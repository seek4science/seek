require 'test_helper'

class FileTemplateApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def setup
    user_login
    @project = @current_user.person.projects.first
    @creator = FactoryBot.create(:person)
    FactoryBot.create(:data_types_controlled_vocab)
    FactoryBot.create(:data_formats_controlled_vocab)
    @file_template = FactoryBot.create(:file_template, policy: FactoryBot.create(:public_policy), contributor: current_person, creators: [@creator])
  end

  test 'can add content to API-created file template' do
    ft = FactoryBot.create(:api_pdf_file_template, contributor: current_person)

    assert ft.content_blob.no_content?
    assert ft.can_download?(@current_user)
    assert ft.can_edit?(@current_user)

    original_md5 = ft.content_blob.md5sum
    put file_template_content_blob_path(ft, ft.content_blob), headers: { 'Accept' => 'application/json', 'RAW_POST_DATA' => File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'a_pdf_file.pdf')) }

    assert_response :success
    blob = ft.content_blob.reload
    refute_equal original_md5, blob.reload.md5sum
    refute blob.no_content?
    assert blob.file_size > 0
  end

  test 'cannot add content to API-created file template without permission' do
    ft = FactoryBot.create(:api_pdf_file_template, policy: FactoryBot.create(:public_download_and_no_custom_sharing)) # Created by someone who is not currently logged in

    assert ft.content_blob.no_content?
    assert ft.can_download?(@current_user)
    refute ft.can_edit?(@current_user)

    put file_template_content_blob_path(ft, ft.content_blob), headers: { 'Accept' => 'application/json', 'RAW_POST_DATA' => File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'a_pdf_file.pdf')) }

    assert_response :forbidden
    blob = ft.content_blob.reload
    assert_nil blob.md5sum
    assert blob.no_content?
  end

  test 'cannot add content to API-created file template that already has content' do
    ft = FactoryBot.create(:file_template, contributor: current_person)

    refute ft.content_blob.no_content?
    assert ft.can_download?(@current_user)
    assert ft.can_edit?(@current_user)

    original_md5 = ft.content_blob.md5sum
    put file_template_content_blob_path(ft, ft.content_blob), headers: { 'Accept' => 'application/json', 'RAW_POST_DATA' => File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'another_pdf_file.pdf')) }

    assert_response :bad_request
    blob = ft.content_blob.reload
    assert_equal original_md5, blob.md5sum
    assert blob.file_size > 0
  end

  test 'can create file_template with remote content' do
    stub_request(:get, 'http://mockedlocation.com/txt_test.txt').to_return(body: File.new("#{Rails.root}/test/fixtures/files/txt_test.txt"),
                                                                           status: 200, headers: { content_type: 'text/plain; charset=UTF-8' })
    stub_request(:head, 'http://mockedlocation.com/txt_test.txt').to_return(status: 200, headers: { content_type: 'text/plain; charset=UTF-8' })
    template = load_template('post_remote_file_template.json.erb')
    api_post_test(template)
  end

  test 'returns sensible error objects' do
    skip 'Errors are a WIP'
    to_post = load_template('post_bad_file_template.json.erb')

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
