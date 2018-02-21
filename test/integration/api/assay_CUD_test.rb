require 'test_helper'
require 'integration/api_test_helper'

class AssayCUDTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    admin_login
    @clz = 'assay'
    @plural_clz = @clz.pluralize

    @min_study = Factory(:min_study)
    @min_study.title = 'Fred'

    # Populate the assay classes
    Factory(:modelling_assay_class)
    Factory(:experimental_assay_class)

    template_file = File.join(ApiTestHelper.template_dir, 'post_min_assay.json.erb')
    template = ERB.new(File.read(template_file))
    namespace = OpenStruct.new({:study_id => @min_study.id, :r => ApiTestHelper.method(:render_erb)})
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
    investigation = @min_study.investigation
    investigation_id = investigation.id
    project_id = investigation.projects[0].id

    extra_relationships = {}
    extra_relationships[:submitter] = JSON.parse "{\"data\" : [{\"id\" : \"#{person_id}\", \"type\" : \"people\"}]}"
    extra_relationships[:people] = JSON.parse "{\"data\" : [{\"id\" : \"#{person_id}\", \"type\" : \"people\"}]}"
    extra_relationships[:projects] = JSON.parse "{\"data\" : [{\"id\" : \"#{project_id}\", \"type\" : \"projects\"}]}"
    extra_relationships[:investigation] = JSON.parse "{\"data\" : {\"id\" : \"#{investigation_id}\", \"type\" : \"investigations\"}}"
    extra_relationships.with_indifferent_access
  end
end
