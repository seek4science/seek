require 'test_helper'
require 'integration/api_integration_test_helper'

class AssayCUDTest < ActionDispatch::IntegrationTest
  include ApiIntegrationTestHelper

  def setup
    admin_login
    @clz = 'assay'
    @plural_clz = @clz.pluralize

    @min_study = Factory(:min_study)
    @min_study.title = 'Fred'

    @@template_dir = File.join(Rails.root, 'test', 'fixtures',
                               'files', 'json', 'templates')
    template_file = File.join(@@template_dir, 'post_min_assay.json.erb')
    template = ERB.new(File.read(template_file))
    namespace = OpenStruct.new({:study_id => @min_study.id, :r => ApiIntegrationTestHelper.method(:render_erb)})
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

  def tweak_response h
    h['data']['attributes']['assay_class'].delete('title')
    h['data']['attributes']['assay_class'].delete('description')
    h['data']['attributes']['assay_type'].delete('label')
    h['data']['attributes']['technology_type'].delete('label')
  end

end
