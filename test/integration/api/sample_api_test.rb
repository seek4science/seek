require 'test_helper'

class SampleApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def populate_extra_attributes(hash)
    extra_attributes = super

    title = hash.dig('data', 'attributes', 'attribute_map', 'the_title')
    extra_attributes[:title] = title if title

    extra_attributes
  end

  def setup
    user_login

    @sample = Factory(:sample, contributor: current_person, policy: Factory(:public_policy))

    @project = Factory(:min_project)
    @project.title = 'testProject'

    institution = Factory(:institution)
    current_person.add_to_project_and_institution(@project, institution)
    @sample_type = SampleType.new(title: "vahidSampleType", project_ids: [@project.id], contributor: current_person)
    @sample_type.sample_attributes << Factory(:sample_attribute, title: 'the_title', is_title: true, required: true, sample_attribute_type: Factory(:string_sample_attribute_type), sample_type: Factory(:simple_sample_type))
    @sample_type.sample_attributes << Factory(:sample_attribute, title: 'a_real_number', sample_attribute_type: Factory(:float_sample_attribute_type), required: false, sample_type: @sample_type)
    @sample_type.save!

    @assay = Factory(:assay, contributor: current_person)
  end

  test 'patching a couple of attributes retains others' do
    user_login
    sample = Factory(:patient_sample, contributor: current_person, policy: Factory(:public_policy))
    params = {
      "data": {
        "type": "samples",
        "id": "#{sample.id}",
        "attributes": {
          "attribute_map": {
            "full name": "Jack Frost",
            "weight": 12.4,
            "postcode": "Z50 8GG"
          }
        }
      }
    }
    assert_no_difference('Sample.count') do
      patch sample_path(sample.id, format: :json), params: params, as: :json
    end

    assert_response :success
    sample = Sample.find(sample.id)
    assert_equal "Jack Frost", sample.get_attribute_value("full name")
    assert_equal 12.4, sample.get_attribute_value("weight")
    assert_equal "Z50 8GG", sample.get_attribute_value("postcode")
    assert_equal 44, sample.get_attribute_value("age")
  end

  test 'patching a couple of attributes retains others including capitals' do
    user_login
    User.current_user = @current_user
    sample = Factory(:max_sample, contributor: current_person, policy: Factory(:public_policy))
    params = {
      "data": {
        "type": "samples",
        "id": "#{sample.id}",
        "attributes": {
          "attribute_map": {
            "full_name": "Jack Frost",
            'CAPITAL key': 'some value',
            "postcode": "Z50 8GG"
          }
        }
      }
    }
    assert_no_difference('Sample.count') do
      patch sample_path(sample.id, format: :json), params: params, as: :json
    end

    assert_response :success
    sample = Sample.find(sample.id)
    assert_equal "Jack Frost", sample.get_attribute_value("full_name")
    assert_equal "Z50 8GG", sample.get_attribute_value("postcode")
    assert_equal 'HD', sample.get_attribute_value("address")
    assert_equal "some value", sample.get_attribute_value("CAPITAL key")
  end

  test 'set sample_type and attributes in post' do
    user_login
    patient_sample_type = Factory(:patient_sample_type)
    params = {
      "data": {
        "type": "samples",
        "attributes": {
          "title": "Jack Frost",
          "attribute_map": {
            "full name": "Jack Frost",
            "weight": 12.4,
            "age": 12
          }
        },
        "relationships": {
          "projects": {
            "data":
              [
                {
                  "type": "projects",
                  "id": "#{current_person.projects.first.id}"
                }
              ]
          },
          "sample_type": {
            "data": {
              "id": "#{patient_sample_type.id}",
              "type": "sample_types"
            }
          }
        }
      }
    }
    assert_difference('Sample.count') do
      post samples_path(format: :json), params: params, as: :json
    end
    assert_response :success
    sample = Sample.last
    assert_equal patient_sample_type, sample.sample_type
    assert_equal "Jack Frost", sample.get_attribute_value("full name")
    assert_equal 12.4, sample.get_attribute_value("weight")
    assert_equal 12, sample.get_attribute_value("age")
  end

  test 'batch create' do 
    skip
    person = Factory(:person)
    user_login(person)
    project = Factory(:project)
    institution = Factory(:institution)
    person.add_to_project_and_institution(project, institution)
    investigation = Factory(:investigation, contributor: person)
    study = Factory(:study, contributor: person)
    type = Factory(:patient_sample_type, contributor: person)
    assay = Factory(:assay, contributor: person, sample_type: type)

    other_person = Factory(:person)
    user_login(other_person)
    other_person.add_to_project_and_institution(project, institution)
    params = {
      "data": [
        {
          "ex_id": "1",
          "data": {
            "type": "samples",
            "attributes": {
              "title": "Jack Frost",
              "attribute_map": {"full name": "Jack Frost","weight": 12.4,"age": 12}
            },
            "relationships": {
              "projects": {"data":[{"type": "projects","id": "#{project.id}"}]},
              "sample_type": {"data": {"id": "#{type.id}","type": "sample_types"}},
              "assays":{"data": [{"type": "assays","id": "#{assay.id}"}]}
            }
          }
        },
        {
          "ex_id": "2",
          "data": {
            "type": "samples",
            "attributes": {
              "title": "Mary Poppins",
              "attribute_map": {"full name": "Mary Poppins","weight": 12.4,"age": 44}
            },
            "relationships": {
              "projects": {"data":[{"type": "projects","id": "#{project.id}"}]},
              "sample_type": {"data": {"id": "#{type.id}","type": "sample_types"}},
              "assays":{"data": [{"type": "assays","id": "#{assay.id}"}]}
            }
          }
        }
      ]
    }

    assert_difference('Sample.count', 0) do
      assert_difference('AssayAsset.count', 0) do
        assert_difference('SampleType.count', 0) do
          post "/samples/batch_create", as: :json, params: params
          assert_response :success
        end
      end
    end

    assay.policy.permissions.create!(access_type: Policy::EDITING, contributor: other_person)

    assert_difference('Sample.count', 2) do
      assert_difference('AssayAsset.count', 2) do
        assert_difference('SampleType.count', 0) do
          post "/samples/batch_create", as: :json, params: params
          assert_response :success
        end
      end
    end

  end

  def create_post_values
      @post_values = {
         sample_type_id: @sample_type.id,
         creator_id: @current_person.id, 
         project_id: @min_project.id}
  end

  def create_patch_values
    @patch_values = {
      id: @sample.id,
      sample_type_id: @sample_type.id,
      project_id: @min_project.id,
      creator_ids: [@current_person.id],
      the_title: @sample.get_attribute_value("the_title")}
  end

end
