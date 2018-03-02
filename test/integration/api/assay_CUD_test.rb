require 'test_helper'
require 'integration/api_test_helper'

class AssayCUDTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    admin_login
    @clz = 'assay'
    @plural_clz = @clz.pluralize

    @study = Factory(:study)
    @study.title = 'Fred'

    # Populate the assay classes
    Factory(:modelling_assay_class)
    Factory(:experimental_assay_class)
    assay = Factory(:experimental_assay, policy: Factory(:public_policy))
    assay.contributor = @current_user.person
    assay.save

    hash = {study_id: @study.id, r: ApiTestHelper.method(:render_erb)}
    @to_post = load_template("post_min_#{@clz}.json.erb", hash)
    @to_patch = load_template("patch_#{@clz}.json.erb", {id: assay.id})
  end

  def create_post_values
      @post_values[m] = {study_id: @study.id,
                         project_id: Factory(:project).id,
                         creator_ids: [@current_user.person.id],
                         r: ApiTestHelper.method(:render_erb) }
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
