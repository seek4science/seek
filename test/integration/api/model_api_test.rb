require 'test_helper'

class ModelApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def setup
    user_login
    @project = @current_user.person.projects.first
    @organism = FactoryBot.create(:organism)
    @project.organisms << @organism
    investigation = FactoryBot.create(:investigation, projects: [@project], contributor: current_person)
    study = FactoryBot.create(:study, investigation: investigation, contributor: current_person)
    @assay = FactoryBot.create(:assay, study: study, contributor: current_person)
    @creator = FactoryBot.create(:person)
    @publication = FactoryBot.create(:publication, projects: [@project])
    @event = FactoryBot.create(:event, projects: [@project], policy: FactoryBot.create(:public_policy))
    ModelType.where(title: 'Linear equations').first_or_create
    ModelFormat.where(title: 'SBML').first_or_create
    RecommendedModelEnvironment.where(title: 'JWS Online').first_or_create
    @model = FactoryBot.create(:model, policy: FactoryBot.create(:public_policy),
                     contributor: current_person, creators: [@creator],
                     discussion_links: [FactoryBot.create(:discussion_link)])
    @discussion_link = @model.discussion_links.first
  end

  test 'can add content to API-created model' do
    model = FactoryBot.create(:api_model, contributor: current_person)

    assert model.content_blobs.all?(&:no_content?)
    assert model.can_download?(@current_user)
    assert model.can_edit?(@current_user)

    pdf_blob = model.content_blobs.first
    xml_blob = model.content_blobs.last

    original_md5 = pdf_blob.md5sum
    put model_content_blob_path(model, pdf_blob), headers: { 'Accept' => 'application/json', 'RAW_POST_DATA' => File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'a_pdf_file.pdf')) }

    assert_response :success
    blob = pdf_blob.reload
    refute_equal original_md5, pdf_blob.reload.md5sum
    refute pdf_blob.no_content?
    assert pdf_blob.file_size > 0

    original_md5 = xml_blob.md5sum
    put model_content_blob_path(model, xml_blob), headers: { 'Accept' => 'application/json', 'RAW_POST_DATA' => File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'BIOMD0000000064.xml')) }

    assert_response :success
    blob = xml_blob.reload
    refute_equal original_md5, xml_blob.reload.md5sum
    refute xml_blob.no_content?
    assert xml_blob.file_size > 0
  end

  test 'cannot add content to API-created model without permission' do
    model = FactoryBot.create(:api_model, policy: FactoryBot.create(:public_download_and_no_custom_sharing)) # Created by someone who is not currently logged in

    assert model.content_blobs.all?(&:no_content?)
    assert model.can_download?(@current_user)
    refute model.can_edit?(@current_user)

    pdf_blob = model.content_blobs.first

    original_md5 = pdf_blob.md5sum
    put model_content_blob_path(model, pdf_blob), headers: { 'Accept' => 'application/json', 'RAW_POST_DATA' => File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'a_pdf_file.pdf')) }

    assert_response :forbidden
    validate_json response.body, '#/components/schemas/forbiddenResponse'
    blob = pdf_blob.reload
    assert_nil blob.md5sum
    assert blob.no_content?
  end

  test 'cannot add content to API-created model that already has content' do
    model = FactoryBot.create(:model, contributor: current_person)

    pdf_blob = model.content_blobs.first

    refute pdf_blob.no_content?
    assert model.can_download?(@current_user)
    assert model.can_edit?(@current_user)

    original_md5 = pdf_blob.md5sum
    put model_content_blob_path(model, pdf_blob), headers: { 'Accept' => 'application/json', 'RAW_POST_DATA' => File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'a_pdf_file.pdf')) }

    assert_response :bad_request
    validate_json response.body, '#/components/schemas/badRequestResponse'
    blob = pdf_blob.reload
    assert_equal original_md5, blob.md5sum
    assert blob.file_size > 0
  end

  test 'can create model with remote content' do
    stub_request(:get, 'http://mockedlocation.com/txt_test.txt').to_return(body: File.new("#{Rails.root}/test/fixtures/files/txt_test.txt"),
                                                                           status: 200, headers: { content_type: 'text/plain; charset=UTF-8' })
    stub_request(:head, 'http://mockedlocation.com/txt_test.txt').to_return(status: 200, headers: { content_type: 'text/plain; charset=UTF-8' })
    stub_request(:get, 'http://mockedlocation.com/model.xml').to_return(body: File.new("#{Rails.root}/test/fixtures/files/BIOMD0000000064.xml"),
                                                                        status: 200, headers: { content_type: 'application/xml; charset=UTF-8' })
    stub_request(:head, 'http://mockedlocation.com/model.xml').to_return(status: 200, headers: { content_type: 'application/xml; charset=UTF-8' })

    template = load_template('post_remote_model.json.erb')
    api_post_test(template)
  end

  test 'returns sensible error objects' do
    skip 'Errors are a WIP'
    to_post = load_template('post_bad_model.json.erb')

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
end
