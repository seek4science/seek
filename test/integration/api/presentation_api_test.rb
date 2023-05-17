require 'test_helper'

class PresentationApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def setup
    user_login
    @project = @current_user.person.projects.first
    @creator = FactoryBot.create(:person)
    @publication = FactoryBot.create(:publication, projects: [@project])
    @event = FactoryBot.create(:event, projects: [@project], policy: FactoryBot.create(:public_policy))
    @presentation = FactoryBot.create(:presentation, policy: FactoryBot.create(:public_policy), contributor: current_person, creators: [@creator])
    @workflow = FactoryBot.create(:workflow, projects: [@project], policy: FactoryBot.create(:public_policy))
  end

  test 'can add content to API-created presentation' do
    pres = FactoryBot.create(:api_pdf_presentation, contributor: current_person)

    assert pres.content_blob.no_content?
    assert pres.can_download?(@current_user)
    assert pres.can_edit?(@current_user)

    original_md5 = pres.content_blob.md5sum
    put presentation_content_blob_path(pres, pres.content_blob), headers: { 'Accept' => 'application/json', 'RAW_POST_DATA' => File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'a_pdf_file.pdf')) }

    assert_response :success
    blob = pres.content_blob.reload
    refute_equal original_md5, blob.reload.md5sum
    refute blob.no_content?
    assert blob.file_size > 0
  end

  test 'cannot add content to API-created presentation without permission' do
    pres = FactoryBot.create(:api_pdf_presentation, policy: FactoryBot.create(:public_download_and_no_custom_sharing)) # Created by someone who is not currently logged in

    assert pres.content_blob.no_content?
    assert pres.can_download?(@current_user)
    refute pres.can_edit?(@current_user)

    put presentation_content_blob_path(pres, pres.content_blob), headers: { 'Accept' => 'application/json', 'RAW_POST_DATA' => File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'a_pdf_file.pdf')) }

    assert_response :forbidden
    validate_json response.body, '#/components/schemas/forbiddenResponse'
    blob = pres.content_blob.reload
    assert_nil blob.md5sum
    assert blob.no_content?
  end

  test 'cannot add content to API-created presentation that already has content' do
    pres = FactoryBot.create(:presentation, contributor: current_person)

    refute pres.content_blob.no_content?
    assert pres.can_download?(@current_user)
    assert pres.can_edit?(@current_user)

    original_md5 = pres.content_blob.md5sum
    put presentation_content_blob_path(pres, pres.content_blob), headers: { 'Accept' => 'application/json', 'RAW_POST_DATA' => File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'another_pdf_file.pdf')) }

    assert_response :bad_request
    validate_json response.body, '#/components/schemas/badRequestResponse'
    blob = pres.content_blob.reload
    assert_equal original_md5, blob.md5sum
    assert blob.file_size > 0
  end

  test 'can create presentation with remote content' do
    stub_request(:get, 'http://mockedlocation.com/txt_test.txt').to_return(body: File.new("#{Rails.root}/test/fixtures/files/txt_test.txt"),
                                                                           status: 200, headers: { content_type: 'text/plain; charset=UTF-8' })
    stub_request(:head, 'http://mockedlocation.com/txt_test.txt').to_return(status: 200, headers: { content_type: 'text/plain; charset=UTF-8' })

    template = load_template('post_remote_presentation.json.erb')
    api_post_test(template)
  end

  test 'returns sensible error objects' do
    skip 'Errors are a WIP'
    to_post = load_template('post_bad_presentation.json.erb')

    assert_no_difference(-> { model.count }) do
      post "/#{plural_name}.json", params: to_post
      # assert_response :unprocessable_entity
      # validate_json response.body, '#/components/schemas/errors'
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
