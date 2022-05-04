require 'test_helper'

class InvestigationApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def setup
    user_login

    @projects = [Factory(:min_project, title: 'Fred'), Factory(:max_project, title: 'Bert')]

    institution = Factory(:institution)
    @projects.each { |p| current_person.add_to_project_and_institution(p, institution) }
    @publication = Factory(:publication)

    @investigation = Factory(:investigation, contributor: current_person, policy: Factory(:public_policy))
  end

  test 'should not delete investigation with studies' do
    inv = Factory(:max_investigation)
    assert_no_difference('Investigation.count') do
      delete "/#{plural_name}/#{inv.id}.json"
      assert_response :forbidden
      validate_json response.body, '#/components/responses/forbiddenResponse'
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
        delete "/#{plural_name}/#{inv.id}.json"
      end
    end
  end
end
