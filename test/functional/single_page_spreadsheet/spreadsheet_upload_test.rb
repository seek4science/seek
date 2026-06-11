# frozen_string_literal: true

require 'test_helper'

class SpreadsheetUploadTest < ActionController::TestCase
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

  test 'invalid file extension should raise exception' do
    file_path = 'upload_single_page/00_wrong_format_spreadsheet.ods'
    file = fixture_file_upload(file_path, 'application/vnd.oasis.opendocument.spreadsheet')

    project, source_sample_type = setup_test_data.values_at(
      :project, :source_sample_type
    )

    post :upload_samples, params: { file:, project_id: project.id,
                                    sample_type_id: source_sample_type.id }

    assert_response :bad_request
    assert_equal flash[:error], "Please upload a valid spreadsheet file with extension '.xlsx'"
  end

  test 'Should prevent to upload to the wrong Sample Type' do
    project, sample_collection_sample_type = setup_test_data.values_at(
      :project, :sample_collection_sample_type
    )

    file_path = 'upload_single_page/01_combo_update_sources_spreadsheet.xlsx'
    file = fixture_file_upload(file_path, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

    post :upload_samples, as: :json, params: { file:, project_id: project.id,
                                               sample_type_id: sample_collection_sample_type.id }

    assert_response :bad_request
  end

  test 'Should not process invalid workbooks' do
    project, source_sample_type = setup_test_data.values_at(
      :project, :source_sample_type
    )

    file_path = 'upload_single_page/02_invalid_workbook.xlsx'
    file = fixture_file_upload(file_path, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

    post :upload_samples, as: :json, params: { file:, project_id: project.id,
                                               sample_type_id: source_sample_type.id }

    assert_response :bad_request
  end

  test 'Should update, create and detect duplicate sources when uploading to a source Sample Type' do
    project, source_sample_type = setup_test_data.values_at(
      :project, :source_sample_type
    )

    file_path = 'upload_single_page/01_combo_update_sources_spreadsheet.xlsx'
    file = fixture_file_upload(file_path, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

    post :upload_samples, as: :json, params: { file:, project_id: project.id,
                                               sample_type_id: source_sample_type.id }

    response_data = JSON.parse(response.body)['uploadData']
    db_samples = response_data['dbSamples']
    updated_samples = response_data['updateSamples']
    new_samples = response_data['newSamples']
    possible_duplicates = response_data['possibleDuplicates']

    assert_response :success
    assert_equal db_samples.size, 5
    assert_equal updated_samples.size, 2
    assert_equal new_samples.size, 2
    assert_equal possible_duplicates.size, 1

    post :upload_samples, as: :html, params: { file:, project_id: project.id,
                                               sample_type_id: source_sample_type.id }

    assert_response :success

    assert_select 'table#create-samples-table', count: 1 do
      assert_select "tbody tr", count: new_samples.size
    end

    assert_select 'table#update-samples-table', count: 1 do
      update_sample_ids = updated_samples.map { |s| s['id'] }
      update_sample_ids.map do |sample_id|
        row_id_updated = "update-sample-#{sample_id}-updated"
        assert_select "tr##{row_id_updated}", count: 1

        row_id_original = "update-sample-#{sample_id}-original"
        assert_select "tr##{row_id_original}", count: 1
      end
    end

    assert_select 'table#duplicate-samples-table', count: 1 do
      dup_sample_ids = possible_duplicates.map { |s| s['duplicate']['id'] }
      dup_sample_ids.map do |sample_id|
        row_id = "duplicate-sample-#{sample_id}"
        assert_select "tr##{row_id}-1", count: 1
        assert_select "tr##{row_id}-2", count: 1
      end
    end
  end

  test 'Should update, create and detect duplicate samples when uploading to a source sample Sample Type' do
    project, sample_collection_sample_type = setup_test_data.values_at(
      :project, :sample_collection_sample_type
    )

    file_path = 'upload_single_page/03_combo_update_samples_spreadsheet.xlsx'
    file = fixture_file_upload(file_path, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

    post :upload_samples, as: :json, params: { file:, project_id: project.id,
                                               sample_type_id: sample_collection_sample_type.id }

    response_data = JSON.parse(response.body)['uploadData']
    updated_samples = response_data['updateSamples']
    new_samples = response_data['newSamples']
    possible_duplicates = response_data['possibleDuplicates']

    assert_response :success
    assert_equal updated_samples.size, 2
    assert_equal new_samples.size, 2
    assert_equal possible_duplicates.size, 1

    post :upload_samples, as: :html, params: { file:, project_id: project.id,
                                               sample_type_id: sample_collection_sample_type.id }

    assert_response :success

    assert_select 'table#create-samples-table', count: 1 do
      assert_select "tbody tr", count: new_samples.size
    end

    assert_select 'table#update-samples-table', count: 1 do
      update_sample_ids = updated_samples.map { |s| s['id'] }
      update_sample_ids.map do |sample_id|
        row_id_updated = "update-sample-#{sample_id}-updated"
        assert_select "tr##{row_id_updated}", count: 1

        row_id_original = "update-sample-#{sample_id}-original"
        assert_select "tr##{row_id_original}", count: 1
      end
    end

    assert_select 'table#duplicate-samples-table', count: 1 do
      dup_sample_ids = possible_duplicates.map { |s| s['duplicate']['id'] }
      dup_sample_ids.map do |sample_id|
        row_id = "duplicate-sample-#{sample_id}"
        assert_select "tr##{row_id}-1", count: 1
        assert_select "tr##{row_id}-2", count: 1
      end
    end
  end

  test 'Should update, create and detect duplicate samples when uploading to a assay Sample Type' do
    project, assay_sample_type = setup_test_data.values_at(
      :project, :assay_sample_type
    )

    file_path = 'upload_single_page/04_combo_update_assay_samples_spreadsheet.xlsx'
    file = fixture_file_upload(file_path, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

    post :upload_samples, as: :json, params: { file:, project_id: project.id,
                                               sample_type_id: assay_sample_type.id }

    response_data = JSON.parse(response.body)['uploadData']
    updated_samples = response_data['updateSamples']
    new_samples = response_data['newSamples']
    possible_duplicates = response_data['possibleDuplicates']

    assert_response :success
    assert_equal updated_samples.size, 2
    assert_equal new_samples.size, 1
    assert_equal possible_duplicates.size, 1

    post :upload_samples, as: :html, params: { file:, project_id: project.id,
                                               sample_type_id: assay_sample_type.id }

    assert_response :success

    assert_select 'table#create-samples-table', count: 1 do
      assert_select "tbody tr", count: new_samples.size
    end

    assert_select 'table#update-samples-table', count: 1 do
      update_sample_ids = updated_samples.map { |s| s['id'] }
      update_sample_ids.map do |sample_id|
        row_id_updated = "update-sample-#{sample_id}-updated"
        assert_select "tr##{row_id_updated}", count: 1

        row_id_original = "update-sample-#{sample_id}-original"
        assert_select "tr##{row_id_original}", count: 1
      end
    end

    assert_select 'table#duplicate-samples-table', count: 1 do
      dup_sample_ids = possible_duplicates.map { |s| s['duplicate']['id'] }
      dup_sample_ids.map do |sample_id|
        row_id = "duplicate-sample-#{sample_id}"
        assert_select "tr##{row_id}-1", count: 1
        assert_select "tr##{row_id}-2", count: 1
      end
    end
  end

  test 'Should show permission conflicts for samples' do
    unauthorized_user = FactoryBot.create(:user)
    login_as unauthorized_user
    project, source_sample_type = setup_test_data.values_at(
      :project, :source_sample_type
    )

    file_path = 'upload_single_page/01_combo_update_sources_spreadsheet.xlsx'
    file = fixture_file_upload(file_path, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

    post :upload_samples, as: :json, params: { file:, project_id: project.id,
                                               sample_type_id: source_sample_type.id }

    response_data = JSON.parse(response.body)['uploadData']
    updated_samples = response_data['updateSamples']
    unauthorized_samples = response_data['unauthorized_samples']
    new_samples = response_data['newSamples']

    assert_response :success
    assert_equal updated_samples.size, 0
    assert_equal unauthorized_samples.size, 2
    assert_equal new_samples.size, 2

    possible_duplicates = response_data['possibleDuplicates']
    assert(possible_duplicates.size, 1)

    post :upload_samples, as: :html, params: { file:, project_id: project.id,
                                               sample_type_id: source_sample_type.id }

    assert_response :success

    assert_select 'table#create-samples-table', count: 1 do
      assert_select "tbody tr", count: new_samples.size
    end

    assert_select 'table#update-samples-table', count: 0

    assert_select 'table#unauthorized-samples-table', count: 1 do
      unauthorized_sample_ids = unauthorized_samples.map { |s| s['id'] }
      unauthorized_sample_ids.map do |sample_id|
        row_id = "unauthorized-sample-#{sample_id}"
        assert_select "tr##{row_id}", count: 1
      end
    end
  end

  test 'Should not be able to use the download feature if isa_json_compliance_enabled is false' do
    with_config_value(:isa_json_compliance_enabled, false) do
      id_label, person, project, study, source_sample_type, sources = setup_test_data.values_at(
        :id_label, :person, :project, :study, :source_sample_type, :sources
      )

      source_ids = sources.map(&:id)
      sample_type_id = source_sample_type.id
      study_id = study.id
      assay_id = nil
      project_id = project.id

      download_params = { sample_ids: source_ids.to_json,
                          sample_type_id: sample_type_id.to_json,
                          study_id: study_id.to_json,
                          assay_id: assay_id.to_json,
                          project_id: project_id.to_json}

      post :export_to_spreadsheet, params: download_params
      assert_redirected_to root_path

      post :export_to_spreadsheet, params: download_params, format: :json
      assert_response :unprocessable_entity
      response_body = JSON.parse(response.body)
      assert_equal "ISA JSON compliance are disabled", response_body['title']
    end
  end

  test 'Should link registered assets to the sample metadata' do
    project, assay_sample_type = setup_test_data.values_at(
      :project, :assay_sample_type
    )
    car_catalogue = car_catalogue(project, @member.person)
    flower_based_names_catalogue = flower_names(project, @member.person)
    _strains = bacteria_strains(project, @member.person)
    _data_files = create_data_files(project, @member.person)
    _sops = create_sops(project, @member.person)

    assay_sample_type.sample_attributes << [
      FactoryBot.create(:data_file_sample_attribute, required: false, is_title: false, sample_type: assay_sample_type, title: "Registered Data File"),
      FactoryBot.create(:sop_sample_attribute, required: false, is_title: false, sample_type: assay_sample_type, title: "Registered SOP"),
      FactoryBot.create(:strain_sample_attribute, required: false, is_title: false, sample_type: assay_sample_type, title: "Registered Strain"),
      FactoryBot.create(:sample_sample_attribute, required: false, is_title: false, sample_type: assay_sample_type, title: "Registered Sample", linked_sample_type: car_catalogue),
      FactoryBot.create(:sample_multi_sample_attribute, required: false, is_title: false, sample_type: assay_sample_type, title: "Registered Sample List", linked_sample_type: flower_based_names_catalogue),
    ]
    file_path = 'upload_single_page/05_combo_update_assay_samples_with_registered_assets_spreadsheet.xlsx'
    file = fixture_file_upload(file_path, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

    post :upload_samples, as: :json, params: { file:, project_id:project.id, sample_type_id: assay_sample_type.id }

    assert_response :success
    response_data = JSON.parse(response.body)['uploadData']
    updated_samples = response_data['updateSamples']
    unauthorized_samples = response_data['unauthorized_samples']
    new_samples = response_data['newSamples']
    possible_duplicates = response_data['possibleDuplicates']

    assert_equal updated_samples.size, 2
    assert_equal unauthorized_samples.size, 0
    assert_equal new_samples.size, 1
    assert_equal possible_duplicates.size, 1
  end

  test 'should raise error when Sample Type attributes don\'t match the spreadsheet header' do
    project, assay_sample_type = setup_test_data.values_at(
      :project, :assay_sample_type
    )

    # In the spreadsheet:
    # 'other material characteristic 1' was deleted
    # 'other material characteristic 2' was renamed to 'My made up attribute'
    file_path = 'upload_single_page/06_mismatch_sample_type_sample_header_row.xlsx'
    file = fixture_file_upload(file_path, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

    post :upload_samples, as: :json, params: { file:, project_id:project.id, sample_type_id: assay_sample_type.id }
    assert_response :bad_request
    assert_equal JSON.parse(response.body)["error"], "The Sample Attributes '[\"other material characteristic 1\", \"other material characteristic 2\"]' where not found in the uploaded spreadsheet. Sample upload was aborted!"
  end
end
