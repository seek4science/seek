require 'test_helper'

class  SpreadsheetDownloadTest < ActionController::TestCase
  include AuthenticatedTestHelper
  include SinglePageTestUtils

  tests SinglePagesController

  def setup
    @member = FactoryBot.create :user
    login_as @member
    @initial_isa_json_compliance_enabled = Seek::Config.isa_json_compliance_enabled
    Seek::Config.isa_json_compliance_enabled = true
  end

  def teardown
    Seek::Config.isa_json_compliance_enabled = @initial_isa_json_compliance_enabled
  end

  test 'Should not generate spreadheet export if not authorized' do
    id_label, _person, project, study, source_sample_type, sources = setup_test_data.values_at(
      :id_label, :person, :project, :study, :source_sample_type, :sources
    )
    unauthorized_person = FactoryBot.create(:person)
    source_ids = sources.map(&:id)
    sample_type_id = source_sample_type.id
    study_id = study.id
    assay_id = nil
    project_id = project.id

    login_as(unauthorized_person)

    download_params = { sample_ids: source_ids.to_json,
                        sample_type_id: sample_type_id.to_json,
                        study_id: study_id.to_json,
                        assay_id: assay_id.to_json,
                        project_id: project_id.to_json}

    post :export_to_spreadsheet, params: download_params, format: :json
    assert_response :ok, msg = "Couldn't reach the server"

    response_body = JSON.parse(response.body)
    assert response_body.key?('uuid'), msg = "Response body is expected to have a 'uuid' key"
    cache_uuid = response_body['uuid']

    get :download_spreadsheet, params: { uuid: cache_uuid }, format: :xlsx
    assert_redirected_to single_page_path(id: project_id, item_type: 'study', item_id: study_id)
    assert_equal flash[:error], 'Could not retrieve Study Sample Type! Do you have at least viewing permissions?'
  end

  test 'generates a valid export of study sources in single page' do
    # Generate the excel data
    id_label, person, project, study, source_sample_type, sources = setup_test_data.values_at(
      :id_label, :person, :project, :study, :source_sample_type, :sources
    )

    source_ids = sources.map(&:id)
    sample_type_id = source_sample_type.id
    study_id = study.id
    assay_id = nil
    project_id = project.id

    login_as(person)

    download_params = { sample_ids: source_ids.to_json,
                        sample_type_id: sample_type_id.to_json,
                        study_id: study_id.to_json,
                        assay_id: assay_id.to_json,
                        project_id: project_id.to_json}

    post :export_to_spreadsheet, params: download_params, format: :json
    assert_response :ok, msg = "Couldn't reach the server"

    response_body = JSON.parse(response.body)
    assert response_body.key?('uuid'), msg = "Response body is expected to have a 'uuid' key"
    cache_uuid = response_body['uuid']

    get :download_spreadsheet, params: { uuid: cache_uuid }, format: :xlsx
    response_cd = response.headers["Content-Disposition"]
    assert_response :ok
    assert response_cd.include?("filename=\"#{study.id} - #{study.title} sources table.xlsx\"")
  end

  test 'generates a valid export of assay samples in single page' do
    id_label, person, project, study, assay, assay_sample_type, assay_samples = setup_test_data.values_at(
      :id_label, :person, :project, :study, :assay, :assay_sample_type, :assay_samples
    )

    assay_sample_ids = assay_samples.map(&:id)
    sample_type_id = assay_sample_type.id
    study_id = study.id
    assay_id = assay.id
    project_id = project.id

    login_as(person)

    download_params = { sample_ids: assay_sample_ids.to_json,
                        sample_type_id: sample_type_id.to_json,
                        study_id: study_id.to_json,
                        assay_id: assay_id.to_json,
                        project_id: project_id.to_json}

    post :export_to_spreadsheet, params: download_params, format: :json
    assert_response :ok, msg = "Couldn't reach the server"

    response_body = JSON.parse(response.body)
    assert response_body.key?('uuid'), msg = "Response body is expected to have a 'uuid' key"
    cache_uuid = response_body['uuid']

    get :download_spreadsheet, params: { uuid: cache_uuid }, format: :xlsx
    response_cd = response.headers["Content-Disposition"]
    assert_response :ok
    assert response_cd.include?("filename=\"#{assay.id} - #{assay.title} table.xlsx\"")
  end

  test 'Should sanitize spreadsheet name' do
    # Generate the excel data
    id_label, person, project, study, source_sample_type, sources = setup_test_data.values_at(
      :id_label, :person, :project, :study, :source_sample_type, :sources
    )

    study.update_column(:title, '<script>alert("Script tags should be removed!")</script> My sample type')

    source_ids = sources.map(&:id)
    sample_type_id = source_sample_type.id
    study_id = study.id
    assay_id = nil
    project_id = project.id

    login_as(person)

    download_params = { sample_ids: source_ids.to_json,
                        sample_type_id: sample_type_id.to_json,
                        study_id: study_id.to_json,
                        assay_id: assay_id.to_json,
                        project_id: project_id.to_json}

    post :export_to_spreadsheet, params: download_params, format: :json
    assert_response :ok, msg = "Couldn't reach the server"

    response_body = JSON.parse(response.body)
    assert response_body.key?('uuid'), msg = "Response body is expected to have a 'uuid' key"
    cache_uuid = response_body['uuid']

    get :download_spreadsheet, params: { uuid: cache_uuid }, format: :xlsx
    response_cd = response.headers["Content-Disposition"]
    assert_response :ok
    expected_file_name = "My sample type sources table.xlsx"
    assert response_cd.include?(expected_file_name)
    assert %w[<script> </script>].none? { |tag| response_cd.include?(tag) }
  end

  test 'download_spreadsheet fails when sample belongs to different project' do
    data = setup_test_data
    person = data[:person]
    project2 = FactoryBot.create(:project)
    institution = FactoryBot.create(:institution)
    person.add_to_project_and_institution(project2, institution)

    # Create sample that belongs to project2, not project1
    sample = FactoryBot.create(:sample,
                              sample_type: data[:source_sample_type],
                              project_ids: [project2.id],
                              contributor: person,
                              data: {
                                'Source Name': 'Test Source',
                                'Source Characteristic 1': 'Value 1',
                                'Source Characteristic 2': data[:source_sample_type].sample_attributes
                                  .find_by_title('Source Characteristic 2')
                                  .sample_controlled_vocab
                                  .sample_controlled_vocab_terms
                                  .first
                                  .label
                              })

    project = data[:project]
    export_params = {
      sample_ids: [sample.id].to_json,
      sample_type_id: data[:source_sample_type].id.to_json,
      study_id: data[:study].id.to_json,
      assay_id: nil.to_json,
      project_id: project.id.to_json
    }

    post :export_to_spreadsheet, params: export_params, format: :json
    assert_response :ok
    response_body = JSON.parse(response.body)
    cache_uuid = response_body['uuid']

    # This should fail because the sample belongs to a different project
    # Note: Currently returns a redirect, but should return a proper error response for xlsx format
    get :download_spreadsheet, params: { uuid: cache_uuid }, format: :xlsx
    assert_response :redirect, 'Expected redirect on error'
    assert flash[:error].present?, 'Expected an error message in flash for mismatched project'
    assert_equal "Export aborted! Some sample could not be associated with the provided project (\"#{project.id}: #{project.title}\").", flash[:error]
  end

  test 'download_spreadsheet succeeds with valid project-aligned data' do
    data = setup_test_data
    source_ids = data[:sources].map(&:id)

    export_params = {
      sample_ids: source_ids.to_json,
      sample_type_id: data[:source_sample_type].id.to_json,
      study_id: data[:study].id.to_json,
      assay_id: nil.to_json,
      project_id: data[:project].id.to_json
    }

    post :export_to_spreadsheet, params: export_params, format: :json
    assert_response :ok
    response_body = JSON.parse(response.body)
    cache_uuid = response_body['uuid']

    # This should succeed because all data belongs to the same project
    get :download_spreadsheet, params: { uuid: cache_uuid }, format: :xlsx
    assert_response :ok
    response_cd = response.headers['Content-Disposition']
    assert response_cd.include?('sources table.xlsx'), 'Expected sources table filename'
  end

  test 'download_spreadsheet fails when mixing samples from different projects' do
    data = setup_test_data
    person = data[:person]
    project2 = FactoryBot.create(:project)
    institution = FactoryBot.create(:institution)
    person.add_to_project_and_institution(project2, institution)

    # Create one sample in project1 and one in project2
    sample_project2 = FactoryBot.create(:sample,
                                       sample_type: data[:source_sample_type],
                                       project_ids: [project2.id],
                                       contributor: person,
                                       data: {
                                         'Source Name': 'Mixed Source',
                                         'Source Characteristic 1': 'Value 1',
                                         'Source Characteristic 2': data[:source_sample_type].sample_attributes
                                           .find_by_title('Source Characteristic 2')
                                           .sample_controlled_vocab
                                           .sample_controlled_vocab_terms
                                           .first
                                           .label
                                       })

    project = data[:project]
    # Try to download with mixed samples
    export_params = {
      sample_ids: [data[:sources].first.id, sample_project2.id].to_json,
      sample_type_id: data[:source_sample_type].id.to_json,
      study_id: data[:study].id.to_json,
      assay_id: nil.to_json,
      project_id: project.id.to_json
    }

    post :export_to_spreadsheet, params: export_params, format: :json
    assert_response :ok
    response_body = JSON.parse(response.body)
    cache_uuid = response_body['uuid']

    # This should fail because one sample doesn't belong to the specified project
    get :download_spreadsheet, params: { uuid: cache_uuid }, format: :xlsx
    assert_response :redirect, 'Expected redirect on error for mismatched project samples'
    assert flash[:error].present?, 'Expected error message when samples belong to different projects'
    assert_equal "Export aborted! Some sample could not be associated with the provided project (\"#{project.id}: #{project.title}\").", flash[:error]
  end

  test 'download_spreadsheet fails with invalid cache uuid' do
    # Try to download with a non-existent cache UUID
    get :download_spreadsheet, params: { uuid: 'invalid-uuid-that-does-not-exist' }, format: :xlsx
    assert_response :redirect, 'Expected redirect on invalid cache'
    assert flash[:error].present?, 'Expected error message for invalid cache'
  end

  test 'download_spreadsheet fails with expired cache uuid' do
    data = setup_test_data
    source_ids = data[:sources].map(&:id)

    export_params = {
      sample_ids: source_ids.to_json,
      sample_type_id: data[:source_sample_type].id.to_json,
      study_id: data[:study].id.to_json,
      assay_id: nil.to_json,
      project_id: data[:project].id.to_json
    }

    post :export_to_spreadsheet, params: export_params, format: :json
    assert_response :ok
    response_body = JSON.parse(response.body)
    cache_uuid = response_body['uuid']

    travel_to(Time.now + 2.minutes) do
      get :download_spreadsheet, params: { uuid: cache_uuid }, format: :xlsx
      assert_response :redirect, 'Expected redirect on invalid cache'
      assert flash[:error].present?, 'Expected error message for invalid cache'
      assert_equal "Request took too long or was interrupted.", flash[:error]
    end
  end

  test 'download_spreadsheet fails with any other format then xlsx' do
    data = setup_test_data
    source_ids = data[:sources].map(&:id)

    export_params = {
      sample_ids: source_ids.to_json,
      sample_type_id: data[:source_sample_type].id.to_json,
      study_id: data[:study].id.to_json,
      assay_id: nil.to_json,
      project_id: data[:project].id.to_json
    }

    post :export_to_spreadsheet, params: export_params, format: :json
    assert_response :ok
    response_body = JSON.parse(response.body)
    cache_uuid = response_body['uuid']

    responses = []
    Mime::SET.symbols.each do |mime_type|
      # Skip the xlsx format
      next if mime_type == :xlsx

      result = {}
      get :download_spreadsheet, params: { uuid: cache_uuid }, format: mime_type
      result[:mime_type] = mime_type
      result[:status] = response.status
      result[:error] = flash[:error]
      responses.append(result)
    end
    # The RDF Mime Type gets caught before and returns a 'Not Acceptable' instead of the redirect
    assert responses.map { |r| r[:status] }.all? { |s| s == 302 || s == 406 }

    errors = responses.map { |e| e[:error] }
    assert errors.none? { |e| e.blank? }
    assert errors.all? { |e| e == 'ActionController::UnknownFormat' }
  end
end
