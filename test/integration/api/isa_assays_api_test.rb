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
    sample_type = response_body['data']['attributes']['sample_type']
    assert sample_type.present?
    assert response_body['data']['attributes']['input_sample_type_id'].present?
    assert_equal [], sample_type['samples']
  end

  test 'show ISA assay - samples are filtered by authorization' do
    assay = FactoryBot.create(:isa_json_compliant_material_assay, contributor: current_person,
                               linked_sample_type: @study.sample_types.last)
    assay_sample_type = assay.sample_type
    source_type = @study.sample_types.first
    collection_type = @study.sample_types.last

    source_vocab_term = source_type.sample_attributes.find_by_title('Source Characteristic 2')
                                    .sample_controlled_vocab.sample_controlled_vocab_terms.first.label
    source_sample = FactoryBot.create(:sample, sample_type: source_type,
                                               contributor: current_person,
                                               project_ids: current_person.projects.map(&:id),
                                               data: { 'Source Name' => 'Source 1',
                                                       'Source Characteristic 1' => 'c1',
                                                       'Source Characteristic 2' => source_vocab_term })

    collection_sample = FactoryBot.create(:sample, sample_type: collection_type,
                                                    contributor: current_person,
                                                    project_ids: current_person.projects.map(&:id),
                                                    data: { 'Input' => [source_sample.id],
                                                            'sample collection' => 'protocol 1',
                                                            'sample collection parameter value 1' => 'pv1',
                                                            'Sample Name' => 'Sample 1',
                                                            'sample characteristic 1' => 'char1' })

    assay_data = { 'Input' => [collection_sample.id], 'Protocol Assay 1' => 'prot',
                   'Assay 1 parameter value 1' => 'pv1', 'Extract Name' => 'Extract 1',
                   'other material characteristic 1' => 'mc1' }

    viewable_sample = FactoryBot.create(:sample, sample_type: assay_sample_type,
                                                  contributor: current_person,
                                                  project_ids: current_person.projects.map(&:id),
                                                  data: assay_data,
                                                  policy: FactoryBot.create(:public_policy))
    private_sample = FactoryBot.create(:sample, sample_type: assay_sample_type,
                                                 contributor: FactoryBot.create(:person),
                                                 project_ids: current_person.projects.map(&:id),
                                                 data: assay_data.merge('Extract Name' => 'Extract 2'),
                                                 policy: FactoryBot.create(:private_policy))

    get isa_assay_path(assay.id, format: :json), as: :json,
        headers: { "Authorization": read_access_auth }
    assert_response :success

    assay_samples = JSON.parse(response.body)['data']['attributes']['sample_type']['samples']
    sample_ids = assay_samples.map { |s| s['id'] }
    assert_includes sample_ids, viewable_sample.id.to_s
    refute_includes sample_ids, private_sample.id.to_s
    assert assay_samples.first['data'].present?
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


