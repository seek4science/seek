require 'test_helper'
require 'integration/api_test_helper'

class AssayCUDTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    admin_login
    @clz = 'assay'
    @plural_clz = @clz.pluralize

    @study = Factory(:study, contributor: @current_person)
    @study.title = 'Fred'

    # Populate the assay classes
    Factory(:modelling_assay_class)
    Factory(:experimental_assay_class)
    @assay = Factory(:experimental_assay, contributor: @current_person, policy: Factory(:public_policy))
    hash = {study_id: @study.id, r: ApiTestHelper.method(:render_erb)}
    @to_post = load_template("post_min_#{@clz}.json.erb", hash)
  end

  def create_post_values
      @post_values = {study_id: @study.id,
                      creator_ids: [@current_user.person.id],
                      project_id: Factory(:project).id,
                      r: ApiTestHelper.method(:render_erb) }
  end

  def create_patch_values
    @study = @assay.study
    @patch_values = {id: @assay.id,
                     study_id: @study.id,
                     project_id: Factory(:project).id,
                     creator_ids: [@current_user.person.id],
                     r: ApiTestHelper.method(:render_erb) }
  end

  def populate_extra_relationships(hash = nil)
    extra_relationships = super
    extra_relationships[:investigation] = { data: { id: @study.investigation.id.to_s, type: 'investigations' } }
    extra_relationships
  end

  test 'should not delete assay when not project member' do
    a = Factory(:max_assay)
    person = Factory(:person)
    user_login(person)
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('Assay.count') do
        delete "/#{@plural_clz}/#{a.id}.json"
        assert_response :forbidden
        validate_json_against_fragment response.body, '#/definitions/errors'
      end
    end
  end

  test 'project member can delete' do
    person = Factory(:person)
    user_login(person)
    proj = person.projects.first
    assay = Factory(:experimental_assay,
                    contributor: person,
                    policy: Factory(:policy,
                                    access_type: Policy::NO_ACCESS,
                                    permissions: [Factory(:permission, contributor: proj, access_type: Policy::MANAGING)]))

    assert_difference('Assay.count', -1) do
      delete "/#{@plural_clz}/#{assay.id}.json"
      assert_response :success
    end
  end

  test 'can delete an assay with subscriptions' do
    assay = Factory(:assay, policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    p = Factory(:person)
    Factory(:subscription, person: assay.contributor, subscribable: assay)
    Factory(:subscription, person: p, subscribable: assay)

    user_login(assay.contributor)

    assert_difference('Subscription.count', -2) do
      assert_difference('Assay.count', -1) do
        delete "/#{@plural_clz}/#{assay.id}.json"
        assert_response :success
      end
    end
  end

end
