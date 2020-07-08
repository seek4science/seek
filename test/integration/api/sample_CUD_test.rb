require 'test_helper'
require 'integration/api_test_helper'

class SampleCUDTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    admin_login
    @clz = "sample"
    @plural_clz = @clz.pluralize

    @sample = Factory(:sample, contributor: @current_person, policy: Factory(:public_policy))

    @min_project = Factory(:min_project)
    @min_project.title = 'testProject'

    institution = Factory(:institution)
    @current_person.add_to_project_and_institution(@min_project, institution)
    @sample_type = SampleType.new({title:"vahidSampleType", project_ids: [@min_project.id], contributor:@current_person})
    @sample_type.sample_attributes << Factory(:sample_attribute,title: 'the_title', is_title: true, required: true, sample_attribute_type: Factory(:string_sample_attribute_type), sample_type: Factory(:simple_sample_type))
    @sample_type.sample_attributes << Factory(:sample_attribute, title: 'a_real_number', sample_attribute_type: Factory(:float_sample_attribute_type), required: false, sample_type: @sample_type)
    @sample_type.save!

    #min object needed for all tests related to post except 'test_create' which will load min and max subsequently
    @to_post = load_template("post_min_#{@clz}.json.erb", {project_id: @min_project.id, sample_type_id: @sample_type.id})
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
      title: @sample.title}
  end

end
