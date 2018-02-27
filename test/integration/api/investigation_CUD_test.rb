require 'test_helper'
require 'integration/api_test_helper'

class InvestigationCUDTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    admin_login
    @clz = 'investigation'
    @plural_clz = @clz.pluralize

    @min_project = Factory(:min_project)
    @min_project.title = 'Fred'

    @max_project = Factory(:max_project)
    @max_project.title = 'Bert'

    inv = Factory(:investigation, policy: Factory(:public_policy))
    inv.contributor = @current_user.person
    inv.save

    hash = {project_ids: [@min_project.id, @max_project.id],
            r: ApiTestHelper.method(:render_erb) }
    puts "setup hash #{hash}"
    @to_post = load_template("post_min_#{@clz}.json.erb", hash)
    puts "setup post #{@to_post}"
    @to_patch = load_template("patch_#{@clz}.json.erb", {id: inv.id})
  end

  def create_post_values
    @post_values = {}
    ['min','max'].each do |m|
      @post_values[m] = {project_ids:  [@min_project.id, @max_project.id],
                         r: ApiTestHelper.method(:render_erb) }
    end
    puts "created post values"
  end

  def populate_extra_attributes
    extra_attributes = {}
    extra_attributes[:policy] = BaseSerializer::convert_policy Factory(:private_policy)
    extra_attributes.with_indifferent_access

  end

  def populate_extra_relationships
    person_id = @current_user.person.id
    extra_relationships = {}
    extra_relationships[:submitter] = JSON.parse "{\"data\" : [{\"id\" : \"#{person_id}\", \"type\" : \"people\"}]}"
    extra_relationships[:people] = JSON.parse "{\"data\" : [{\"id\" : \"#{person_id}\", \"type\" : \"people\"}]}"
    extra_relationships.with_indifferent_access

  end
end
