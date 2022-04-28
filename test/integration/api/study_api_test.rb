require 'test_helper'

class StudyApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def setup
    user_login

    @investigation = Factory(:investigation, title: 'Fred', contributor: current_person, projects: [current_person.projects.first])
    @project = @investigation.projects.first
    @publication = Factory(:publication)

    @study = Factory(:study, policy: Factory(:public_policy), contributor: current_person)
  end

  test 'should not delete a study with assays' do
    study = Factory(:max_study, policy: Factory(:public_policy))
    assert_no_difference('Study.count') do
      delete "/#{plural_name}/#{study.id}.json"
      assert_response :forbidden
      validate_json response.body, '#/components/schemas/errors'
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
        delete "/#{plural_name}/#{study.id}.json"
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
      delete "/#{plural_name}/#{study.id}.json"
      assert_response :success
    end
  end
end
