require 'test_helper'

class ISAAssaysApiTest < ActionDispatch::IntegrationTest
  include ApiTestHelper
  def setup
    user_login
    @old_isa_json_compliance_config = Seek::Config.isa_json_compliance_enabled
    @old_single_pages_config = Seek::Config.project_single_page_folders_enabled
    Seek::Config.isa_json_compliance_enabled = true
    Seek::Config.project_single_page_folders_enabled = true
    @project = current_person.projects.first
    @study = FactoryBot.create(:isa_json_compliant_study, contributor: current_person)
    @assay_stream = FactoryBot.create(:assay_stream, contributor: current_person)
    @material_assay_template = FactoryBot.create(:isa_assay_material_template, contributor: current_person)
    @data_file_assay_template = FactoryBot.create(:isa_assay_data_file_template, contributor: current_person)
    @sample_multi_sample_attribute_type = FactoryBot.create(:sample_multi_sample_attribute_type)
    @string_sample_attribute_type = FactoryBot.create(:string_sample_attribute_type)

    # ISA tags
    @other_material_isa_tag = ISATag.find_by(title: 'other_material') || FactoryBot.create(:other_material_isa_tag)
    @other_material_characteristic_isa_tag = ISATag.find_by(title: 'other_material_characteristic') || FactoryBot.create(:other_material_characteristic_isa_tag)
    @protocol_isa_tag = ISATag.find_by(title: 'protocol') || FactoryBot.create(:protocol_isa_tag)
    @parameter_value_isa_tag = ISATag.find_by(title: 'parameter_value') || FactoryBot.create(:parameter_value_isa_tag)
    @input_isa_tag = ISATag.find_by(title: 'input') || FactoryBot.create(:input_isa_tag)

    @experimental_assay_class = AssayClass.experimental
  end

  def teardown
    Seek::Config.isa_json_compliance_enabled = @old_isa_json_compliance_config
    Seek::Config.project_single_page_folders_enabled = @old_single_pages_config
  end

  test 'show ISA assay' do
    assay = FactoryBot.create(:isa_json_compliant_material_assay, contributor: current_person,
                               linked_sample_type: @study.sample_types.last)

    get isa_assay_path(assay.id, format: :json), as: :json,
        headers: { "Authorization": read_access_auth }
    assert_response :success

    response_body = JSON.parse(response.body)
    assert_equal 'isa_assays', response_body['data']['type']
    assert_equal assay.id.to_s, response_body['data']['id']
    assert response_body['data']['attributes']['assay'].present?
    assert response_body['data']['attributes']['sample_type'].present?
    assert response_body['data']['attributes']['input_sample_type_id'].present?
  end

  test 'show ISA assay - not found' do
    get isa_assay_path(0, format: :json), as: :json,
        headers: { "Authorization": read_access_auth }
    assert_response :not_found
  end

  test 'show ISA assay - unauthorized' do
    other_person = FactoryBot.create(:person)
    assay = FactoryBot.create(:isa_json_compliant_material_assay, contributor: other_person,
                               linked_sample_type: @study.sample_types.last,
                               policy: FactoryBot.create(:private_policy))

    get isa_assay_path(assay.id, format: :json), as: :json,
        headers: { "Authorization": read_access_auth }
    assert_response :forbidden
  end

  test 'create ISA assay' do
    sample_collection_sample_type_id = @study.sample_types.last.id

    assay_params = {
      "title": "My new Material ISA Assay via API",
      "description": "This Material ISA Assay was created via the DataHub API",
      "study_id": @study.id,
      "assay_stream_id": @assay_stream.id,
      "assay_class_id": @experimental_assay_class.id
    }

    sample_type_params = {
      "title": "Material Assay sample type API",
      "description": "Material Assay sample type created via the DataHub API",
      "template_id": @material_assay_template.id,
      "sample_attributes_attributes":{
        "1":{
          "pos": 1,
          "sample_attribute_type_id": @sample_multi_sample_attribute_type.id,  # Registered sample multi type
          "title": "Input (collected sample)",
          "isa_tag_id": @input_isa_tag.id,  # Input has no tag
          "required": true,
          "is_title": false,
          "linked_sample_type_id": sample_collection_sample_type_id
        },
        "2": {
          "pos": 2,
          "sample_attribute_type_id": @string_sample_attribute_type.id,  # String type
          "isa_tag_id": @other_material_isa_tag.id,  # other_material
          "title": "Other material Name",
          "required": true,
          "is_title": true
        },
        "3": {
          "pos": 3,
          "sample_attribute_type_id": @string_sample_attribute_type.id,  # String type
          "isa_tag_id": @other_material_characteristic_isa_tag.id,  # other_material_characteristic
          "title": "Sample Characteristic",
          "required": false,
          "is_title": false
        },
        "4":{
          "pos": 4,
          "sample_attribute_type_id": @string_sample_attribute_type.id,  # String type
          "isa_tag_id": @protocol_isa_tag.id,  # Protocol
          "title": "Protocol used",
          "required": true,
          "is_title": false
        },
        "5":{
          "pos": 5,
          "sample_attribute_type_id": @string_sample_attribute_type.id,  # String type
          "isa_tag_id": @parameter_value_isa_tag.id,  # Parameter value
          "title": "Parameter Value",
          "required": false,
          "is_title": false
        }
      }
    }

    params = {
      "data": {
        "type": "isa_assays",
        "attributes": {
          "assay": assay_params,
          "sample_type": sample_type_params,
          "input_sample_type_id": sample_collection_sample_type_id
        }
      }
    }
    assert_difference('Assay.count', 1) do
      assert_difference('SampleType.count', 1) do
        assert_difference('SampleAttribute.count', 5) do
          post isa_assays_path(format: :json), params: params, as: :json, headers: { "Authorization": write_access_auth }
        end
      end
    end
  end

  test 'update ISA assay' do
    assay = FactoryBot.create(:isa_json_compliant_material_assay, contributor: current_person,
                                                                   linked_sample_type: @study.sample_types.last)
    # Ensure the sample type is editable by the current person
    assay.sample_type.update_column(:contributor_id, current_person.id)

    params = {
      "data": {
        "id": assay.id.to_s,
        "type": "isa_assays",
        "attributes": {
          "assay": {
            "description": "Updated description via API"
          },
          "sample_type": {
            "title": "Updated Sample Type Title"
          }
        }
      }
    }

    assert_changes -> { assay.reload.description }, to: "Updated description via API" do
      assert_changes -> { assay.sample_type.reload.title }, to: "Updated Sample Type Title" do
        patch isa_assay_path(assay.id, format: :json), params: params, as: :json,
              headers: { "Authorization": write_access_auth }
      end
    end
  end
end


