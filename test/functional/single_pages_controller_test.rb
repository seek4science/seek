require 'test_helper'

class SinglePagesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  def setup
    @instance_name = Seek::Config.instance_name
    @member = FactoryBot.create :user
    login_as @member
    @initial_isa_json_compliance_enabled = Seek::Config.isa_json_compliance_enabled
    Seek::Config.isa_json_compliance_enabled = true
  end

  def teardown
    Seek::Config.isa_json_compliance_enabled = @initial_isa_json_compliance_enabled
  end

  test 'should show' do
    with_config_value(:project_single_page_enabled, true) do
      project = FactoryBot.create(:project)
      get :show, params: { id: project.id }
      assert_response :success
    end
  end

  test 'should hide inaccessible items in treeview' do
    project = FactoryBot.create(:project)
    FactoryBot.create(:investigation, contributor: @member.person, policy: FactoryBot.create(:private_policy),
                                      projects: [project])

    login_as(FactoryBot.create(:user))
    inv_two = FactoryBot.create(:investigation, contributor: User.current_user.person, policy: FactoryBot.create(:private_policy),
                                                projects: [project])

    controller = TreeviewBuilder.new project, nil
    result = controller.send(:build_tree_data)

    json = JSON.parse(result)[0]

    assert_equal 'hidden item', json['children'][0]['text']
    assert_equal inv_two.title, json['children'][1]['text']
  end

  test 'Should not generate export if not authorized' do
    id_label, _person, project, study, source_sample_type, sources = setup_file_upload.values_at(
      :id_label, :person, :project, :study, :source_sample_type, :sources
    )
    unauthorized_person = FactoryBot.create(:person)
    source_ids = sources.map { |s| { id_label => s.id } }
    sample_type_id = source_sample_type.id
    study_id = study.id
    assay_id = nil

    login_as(unauthorized_person)

    post_params = { sample_ids: source_ids.to_json,
                    sample_type_id: sample_type_id.to_json,
                    study_id: study_id.to_json,
                    assay_id: assay_id.to_json }

    post :export_to_excel, params: post_params, xhr: true

    assert_response :ok, msg = "Couldn't reach the server"

    response_body = JSON.parse(response.body)
    assert response_body.key?('uuid'), msg = "Response body is expected to have a 'uuid' key"
    cache_uuid = response_body['uuid']

    get :download_samples_excel, params: { uuid: cache_uuid }
    assert_redirected_to single_page_path(id: project.id, item_type: 'study', item_id: study_id)
    assert_equal flash[:error], 'Could not retrieve Study Sample Type! Do you have at least viewing permissions?'
  end

  test 'generates a valid export of study sources in single page' do
    # Generate the excel data
    id_label, person, _project, study, source_sample_type, sources = setup_file_upload.values_at(
      :id_label, :person, :project, :study, :source_sample_type, :sources
    )

    source_ids = sources.map { |s| { id_label => s.id } }
    sample_type_id = source_sample_type.id
    study_id = study.id
    assay_id = nil

    login_as(person)

    post_params = { sample_ids: source_ids.to_json,
                    sample_type_id: sample_type_id.to_json,
                    study_id: study_id.to_json,
                    assay_id: assay_id.to_json }

    post :export_to_excel, params: post_params, xhr: true

    assert_response :ok, msg = "Couldn't reach the server"

    response_body = JSON.parse(response.body)
    assert response_body.key?('uuid'), msg = "Response body is expected to have a 'uuid' key"
    cache_uuid = response_body['uuid']

    get :download_samples_excel, params: { uuid: cache_uuid }
    response_cd = response.headers["Content-Disposition"]
    assert_response :ok
    assert response_cd.include?("filename=\"#{study.id} - #{study.title} sources table.xlsx\"")
  end

  test 'generates a valid export of study samples in single page' do
    id_label, person, study, sample_collection_sample_type, study_samples = setup_file_upload.values_at(
      :id_label, :person, :study, :sample_collection_sample_type, :study_samples
    )

    source_sample_ids = study_samples.map { |ss| { id_label => ss.id } }
    sample_type_id = sample_collection_sample_type.id
    study_id = study.id
    assay_id = nil

    login_as(person)

    post_params = { sample_ids: source_sample_ids.to_json,
                    sample_type_id: sample_type_id.to_json,
                    study_id: study_id.to_json,
                    assay_id: assay_id.to_json }

    post :export_to_excel, params: post_params, xhr: true

    assert_response :ok, msg = "Couldn't reach the server"

    response_body = JSON.parse(response.body)
    assert response_body.key?('uuid'), msg = "Response body is expected to have a 'uuid' key"
    cache_uuid = response_body['uuid']

    get :download_samples_excel, params: { uuid: cache_uuid }
    response_cd = response.headers["Content-Disposition"]
    assert_response :ok
    assert response_cd.include?("filename=\"#{study.id} - #{study.title} samples table.xlsx\"")
  end

  test 'generates a valid export of assay samples in single page' do
    id_label, person, study, assay, assay_sample_type, assay_samples = setup_file_upload.values_at(
      :id_label, :person, :study, :assay, :assay_sample_type, :assay_samples
    )

    assay_sample_ids = assay_samples.map { |ss| { id_label => ss.id } }
    sample_type_id = assay_sample_type.id
    study_id = study.id
    assay_id = assay.id

    login_as(person)

    post_params = { sample_ids: assay_sample_ids.to_json,
                    sample_type_id: sample_type_id.to_json,
                    study_id: study_id.to_json,
                    assay_id: assay_id.to_json }

    post :export_to_excel, params: post_params, xhr: true

    assert_response :ok, msg = "Couldn't reach the server"

    response_body = JSON.parse(response.body)
    assert response_body.key?('uuid'), msg = "Response body is expected to have a 'uuid' key"
    cache_uuid = response_body['uuid']

    get :download_samples_excel, params: { uuid: cache_uuid }
    response_cd = response.headers["Content-Disposition"]
    assert_response :ok
    assert response_cd.include?("filename=\"#{assay.id} - #{assay.title} table.xlsx\"")
  end

  test 'invalid file extension should raise exception' do
    file_path = 'upload_single_page/00_wrong_format_spreadsheet.ods'
    file = fixture_file_upload(file_path, 'application/vnd.oasis.opendocument.spreadsheet')

    project, source_sample_type = setup_file_upload.values_at(
      :project, :source_sample_type
    )

    post :upload_samples, params: { file:, project_id: project.id,
                                    sample_type_id: source_sample_type.id }

    assert_response :bad_request
    assert_equal flash[:error], "Please upload a valid spreadsheet file with extension '.xlsx'"
  end

  test 'Should prevent to upload to the wrong Sample Type' do
    project, sample_collection_sample_type = setup_file_upload.values_at(
      :project, :sample_collection_sample_type
    )

    file_path = 'upload_single_page/01_combo_update_sources_spreadsheet.xlsx'
    file = fixture_file_upload(file_path, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

    post :upload_samples, as: :json, params: { file:, project_id: project.id,
                                               sample_type_id: sample_collection_sample_type.id }

    assert_response :bad_request
  end

  test 'Should not process invalid workbooks' do
    project, source_sample_type = setup_file_upload.values_at(
      :project, :source_sample_type
    )

    file_path = 'upload_single_page/02_invalid_workbook.xlsx'
    file = fixture_file_upload(file_path, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

    post :upload_samples, as: :json, params: { file:, project_id: project.id,
                                               sample_type_id: source_sample_type.id }

    assert_response :bad_request
  end

  test 'Should update, create and detect duplicate sources when uploading to a source Sample Type' do
    project, source_sample_type = setup_file_upload.values_at(
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
    project, sample_collection_sample_type = setup_file_upload.values_at(
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
    project, assay_sample_type = setup_file_upload.values_at(
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
    project, source_sample_type = setup_file_upload.values_at(
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
      id_label, person, project, study, source_sample_type, sources = setup_file_upload.values_at(
        :id_label, :person, :project, :study, :source_sample_type, :sources
      )

      source_ids = sources.map { |s| { id_label => s.id } }
      sample_type_id = source_sample_type.id
      study_id = study.id
      assay_id = nil

      post_params = { sample_ids: source_ids.to_json,
                      sample_type_id: sample_type_id.to_json,
                      study_id: study_id.to_json,
                      assay_id: assay_id.to_json }

      post :export_to_excel, params: post_params, format: :json

      assert_response :unprocessable_entity

      response_body = JSON.parse(response.body)
      assert_equal response_body, {"title" => "ISA JSON compliance are disabled"}
    end
  end

  test 'Should link registered assets to the sample metadata' do
    project, assay_sample_type = setup_file_upload.values_at(
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
    project, assay_sample_type = setup_file_upload.values_at(
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

  test 'Should sanitize spreadsheet name' do
    # Generate the excel data
    id_label, person, _project, study, source_sample_type, sources = setup_file_upload.values_at(
      :id_label, :person, :project, :study, :source_sample_type, :sources
    )

    study.update_column(:title, '<script>alert("Script tags should be removed!")</script> My sample type')

    source_ids = sources.map { |s| { id_label => s.id } }
    sample_type_id = source_sample_type.id
    study_id = study.id
    assay_id = nil

    login_as(person)

    post_params = { sample_ids: source_ids.to_json,
                    sample_type_id: sample_type_id.to_json,
                    study_id: study_id.to_json,
                    assay_id: assay_id.to_json }

    post :export_to_excel, params: post_params, xhr: true

    assert_response :ok

    response_body = JSON.parse(response.body)
    assert response_body.key?('uuid'), "Response body is expected to have a 'uuid' key"
    cache_uuid = response_body['uuid']

    get :download_samples_excel, params: { uuid: cache_uuid }
    response_cd = response.headers["Content-Disposition"]
    assert_response :ok
    expected_file_name = "My sample type sources table.xlsx"
    assert response_cd.include?(expected_file_name)
    assert %w[<script> </script>].none? { |tag| response_cd.include?(tag) }


  end

  private

  def setup_file_upload
    id_label = "#{Seek::Config.instance_name} id"
    person = @member.person
    institution = FactoryBot.create(:institution, title: 'Legion Of Doooooooooom', country: 'AQ')
    project = FactoryBot.create(:project, id: 10_000)
    person.add_to_project_and_institution(project, institution)
    investigation = FactoryBot.create(:investigation, id: 10_000, is_isa_json_compliant: true, projects: [project], contributor: person)
    study = FactoryBot.create(:study, id: 10_001, investigation: investigation, contributor: person)
    assay = FactoryBot.create(:assay, id: 10_002, study:, contributor: person)

    source_sample_type_template = FactoryBot.create(:isa_source_template, id: 10_006)
    source_sample_type = FactoryBot.create(:isa_source_sample_type,
                                           id: 10_003,
                                           contributor: person,
                                           project_ids: [project.id],
                                           isa_template: source_sample_type_template,
                                           studies: [study])

    sample_collection_sample_type_template = FactoryBot.create(:isa_sample_collection_template, id: 10_007)
    sample_collection_sample_type = FactoryBot.create(:isa_sample_collection_sample_type,
                                                      id: 10_004,
                                                      contributor: person,
                                                      project_ids: [project.id],
                                                      isa_template: sample_collection_sample_type_template,
                                                      studies: [study],
                                                      linked_sample_type: source_sample_type)

    assay_sample_type_template = FactoryBot.create(:isa_assay_material_template, id: 10_008)
    assay_sample_type = FactoryBot.create(:isa_assay_material_sample_type,
                                          id: 10_005,
                                          contributor: person,
                                          isa_template: assay_sample_type_template,
                                          projects: [project],
                                          studies: [study],
                                          linked_sample_type: sample_collection_sample_type)

    sources = (1..5).map do |n|
      FactoryBot.create(
        :sample,
        id: 10_010 + n,
        title: "source_#{n}",
        sample_type: source_sample_type,
        project_ids: [project.id],
        contributor: person,
        data: {
          'Source Name': "Source #{n}",
          'Source Characteristic 1': 'Source Characteristic 1',
          'Source Characteristic 2':
            source_sample_type
              .sample_attributes
              .find_by_title('Source Characteristic 2')
              .sample_controlled_vocab
              .sample_controlled_vocab_terms
              .first
              .label
        }
      )
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

  def car_catalogue(project, person)
    sample_catalogue_cars = FactoryBot.build(:sample_type,
                                              title: "Sample Catalogue Cars",
                                              projects: [project],
                                              contributor: person
                                             )
    sample_catalogue_cars.sample_attributes << [
      FactoryBot.create(:any_string_sample_attribute, title: "Car name", sample_type: sample_catalogue_cars, is_title: true),
      FactoryBot.create(:any_string_sample_attribute, title: "Brand", sample_type: sample_catalogue_cars),
      FactoryBot.create(:any_string_sample_attribute, title: "Model", sample_type: sample_catalogue_cars),
    ]
    sample_catalogue_cars.save
    names = [
      "Herbie",
      "Ecto-1",
      "K.I.T.T.",
      "General Lee",
      "DeLorean Time Machine"
    ]
    brands = [
      "Volkswagen",
      "Cadillac",
      "Pontiac",
      "Dodge",
      "DeLorean Motor Company"
    ]
    models = [
      "Beetle",
      "Miller-Meteor",
      "Firebird Trans Am",
      "Charger",
      "DMC-12"
    ]
    _cars = (1..5).map do |n|
      FactoryBot.create(:sample,
                        id: 10_040 + n,
                        title: names[n-1],
                        sample_type: sample_catalogue_cars,
                        project_ids: [project.id],
                        contributor: person,
                        data: {
                          'Car name': names[n-1],
                          Brand: brands[n-1],
                          Model: models[n-1]
                        }
      )
    end
    sample_catalogue_cars.reload
  end

  def flower_names(project, person)
    sample_catalogue_flower_names = FactoryBot.build(:sample_type,
                                                title: "Sample Catalogue Flowers",
                                                projects: [project],
                                                contributor: person
                                                )

    sample_catalogue_flower_names.sample_attributes << [
      FactoryBot.create(:any_string_sample_attribute, title: "Human name", sample_type: sample_catalogue_flower_names, is_title: true),
      FactoryBot.create(:any_string_sample_attribute, title: "Scientific Name", sample_type: sample_catalogue_flower_names),
      FactoryBot.create(:any_string_sample_attribute, title: "Trivial Name", sample_type: sample_catalogue_flower_names),
    ]
    sample_catalogue_flower_names.save
    human_names = %w[Rosalind Sonny Daisy Lavanda Daffy]
    scientific_names = ["Rosa indica", "Helianthus annuus", "Bellis perennis", "Lavandula", "Narcissus pseudonarcissus"]
    trivial_names = ["Rose", "Sunflower", "English Daisy", "Lavender", "Wild Daffodil"]
    _flowers = (1..5).map do |n|
      FactoryBot.create(:sample,
                        id: 10_050 + n,
                        title: human_names[n - 1],
                        sample_type: sample_catalogue_flower_names,
                        project_ids: [project.id],
                        contributor: person,
                        data: {
                          'Human name': human_names[n - 1],
                          'Scientific Name': scientific_names[n-1],
                          'Trivial Name': trivial_names[n-1]
                        }
      )
    end
    sample_catalogue_flower_names.reload
  end

  def bacteria_strains(project, person)
    organism = FactoryBot.create(:organism, title: "Bacteriaceae", projects: [project])
    bacteria_names = [
      "Escherichia coli",
      "Streptococcus pyogenes",
      "Staphylococcus aureus",
      "Streptococcus pneumoniae",
      "Clostridioides difficile"
    ]

    (1..5).map do |n|
      FactoryBot.create(:strain, id: 10_060 + n, title: bacteria_names[n-1], organism: organism, projects: [project], contributor: person)
    end
  end

  def create_data_files(project, person)
    file_types = [
      "Comma-Separated Values",
      "JavaScript Object Notation",
      "Extensible Markup Language",
      "Apache Parquet",
      "Portable Document Format"
    ]
    (1..5).map do |n|
      FactoryBot.create(:min_data_file, id: 10_070 + n, title: "My #{file_types[n-1]} file", projects: [project], contributor: person)
    end
  end

  def create_sops(project, person)
    lab_protocols = [
      "Standard Operating Procedure for High-Performance Liquid Chromatography (HPLC) Analysis",
      "Protocol for DNA Isolation and Purification Using the CTAB Method",
      "Polymerase Chain Reaction (PCR) Program for Target Sequence Amplification",
      "Protocol for Protein Extraction and SDS-PAGE Analysis",
      "Standard Procedure for Chemical Spill Response and Hazardous Waste Disposal"
    ]

    (1..5).map do |n|
      FactoryBot.create(:sop, id: 10_080 + n, title: lab_protocols[n-1], projects: [project], contributor: person)
    end
  end
end
