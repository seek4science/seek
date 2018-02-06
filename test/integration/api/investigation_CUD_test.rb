require 'test_helper'
require 'integration/api_integration_test_helper'

class InvestigationCUDTest < ActionDispatch::IntegrationTest
  include ApiIntegrationTestHelper

  def setup
    admin_login
    @clz = 'investigation'
    @plural_clz = @clz.pluralize

    @min_project = Factory(:min_project)
    @min_project.title = 'Fred'

    @max_project = Factory(:max_project)
    @max_project.title = 'Bert'

    @@template_dir = File.join(Rails.root, 'test', 'fixtures',
                               'files', 'json', 'templates')
    template_file = File.join(@@template_dir, 'post_min_investigation.json.erb')
    template = ERB.new(File.read(template_file))
    namespace = OpenStruct.new({:project_ids => [@min_project.id, @max_project.id], :r => ApiIntegrationTestHelper.method(:render_erb)})
    template_result = template.result(namespace.instance_eval {binding})
    @to_post = JSON.parse(template_result)
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
