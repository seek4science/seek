require 'test_helper'

class AssayApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def setup
    user_login

    @study = FactoryBot.create(:study, contributor: current_person)
    @study.title = 'Fred'

    # Populate the assay classes
    FactoryBot.create(:modelling_assay_class)
    FactoryBot.create(:experimental_assay_class)
    @assay = FactoryBot.create(:experimental_assay, contributor: current_person, policy: FactoryBot.create(:public_policy))
    @study = @assay.study
    @project = @assay.projects.first
    @publication = FactoryBot.create(:publication)
    @organism = FactoryBot.create(:organism)
    @sop = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy))
    @data_file = FactoryBot.create(:data_file, policy: FactoryBot.create(:public_policy))
    @document = FactoryBot.create(:document, policy: FactoryBot.create(:public_policy))
    @sample = FactoryBot.create(:sample, policy: FactoryBot.create(:public_policy))
  end

  test 'should not delete assay when not project member' do
    a = FactoryBot.create(:max_assay)
    person = FactoryBot.create(:person)
    user_login(person)
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('Assay.count') do
        delete "/#{plural_name}/#{a.id}.json"
        assert_response :forbidden
        validate_json response.body, '#/components/schemas/forbiddenResponse'
      end
    end
  end

  test 'project member can delete' do
    person = FactoryBot.create(:person)
    user_login(person)
    proj = person.projects.first
    assay = FactoryBot.create(:experimental_assay,
                    contributor: person,
                    policy: FactoryBot.create(:policy,
                                    access_type: Policy::NO_ACCESS,
                                    permissions: [FactoryBot.create(:permission, contributor: proj, access_type: Policy::MANAGING)]))

    assert_difference('Assay.count', -1) do
      delete "/#{plural_name}/#{assay.id}.json"
      assert_response :success
    end
  end

  test 'can delete an assay with subscriptions' do
    assay = FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy, access_type: Policy::VISIBLE))
    p = FactoryBot.create(:person)
    FactoryBot.create(:subscription, person: assay.contributor, subscribable: assay)
    FactoryBot.create(:subscription, person: p, subscribable: assay)

    user_login(assay.contributor)

    assert_difference('Subscription.count', -2) do
      assert_difference('Assay.count', -1) do
        delete "/#{plural_name}/#{assay.id}.json"
        assert_response :success
      end
    end
  end
end
