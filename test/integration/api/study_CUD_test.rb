require 'test_helper'
require 'integration/api_test_helper'

class StudyCUDTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    admin_login
    @clz = 'study'
    @plural_clz = @clz.pluralize

    @investigation = Factory(:investigation, contributor: @current_person, projects: [@current_person.projects.first])
    @investigation.title = 'Fred'

    @study = Factory(:study, policy: Factory(:public_policy), contributor: @current_person)
    hash = {investigation_id: @investigation.id,
            r: ApiTestHelper.method(:render_erb) }
    @to_post = load_template("post_min_#{@clz}.json.erb", hash)
  end

  def create_post_values
    @post_values = {investigation_id: @investigation.id,
                    person_id: @current_user.person.id,
                    creator_ids: [@current_user.person.id],
                    r: ApiTestHelper.method(:render_erb) }
  end

  def create_patch_values
    @patch_values = {id: @study.id,
                     investigation_id: @study.investigation.id,
                     person_id: @current_user.person.id,
                     project_id: @study.projects.first.id,
                     creator_ids: [@current_user.person.id],
                     r: ApiTestHelper.method(:render_erb) }
  end

  test 'should not delete a study with assays' do
    study = Factory(:max_study, policy: Factory(:public_policy))
    assert_no_difference('Study.count') do
      delete "/#{@plural_clz}/#{study.id}.json"
      assert_response :forbidden
      validate_json_against_fragment response.body, '#/definitions/errors'
    end
  end

  test 'can delete a study with subscriptions' do
    study = Factory(:study, policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    p = Factory(:person)
    Factory(:subscription, person: study.contributor, subscribable: study)
    Factory(:subscription, person: p, subscribable: study)

    user_login(study.contributor)

    assert_difference('Subscription.count', -2) do
      assert_difference('Study.count', -1) do
        delete "/#{@plural_clz}/#{study.id}.json"
        assert_response :success
      end
    end
  end

  test 'project member can delete' do
    person = Factory(:person)
    user_login(person)
    proj = person.projects.first
    study = Factory(:study,
                    contributor: person,
                    policy: Factory(:policy,
                        access_type: Policy::NO_ACCESS,
                        permissions: [Factory(:permission, contributor: proj, access_type: Policy::MANAGING)]))

    assert_difference('Study.count', -1) do
      delete "/#{@plural_clz}/#{study.id}.json"
      assert_response :success
    end

  end
end
