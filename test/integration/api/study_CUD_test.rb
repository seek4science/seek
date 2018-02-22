require 'test_helper'
require 'integration/api_test_helper'

class StudyCUDTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    admin_login
    @clz = 'study'
    @plural_clz = @clz.pluralize

    @min_investigation = Factory(:min_investigation)
    @min_investigation.title = 'Fred'

    study = Factory(:study, policy: Factory(:public_policy))
    study.contributor = @current_user.person
    study.save

    template_file = File.join(ApiTestHelper.template_dir, 'post_min_study.json.erb')
    template = ERB.new(File.read(template_file))
    namespace = OpenStruct.new({:investigation_id => @min_investigation.id, :r => ApiTestHelper.method(:render_erb)})
    template_result = template.result(namespace.instance_eval {binding})
    @to_post = JSON.parse(template_result)

    @to_patch = load_template("patch_#{@clz}.json.erb", {id: study.id})
  end

  def populate_extra_attributes
    extra_attributes = {}
    extra_attributes[:policy] = BaseSerializer::convert_policy Factory(:private_policy)
    extra_attributes.with_indifferent_access
  end

  def populate_extra_relationships
    person_id = @current_user.person.id
    project_id = @min_investigation.projects[0].id
    extra_relationships = {}
    extra_relationships[:submitter] = JSON.parse "{\"data\" : [{\"id\" : \"#{person_id}\", \"type\" : \"people\"}]}"
    extra_relationships[:people] = JSON.parse "{\"data\" : [{\"id\" : \"#{person_id}\", \"type\" : \"people\"}]}"
    extra_relationships[:projects] = JSON.parse "{\"data\" : [{\"id\" : \"#{project_id}\", \"type\" : \"projects\"}]}"
    extra_relationships.with_indifferent_access

  end
end
