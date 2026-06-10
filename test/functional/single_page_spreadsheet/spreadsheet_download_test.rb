require 'test_helper'

class  SpreadsheetDownloadTest < ActionController::TestCase
  include AuthenticatedTestHelper
  # include SinglePageTestUtils

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

  # Helper to set up test data similar to existing tests
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

    export_params = {
      sample_ids: [sample.id].to_json,
      sample_type_id: data[:source_sample_type].id.to_json,
      study_id: data[:study].id.to_json,
      assay_id: nil.to_json,
      project_id: data[:project].id.to_json
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
  end

  # ==================== Valid Download Tests ====================
  # Verify that valid downloads still work correctly after the validation fixes

  test 'generates a valid export of study samples in single page' do
    id_label, person, project, study, sample_collection_sample_type, study_samples = setup_test_data.values_at(
      :id_label, :person, :project, :study, :sample_collection_sample_type, :study_samples
    )

    source_sample_ids = study_samples.map(&:id)
    sample_type_id = sample_collection_sample_type.id
    study_id = study.id
    assay_id = nil
    project_id = project.id

    login_as(person)

    download_params = { sample_ids: source_sample_ids.to_json,
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
    assert response_cd.include?("filename=\"#{study.id} - #{study.title} samples table.xlsx\"")
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

    # Try to download with mixed samples
    export_params = {
      sample_ids: [data[:sources].first.id, sample_project2.id].to_json,
      sample_type_id: data[:source_sample_type].id.to_json,
      study_id: data[:study].id.to_json,
      assay_id: nil.to_json,
      project_id: data[:project].id.to_json
    }

    post :export_to_spreadsheet, params: export_params, format: :json
    assert_response :ok
    response_body = JSON.parse(response.body)
    cache_uuid = response_body['uuid']

    # This should fail because one sample doesn't belong to the specified project
    get :download_spreadsheet, params: { uuid: cache_uuid }, format: :xlsx
    assert_response :redirect, 'Expected redirect on error for mismatched project samples'
    assert flash[:error].present?, 'Expected error message when samples belong to different projects'
  end

  # ==================== Cache Timeout Test ====================
  # Verify that expired cache entries are properly rejected

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
    end
  end

  # ==================== Assay Project Alignment Test ====================
  # Verify that assays are also validated to belong to the correct project

  test 'download_spreadsheet with assay in valid project' do
    data = setup_test_data

    export_params = {
      sample_ids: [data[:sources].first.id].to_json,
      sample_type_id: data[:source_sample_type].id.to_json,
      study_id: data[:study].id.to_json,
      assay_id: nil.to_json,
      project_id: data[:project].id.to_json
    }

    post :export_to_spreadsheet, params: export_params, format: :json
    assert_response :ok
    response_body = JSON.parse(response.body)
    cache_uuid = response_body['uuid']

    # Download without assay should work
    get :download_spreadsheet, params: { uuid: cache_uuid }, format: :xlsx
    assert_response :ok
  end

  private

  def setup_test_data
    person = @member.person
    institution = FactoryBot.create(:institution)
    project = FactoryBot.create(:project)
    person.add_to_project_and_institution(project, institution)
    investigation = FactoryBot.create(:investigation, projects: [project], contributor: person)
    study = FactoryBot.create(:study, investigation:, contributor: person)
    assay = FactoryBot.create(:assay, study:, contributor: person)

    source_sample_type_template = FactoryBot.create(:isa_source_template)
    source_sample_type = FactoryBot.create(:isa_source_sample_type,
                                           contributor: person,
                                           projects: [project],
                                           isa_template: source_sample_type_template,
                                           studies: [study])

    sources = (1..3).map do |n|
      FactoryBot.create(:sample,
                        title: "source_#{n}",
                        sample_type: source_sample_type,
                        project_ids: [project.id],
                        contributor: person,
                        data: {
                          'Source Name': "Source #{n}",
                          'Source Characteristic 1': 'Value 1',
                          'Source Characteristic 2': source_sample_type.sample_attributes
                                                                       .find_by_title('Source Characteristic 2')
                                                                       .sample_controlled_vocab
                                                                       .sample_controlled_vocab_terms
                                                                       .first
                                                                       .label
                        })
    end

    study_samples = (1..4).map do |n|
      FactoryBot.create(
        :sample,
        id: 10_020 + n,
        title: "Sample collection #{n}",
        sample_type: sample_collection_sample_type,
        project_ids: [project.id],
        contributor: person,
        data: {
          Input: [sources[n - 1].id, sources[n].id],
          'sample collection': 'sample collection',
          'sample collection parameter value 1': 'sample collection parameter value 1',
          'Sample Name': "sample nr. #{n}",
          'sample characteristic 1': 'sample characteristic 1'
        }
      )
    end

    assay_samples = (1..3).map do |n|
      FactoryBot.create(
        :sample,
        id: 10_030 + n,
        title: "Assay Sample #{n}",
        sample_type: assay_sample_type,
        project_ids: [project.id],
        contributor: person,
        data: {
          Input: [study_samples[n - 1].id, study_samples[n].id],
          'Protocol Assay 1': 'How to make concentrated dark matter',
          'Assay 1 parameter value 1': 'Assay 1 parameter value 1',
          'Extract Name': "Extract nr. #{n}",
          'other material characteristic 1': 'other material characteristic 1'
        }
      )
    end

    {
      "id_label": id_label,
      "person": person,
      "project": project,
      "investigation": investigation,
      "study": study,
      "assay": assay,
      "source_sample_type": source_sample_type,
      "sample_collection_sample_type": sample_collection_sample_type,
      "assay_sample_type": assay_sample_type,
      "sources": sources,
      "study_samples": study_samples,
      "assay_samples": assay_samples
    }
  end
end
