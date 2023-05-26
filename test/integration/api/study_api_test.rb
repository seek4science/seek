require 'test_helper'

class StudyApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def setup
    user_login

    @investigation = FactoryBot.create(:investigation, title: 'Fred', contributor: current_person, projects: [current_person.projects.first])
    @project = @investigation.projects.first
    @publication = FactoryBot.create(:publication)

    @study = FactoryBot.create(:study, policy: FactoryBot.create(:public_policy), contributor: current_person)
  end

  test 'should not delete a study with assays' do
    study = FactoryBot.create(:max_study, policy: FactoryBot.create(:public_policy))
    assert_no_difference('Study.count') do
      delete "/#{plural_name}/#{study.id}.json"
      assert_response :forbidden
      validate_json response.body, '#/components/schemas/forbiddenResponse'
    end
  end

  test 'can delete a study with subscriptions' do
    study = FactoryBot.create(:study, policy: FactoryBot.create(:public_policy, access_type: Policy::VISIBLE))
    p = FactoryBot.create(:person)
    FactoryBot.create(:subscription, person: study.contributor, subscribable: study)
    FactoryBot.create(:subscription, person: p, subscribable: study)

    user_login(study.contributor)

    assert_difference('Subscription.count', -2) do
      assert_difference('Study.count', -1) do
        delete "/#{plural_name}/#{study.id}.json"
        assert_response :success
      end
    end
  end

  test 'project member can delete' do
    person = FactoryBot.create(:person)
    user_login(person)
    proj = person.projects.first
    study = FactoryBot.create(:study,
                    contributor: person,
                    policy: FactoryBot.create(:policy,
                                    access_type: Policy::NO_ACCESS,
                                    permissions: [FactoryBot.create(:permission, contributor: proj, access_type: Policy::MANAGING)]))

    assert_difference('Study.count', -1) do
      delete "/#{plural_name}/#{study.id}.json"
      assert_response :success
    end
  end
end
