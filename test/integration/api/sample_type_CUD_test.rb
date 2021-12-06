require 'test_helper'
require 'integration/api_test_helper'

class SampleTypeCUDTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    admin_login
    @clz = 'sample_type'
    @plural_clz = @clz.pluralize
    @project = @current_user.person.projects.first
    @sample_type = Factory(:simple_sample_type, project_ids: [@project.id], contributor:@current_person)
    @sample_type_attribute = @sample_type.sample_attributes.first
    @to_post = load_template("post_min_#{@clz}.json.erb", {project_id: @project.id, sample_attribute_type_title: @sample_type_attribute.sample_attribute_type.title})
    @assay = Factory(:assay, contributor:@current_person)
  end

  def test_should_delete_object
    assert_difference ("SampleType.count"), -1 do
      delete "/sample_types/#{@sample_type.id}.json"
      assert_response :success
    end
     get "/sample_types/#{@sample_type.id}.json"
     assert_response :not_found
     validate_json_against_fragment response.body, '#/definitions/errors'
  end


  def test_unauthorized_user_cannot_delete
    user_login(Factory(:person))
    assert_no_difference("#{@clz.classify.constantize}.count") do
      delete "/sample_types/#{@sample_type.id}.json"
      assert_response :forbidden
      validate_json_against_fragment response.body, '#/definitions/errors'
    end
  end

  def test_unauthorized_user_cannot_update
    user_login(Factory(:person))
    @to_post["data"]["id"] = "#{@sample_type.id}"
    @to_post["data"]["attributes"]["title"] = "updated by an unauthorized"
    patch "/sample_types/#{@sample_type.id}.json", params: @to_post
    assert_response :forbidden
    validate_json_against_fragment response.body, '#/definitions/errors'
  end

  def test_update_should_error_on_wrong_type
    to_patch = load_patch_template({})
    to_patch['data']['type'] = 'wrong'

    assert_no_difference ("SampleType.count") do
      put "/sample_types/#{@sample_type.id}.json", params: to_patch
      assert_response :unprocessable_entity
      validate_json_against_fragment response.body, '#/definitions/errors'
      assert_match "The specified data:type does not match the URL's object (#{to_patch['data']['type']} vs. #{@plural_clz})", response.body
    end
  end

  def test_update_should_error_on_missing_type

    to_patch = load_patch_template({})
    to_patch['data'].delete('type')

    assert_no_difference ("SampleType.count") do
      put "/sample_types/#{@sample_type.id}.json", params: to_patch
      assert_response :unprocessable_entity
      validate_json_against_fragment response.body, '#/definitions/errors'
      assert_match "A POST/PUT request must specify a data:type", response.body
    end
  end

  def test_update_should_error_on_wrong_id
    to_patch = load_patch_template(id: '100000000')
    assert_no_difference ("SampleType.count") do
      put "/sample_types/#{@sample_type.id}.json", params: to_patch
      assert_response :unprocessable_entity
      validate_json_against_fragment response.body, '#/definitions/errors'
      assert_match "id specified by the PUT request does not match object-id in the JSON input", response.body
    end
  end

  test 'create using attribute_type name' do
    attribute_type = Factory(:string_sample_attribute_type)
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
                "id": "#{@current_person.projects.first.id}",
                "type": "projects"
              }
            ]
          }
        }
      }
    }
    assert_difference('SampleType.count') do
      assert_difference('SampleAttribute.count') do
        post sample_types_path(format: :json), params: params.to_json, headers: { 'CONTENT_TYPE' => 'application/vnd.api+json' }
      end
    end
    assert_response :success

    sample_type = SampleType.last
    assert_equal 'In vivo biometrics', sample_type.title
    assert_equal 1,sample_type.sample_attributes.count
    assert_equal "Fish ID", sample_type.sample_attributes.first.title
    assert_equal attribute_type, sample_type.sample_attributes.first.sample_attribute_type

  end

  test 'create using attribute_type id' do
    attribute_type = Factory(:string_sample_attribute_type)
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
                "id": "#{@current_person.projects.first.id}",
                "type": "projects"
              }
            ]
          }
        }
      }
    }
    assert_difference('SampleType.count') do
      assert_difference('SampleAttribute.count') do
        post sample_types_path(format: :json), params: params.to_json, headers: { 'CONTENT_TYPE' => 'application/vnd.api+json' }
      end
    end
    assert_response :success

    sample_type = SampleType.last
    assert_equal 'In vivo biometrics', sample_type.title
    assert_equal 1,sample_type.sample_attributes.count
    assert_equal "Fish ID", sample_type.sample_attributes.first.title
    assert_equal attribute_type, sample_type.sample_attributes.first.sample_attribute_type

  end

  test 'update attribute title and description' do
    sample_type = Factory(:patient_sample_type)
    assert_equal 5,sample_type.sample_attributes.count

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
      patch sample_type_path(sample_type.id, format: :json), params: params.to_json, headers: { 'CONTENT_TYPE' => 'application/vnd.api+json' }
    end

    assert_response :success

    assert_equal 'the name',SampleAttribute.find(attr.id).title
    assert_equal 'the name for the patient',SampleAttribute.find(attr.id).description
    assert_equal 'patient:name',SampleAttribute.find(attr.id).pid
    assert_equal 5, SampleType.find(sample_type.id).sample_attributes.count
  end

  test 'add an attribute' do
    sample_type = Factory(:patient_sample_type)
    assert_equal 5,sample_type.sample_attributes.count

    str_attribute_type = Factory(:string_sample_attribute_type)

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
      patch sample_type_path(sample_type.id, format: :json), params: params.to_json, headers: { 'CONTENT_TYPE' => 'application/vnd.api+json' }
    end

    assert_response :success

    sample_type = SampleType.find(sample_type.id)
    attr = sample_type.sample_attributes.where(title:'a string').first
    assert_equal 6, sample_type.sample_attributes.count

    refute_nil attr
    assert attr.required?
    assert_equal str_attribute_type, attr.sample_attribute_type
    assert_equal 'a series of characters',attr.description

  end

  test 'remove an attribute' do
    sample_type = Factory(:patient_sample_type)
    assert_equal 5,sample_type.sample_attributes.count

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
      patch sample_type_path(sample_type.id, format: :json), params: params.to_json, headers: { 'CONTENT_TYPE' => 'application/vnd.api+json' }
    end

    assert_response :success

    sample_type = SampleType.find(sample_type.id)
    assert_empty sample_type.sample_attributes.where(title:'age')
    assert_equal 4, sample_type.sample_attributes.count
  end

  def create_post_values
    @post_values = {
        sample_attribute_type_title: @sample_type_attribute.sample_attribute_type.title,
        creator_id: @current_person.id,
        project_id: @project.id,
        assay_id: @assay.id}
  end

  def create_patch_values
    @patch_values = {
        id: @sample_type.id,
        title: "This is a new title.",
        attribute_title: "This is a new attribute title",
        project_id: @project.id,
        sample_attribute_type_title: @sample_type_attribute.sample_attribute_type.title,
        sample_attribute_id: @sample_type_attribute.id,
        assay_id: @assay.id
    }
  end

end

