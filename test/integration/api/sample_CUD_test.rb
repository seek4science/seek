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

    # Needs to be replaced with a new sample type base on post_min_sample.json.erb
    @sample_type = Factory(:simple_sample_type, project_ids: [@min_project.id])
    
    #min object needed for all tests related to post except 'test_create' which will load min and max subsequently
    @to_post = load_template("post_min_#{@clz}.json.erb", {title: "Post Sample", 
     project_id: @min_project.id, sample_type_id: @sample_type.id })
  end

  def create_post_values
      @post_values = {
         sample_type_id: @sample_type.id,
         creator_ids: [@current_user.person.id], 
         project_id: @min_project.id}
  end

  def create_patch_values
    puts "running create_patch_values...."
    @patch_values = {id: @sample.id,
                     sample_type_id: @sample_type.id,
                     project_id: @min_project.id,
                     creator_ids: [@current_user.person.id]
                    }
  end

end
