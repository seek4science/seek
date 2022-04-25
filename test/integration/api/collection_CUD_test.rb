require 'test_helper'

class CollectionCUDTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def model
    Collection
  end

  def setup
    admin_login
    @project = @current_user.person.projects.first
    @document1 = Factory(:public_document, contributor: current_person)
    @document2 = Factory(:public_document, contributor: current_person)
    @creator = Factory(:person)
    @collection = Factory(:collection, policy: Factory(:public_policy), contributor: current_person, creators: [@creator])
  end

  test 'returns sensible error objects' do
    skip 'Errors are a WIP'
    to_post = load_template('post_bad_collection.json.erb')

    assert_no_difference("#{singular_name.classify}.count") do
      post "/#{plural_name}.json", params: to_post
      #assert_response :unprocessable_entity
    end

    h = JSON.parse(response.body)

    errors = h["errors"]

    assert errors.any?
    assert_equal "can't be blank", fetch_errors(errors, '/data/relationships/projects')[0]['detail']
    assert_equal "can't be blank", fetch_errors(errors, '/data/attributes/title')[0]['detail']
    policy_errors = fetch_errors(errors, '/data/attributes/policy').map { |p| p['detail'] }
    assert_includes policy_errors, "permissions contributor can't be blank"
    assert_includes policy_errors, "permissions access_type can't be blank"
    refute fetch_errors(errors, '/data/attributes/description').any?
    refute fetch_errors(errors, '/data/attributes/potato').any?
  end
end
