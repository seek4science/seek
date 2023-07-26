require 'test_helper'

class SampleTypeApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def setup
    user_login(FactoryBot.create(:project_administrator))
    @project = @current_user.person.projects.first
    @sample_type = FactoryBot.create(:simple_sample_type, project_ids: [@project.id], contributor: current_person)
    @sample_attribute = @sample_type.sample_attributes.first
    @sample_attribute_type = @sample_attribute.sample_attribute_type
    @assay = FactoryBot.create(:assay, contributor: current_person)
  end

  test 'create using attribute_type name' do
    attribute_type = FactoryBot.create(:string_sample_attribute_type)
    params = {
      "data": {
        "type": "sample_types",
        "attributes": {
          "title": "In vivo biometrics",
          "description": "Template for in vivo biometrics data",
          "sample_attributes": [
            {
              "title": "Fish ID",
              "sample_attribute_type": {
                "id": "#{attribute_type.id}"
              },
              "required": true,
              "pos": "1",
              "is_title": true
            }
          ]
        },
        "relationships": {
          "projects": {
            "data": [
              {
                "id": "#{current_person.projects.first.id}",
                "type": "projects"
              }
            ]
          }
        }
      }
    }
    assert_difference('SampleType.count') do
      assert_difference('SampleAttribute.count') do
        post sample_types_path(format: :json), params: params, as: :json
      end
    end
    assert_response :success

    sample_type = SampleType.last
    assert_equal 'In vivo biometrics', sample_type.title
    assert_equal 1, sample_type.sample_attributes.count
    assert_equal "Fish ID", sample_type.sample_attributes.first.title
    assert_equal attribute_type, sample_type.sample_attributes.first.sample_attribute_type

  end

  test 'create using attribute_type id' do
    attribute_type = FactoryBot.create(:string_sample_attribute_type)
    params = {
      "data": {
        "type": "sample_types",
        "attributes": {
          "title": "In vivo biometrics",
          "description": "Template for in vivo biometrics data",
          "sample_attributes": [
            {
              "title": "Fish ID",
              "sample_attribute_type": {
                "id": "#{attribute_type.id}"
              },
              "required": true,
              "pos": "1",
              "is_title": true
            }
          ]
        },
        "relationships": {
          "projects": {
            "data": [
              {
                "id": "#{current_person.projects.first.id}",
                "type": "projects"
              }
            ]
          }
        }
      }
    }
    assert_difference('SampleType.count') do
      assert_difference('SampleAttribute.count') do
        post sample_types_path(format: :json), params: params, as: :json
      end
    end
    assert_response :success

    sample_type = SampleType.last
    assert_equal 'In vivo biometrics', sample_type.title
    assert_equal 1, sample_type.sample_attributes.count
    assert_equal "Fish ID", sample_type.sample_attributes.first.title
    assert_equal attribute_type, sample_type.sample_attributes.first.sample_attribute_type

  end

  test 'update attribute title and description' do
    sample_type = FactoryBot.create(:patient_sample_type, contributor: current_person)
    assert_equal 5, sample_type.sample_attributes.count

    attr = sample_type.sample_attributes.where(title: 'full name').first

    # rename an attribute
    params = {
      "data": {
        "type": "sample_types",
        "attributes": {
          "sample_attributes": [
            {
              "id": "#{attr.id}",
              "title": "the name",
              "description": "the name for the patient",
              "pid": "patient:name"
            }
          ]
        }
      }
    }

    assert_no_difference('SampleAttribute.count') do
      patch sample_type_path(sample_type.id, format: :json), params: params, as: :json
    end

    assert_response :success

    assert_equal 'the name', SampleAttribute.find(attr.id).title
    assert_equal 'the name for the patient', SampleAttribute.find(attr.id).description
    assert_equal 'patient:name', SampleAttribute.find(attr.id).pid
    assert_equal 5, SampleType.find(sample_type.id).sample_attributes.count
  end

  test 'add an attribute' do
    sample_type = FactoryBot.create(:patient_sample_type, contributor: current_person)
    assert_equal 5, sample_type.sample_attributes.count

    str_attribute_type = FactoryBot.create(:string_sample_attribute_type)

    # rename an attribute
    params = {
      "data": {
        "type": "sample_types",
        "attributes": {
          "sample_attributes": [
            title: 'a string',
            description: 'a series of characters',
            "sample_attribute_type": {
              "id": "#{str_attribute_type.id}"
            },
            "required": true
          ]
        }
      }
    }

    assert_difference('SampleAttribute.count') do
      patch sample_type_path(sample_type.id, format: :json), params: params, as: :json
    end

    assert_response :success

    sample_type = SampleType.find(sample_type.id)
    attr = sample_type.sample_attributes.where(title: 'a string').first
    assert_equal 6, sample_type.sample_attributes.count

    refute_nil attr
    assert attr.required?
    assert_equal str_attribute_type, attr.sample_attribute_type
    assert_equal 'a series of characters', attr.description

  end

  test 'remove an attribute' do
    sample_type = FactoryBot.create(:patient_sample_type, contributor: current_person)
    assert_equal 5, sample_type.sample_attributes.count

    attr = sample_type.sample_attributes.where(title: 'age').first

    # rename an attribute
    params = {
      "data": {
        "type": "sample_types",
        "attributes": {
          "sample_attributes": [
            {
              "id": "#{attr.id}",
              "_destroy": true
            }
          ]
        }
      }
    }

    assert_difference('SampleAttribute.count', -1) do
      patch sample_type_path(sample_type.id, format: :json), params: params, as: :json
    end

    assert_response :success

    sample_type = SampleType.find(sample_type.id)
    assert_empty sample_type.sample_attributes.where(title: 'age')
    assert_equal 4, sample_type.sample_attributes.count
  end
end
