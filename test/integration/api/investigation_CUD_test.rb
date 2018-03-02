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
    @to_post = load_template("post_min_#{@clz}.json.erb", hash)
    @to_patch = load_template("patch_#{@clz}.json.erb", {id: inv.id})
  end

  def create_post_values
      @post_values = {project_ids:  [@min_project.id, @max_project.id],
                         creator_ids: [@current_user.person.id],
                         r: ApiTestHelper.method(:render_erb) }
  end

  def populate_extra_relationships
    person_id = @current_user.person.id
    extra_relationships = {}
    extra_relationships[:submitter] = JSON.parse "{\"data\" : [{\"id\" : \"#{person_id}\", \"type\" : \"people\"}]}"
    extra_relationships[:people] = JSON.parse "{\"data\" : [{\"id\" : \"#{person_id}\", \"type\" : \"people\"}]}"
    extra_relationships.with_indifferent_access
  end

  test 'should not delete investigation with studies' do
    inv = Factory(:max_investigation)
    assert_no_difference('Investigation.count') do
      delete "/#{@plural_clz}/#{inv.id}.json"
      assert_response :forbidden
    end
  end

  test 'can delete an investigation with subscriptions' do
    inv = Factory(:investigation, policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    p = Factory(:person)
    Factory(:subscription, person: inv.contributor, subscribable: inv)
    Factory(:subscription, person: p, subscribable: inv)

    user_login(inv.contributor)

    assert_difference('Subscription.count', -2) do
      assert_difference('Investigation.count', -1) do
        delete "/#{@plural_clz}/#{inv.id}.json"
      end
    end
  end
end
