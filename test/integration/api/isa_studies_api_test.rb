require 'test_helper'

class ISAStudiesApiTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    user_login
    @old_isa_json_compliance_config = Seek::Config.isa_json_compliance_enabled
    @old_single_pages_config = Seek::Config.project_single_page_folders_enabled
    Seek::Config.isa_json_compliance_enabled = true
    Seek::Config.project_single_page_folders_enabled = true
    @project = current_person.projects.first
    @investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true,
                                                       projects: [@project],
                                                       contributor: current_person)
    @sample_multi_sample_attribute_type = FactoryBot.create(:sample_multi_sample_attribute_type)
    @string_sample_attribute_type = FactoryBot.create(:string_sample_attribute_type)

    # ISA tags
    @source_isa_tag = ISATag.find_by(title: 'source') || FactoryBot.create(:source_isa_tag)
    @sample_isa_tag = ISATag.find_by(title: 'sample') || FactoryBot.create(:sample_isa_tag)
    @input_isa_tag = ISATag.find_by(title: 'input') || FactoryBot.create(:input_isa_tag)
    @protocol_isa_tag = ISATag.find_by(title: 'protocol') || FactoryBot.create(:protocol_isa_tag)
    @source_characteristic_isa_tag = ISATag.find_by(title: 'source_characteristic') || FactoryBot.create(:source_characteristic_isa_tag)
  end

  def teardown
    Seek::Config.isa_json_compliance_enabled = @old_isa_json_compliance_config
    Seek::Config.project_single_page_folders_enabled = @old_single_pages_config
  end

  test 'show ISA study' do
    study = FactoryBot.create(:isa_json_compliant_study, contributor: current_person)

    get isa_study_path(study.id, format: :json), as: :json,
        headers: { "Authorization": read_access_auth }
    assert_response :success

    response_body = JSON.parse(response.body)
    assert_equal 'isa_studies', response_body['data']['type']
    assert_equal study.id.to_s, response_body['data']['id']
    assert response_body['data']['attributes']['study'].present?
    source = response_body['data']['attributes']['source_sample_type']
    collection = response_body['data']['attributes']['sample_collection_sample_type']
    assert source.present?
    assert collection.present?
    assert_equal [], source['samples']
    assert_equal [], collection['samples']
  end

  test 'show ISA study - samples are filtered by authorization' do
    study = FactoryBot.create(:isa_json_compliant_study, contributor: current_person)
    source_type = study.sample_types.first
    vocab_term = source_type.sample_attributes.find_by_title('Source Characteristic 2')
                             .sample_controlled_vocab.sample_controlled_vocab_terms.first.label
    sample_data = { 'Source Name' => 'Source 1', 'Source Characteristic 1' => 'char1',
                    'Source Characteristic 2' => vocab_term }

    viewable_sample = FactoryBot.create(:sample, sample_type: source_type,
                                                  contributor: current_person,
                                                  project_ids: current_person.projects.map(&:id),
                                                  data: sample_data,
                                                  policy: FactoryBot.create(:public_policy))
    private_sample = FactoryBot.create(:sample, sample_type: source_type,
                                                 contributor: FactoryBot.create(:person),
                                                 project_ids: current_person.projects.map(&:id),
                                                 data: sample_data.merge('Source Name' => 'Source 2'),
                                                 policy: FactoryBot.create(:private_policy))

    get isa_study_path(study.id, format: :json), as: :json,
        headers: { "Authorization": read_access_auth }
    assert_response :success

    source_samples = JSON.parse(response.body)['data']['attributes']['source_sample_type']['samples']
    sample_ids = source_samples.map { |s| s['id'] }
    assert_includes sample_ids, viewable_sample.id.to_s
    refute_includes sample_ids, private_sample.id.to_s
    assert source_samples.first['data'].present?
  end

  test 'show ISA study - not found' do
    get isa_study_path(0, format: :json), as: :json,
        headers: { "Authorization": read_access_auth }
    assert_response :not_found
  end

  test 'show ISA study - unauthorized' do
    other_person = FactoryBot.create(:person)
    study = FactoryBot.create(:isa_json_compliant_study, contributor: other_person,
                               policy: FactoryBot.create(:private_policy))

    get isa_study_path(study.id, format: :json), as: :json,
        headers: { "Authorization": read_access_auth }
    assert_response :forbidden
  end

  test 'create ISA study' do
    source_sample_type_params = {
      "title": "Source Sample Type via API",
      "description": "Source sample type created via the API",
      "sample_attributes_attributes": {
        "1": {
          "pos": 1,
          "title": "Source Name",
          "sample_attribute_type_id": @string_sample_attribute_type.id,
          "isa_tag_id": @source_isa_tag.id,
          "required": true,
          "is_title": true
        },
        "2": {
          "pos": 2,
          "title": "Species",
          "sample_attribute_type_id": @string_sample_attribute_type.id,
          "isa_tag_id": @source_characteristic_isa_tag.id,
          "required": false,
          "is_title": false
        }
      }
    }

    sample_collection_sample_type_params = {
      "title": "Sample Collection Sample Type via API",
      "description": "Sample collection sample type created via the API",
      "sample_attributes_attributes": {
        "1": {
          "pos": 1,
          "title": "Input",
          "sample_attribute_type_id": @sample_multi_sample_attribute_type.id,
          "linked_sample_type_id": "self",
          "required": true,
          "is_title": false,
          "isa_tag_id": @input_isa_tag.id
        },
        "2": {
          "pos": 2,
          "title": "Sample Name",
          "sample_attribute_type_id": @string_sample_attribute_type.id,
          "isa_tag_id": @sample_isa_tag.id,
          "required": true,
          "is_title": true
        },
        "3": {
          "pos": 3,
          "title": "Collection Protocol",
          "sample_attribute_type_id": @string_sample_attribute_type.id,
          "isa_tag_id": @protocol_isa_tag.id,
          "required": true,
          "is_title": false
        }
      }
    }

    params = {
      "data": {
        "type": "isa_studies",
        "attributes": {
          "study": {
            "title": "My new ISA Study via API",
            "description": "This ISA Study was created via the API",
            "investigation_id": @investigation.id
          },
          "source_sample_type": source_sample_type_params,
          "sample_collection_sample_type": sample_collection_sample_type_params
        }
      }
    }

    assert_difference('Study.count', 1) do
      assert_difference('SampleType.count', 2) do
        assert_difference('SampleAttribute.count', 5) do
          post isa_studies_path(format: :json), params: params, as: :json,
               headers: { "Authorization": write_access_auth }
        end
      end
    end
    assert_response :created
  end

  test 'update ISA study' do
    study = FactoryBot.create(:isa_json_compliant_study, contributor: current_person)
    # Ensure both sample types are editable by the current person
    study.sample_types.each { |st| st.update_column(:contributor_id, current_person.id) }

    params = {
      "data": {
        "id": study.id.to_s,
        "type": "isa_studies",
        "attributes": {
          "study": {
            "description": "Updated description via API"
          },
          "source_sample_type": {
            "title": "Updated Source Sample Type Title"
          }
        }
      }
    }

    assert_changes -> { study.reload.description }, to: "Updated description via API" do
      assert_changes -> { study.sample_types.first.reload.title }, to: "Updated Source Sample Type Title" do
        patch isa_study_path(study.id, format: :json), params: params, as: :json,
              headers: { "Authorization": write_access_auth }
      end
    end

    assert_response :ok
    assert_nothing_raised { validate_json(response.body, '#/components/schemas/isaStudyResponse') }
  end

  test 'show ISA study - response conforms to the documented schema' do
    study = FactoryBot.create(:isa_json_compliant_study, contributor: current_person)

    get isa_study_path(study.id, format: :json), as: :json,
        headers: { "Authorization": read_access_auth }
    assert_response :success

    assert_nothing_raised { validate_json(response.body, '#/components/schemas/isaStudyResponse') }
  end

  test 'show ISA study - not found response conforms to the documented schema' do
    get isa_study_path(0, format: :json), as: :json,
        headers: { "Authorization": read_access_auth }
    assert_response :not_found

    assert_nothing_raised { validate_json(response.body, '#/components/schemas/notFoundResponse') }
  end

  test 'update ISA study - not found' do
    params = {
      "data": {
        "id": "0",
        "type": "isa_studies",
        "attributes": {
          "study": { "description": "Updated description via API" }
        }
      }
    }

    patch isa_study_path(0, format: :json), params: params, as: :json,
          headers: { "Authorization": write_access_auth }

    assert_response :not_found
    assert_nothing_raised { validate_json(response.body, '#/components/schemas/notFoundResponse') }
  end

  test 'update ISA study - not found when the study has no sample types' do
    plain_study = FactoryBot.create(:study, contributor: current_person)

    params = {
      "data": {
        "id": plain_study.id.to_s,
        "type": "isa_studies",
        "attributes": {
          "study": { "description": "Updated description via API" }
        }
      }
    }

    patch isa_study_path(plain_study.id, format: :json), params: params, as: :json,
          headers: { "Authorization": write_access_auth }

    assert_response :not_found
    assert_nothing_raised { validate_json(response.body, '#/components/schemas/notFoundResponse') }
  end

  # The documented request shape uses a `sample_attributes` array with a nested `sample_attribute_type`
  # object, rather than the `sample_attributes_attributes` hash the UI form posts.
  test 'create ISA study - using the documented request shape' do
    params = documented_isa_study_post_params

    assert_nothing_raised { validate_json(params.to_json, '#/components/schemas/isaStudyPost') }

    assert_difference('Study.count', 1) do
      assert_difference('SampleType.count', 2) do
        assert_difference('SampleAttribute.count', 5) do
          post isa_studies_path(format: :json), params: params, as: :json,
               headers: { "Authorization": write_access_auth }
        end
      end
    end

    assert_response :created
    assert_nothing_raised { validate_json(response.body, '#/components/schemas/isaStudyResponse') }

    study = Study.last
    assert_equal 'My documented ISA Study', study.title
    source_type = study.sample_types.first
    assert_equal 'Source Name', source_type.sample_attributes.first.title
    assert_equal 'String', source_type.sample_attributes.first.sample_attribute_type.title
  end

  test 'create ISA study - top level policy is applied to the study and its sample types' do
    params = documented_isa_study_post_params
    params[:data][:attributes][:policy] = { access: 'download', permissions: [] }

    post isa_studies_path(format: :json), params: params, as: :json,
         headers: { "Authorization": write_access_auth }
    assert_response :created

    study = Study.last
    assert_equal Policy::ACCESSIBLE, study.policy.access_type
    study.sample_types.each do |sample_type|
      assert_equal Policy::ACCESSIBLE, sample_type.policy.access_type
    end
  end

  test 'create ISA study - sample type without a protocol tagged attribute is rejected' do
    params = documented_isa_study_post_params
    collection_attributes = params[:data][:attributes][:sample_collection_sample_type][:sample_attributes]
    protocol_attribute = collection_attributes.detect { |a| a[:isa_tag_id] == @protocol_isa_tag.id.to_s }
    protocol_attribute[:isa_tag_id] = @source_characteristic_isa_tag.id.to_s

    assert_no_difference('Study.count') do
      post isa_studies_path(format: :json), params: params, as: :json,
           headers: { "Authorization": write_access_auth }
    end

    assert_response :unprocessable_entity
    assert_nothing_raised { validate_json(response.body, '#/components/schemas/unprocessableEntityResponse') }
    assert_includes response.body, "exactly one attribute with the 'protocol' ISA tag"
  end

  private

  def documented_isa_study_post_params
    {
      data: {
        type: 'isa_studies',
        attributes: {
          study: {
            title: 'My documented ISA Study',
            description: 'Created using the shape described in the API documentation',
            investigation_id: @investigation.id.to_s
          },
          source_sample_type: {
            title: 'Documented Source Sample Type',
            sample_attributes: [
              { title: 'Source Name', pos: 1, required: true, is_title: true,
                sample_attribute_type: { title: 'String' }, isa_tag_id: @source_isa_tag.id.to_s },
              { title: 'Species', pos: 2, required: false, is_title: false,
                sample_attribute_type: { title: 'String' },
                isa_tag_id: @source_characteristic_isa_tag.id.to_s }
            ]
          },
          sample_collection_sample_type: {
            title: 'Documented Sample Collection Sample Type',
            sample_attributes: [
              { title: 'Input', pos: 1, required: true, is_title: false,
                sample_attribute_type: { title: @sample_multi_sample_attribute_type.title },
                linked_sample_type_id: 'self', isa_tag_id: @input_isa_tag.id.to_s },
              { title: 'Sample Name', pos: 2, required: true, is_title: true,
                sample_attribute_type: { title: 'String' }, isa_tag_id: @sample_isa_tag.id.to_s },
              { title: 'Collection Protocol', pos: 3, required: true, is_title: false,
                sample_attribute_type: { title: 'String' }, isa_tag_id: @protocol_isa_tag.id.to_s }
            ]
          }
        }
      }
    }
  end
end
