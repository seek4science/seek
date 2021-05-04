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

