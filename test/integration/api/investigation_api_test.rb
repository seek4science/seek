require 'test_helper'

class InvestigationApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def setup
    user_login

    @projects = [FactoryBot.create(:min_project, title: 'Fred'), FactoryBot.create(:max_project, title: 'Bert')]

    institution = FactoryBot.create(:institution)
    @projects.each { |p| current_person.add_to_project_and_institution(p, institution) }
    @publication = FactoryBot.create(:publication)

    @investigation = FactoryBot.create(:investigation, contributor: current_person, policy: FactoryBot.create(:public_policy))
  end

  test 'should not delete investigation with studies' do
    inv = FactoryBot.create(:max_investigation)
    assert_no_difference('Investigation.count') do
      delete "/#{plural_name}/#{inv.id}.json"
      assert_response :forbidden
      validate_json response.body, '#/components/schemas/forbiddenResponse'
    end
  end

  test 'can delete an investigation with subscriptions' do
    inv = FactoryBot.create(:investigation, policy: FactoryBot.create(:public_policy, access_type: Policy::VISIBLE))
    p = FactoryBot.create(:person)
    FactoryBot.create(:subscription, person: inv.contributor, subscribable: inv)
    FactoryBot.create(:subscription, person: p, subscribable: inv)

    user_login(inv.contributor)

    assert_difference('Subscription.count', -2) do
      assert_difference('Investigation.count', -1) do
        delete "/#{plural_name}/#{inv.id}.json"
      end
    end
  end

  test 'extended metadata not shown if disabled' do
    person = FactoryBot.create(:person)

    emt = FactoryBot.create(:simple_study_extended_metadata_type)
    investigation = FactoryBot.create(:investigation, extended_metadata: ExtendedMetadata.new(extended_metadata_type: emt, data: { name: 'John', age: 12 }), contributor: person)
    user_login(person)

    # first check it's present
    get "/#{plural_name}/#{investigation.id}.json"
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal emt.id.to_s, json.dig('data','attributes','extended_attributes','extended_metadata_type_id')

    # now without
    emt.update_column(:enabled, false)
    get "/#{plural_name}/#{investigation.id}.json"
    assert_response :success
    json = JSON.parse(response.body)
    refute_nil attributes = json.dig('data','attributes')
    refute attributes.key?('extended_attributes')
  end
end
