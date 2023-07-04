require 'test_helper'

class EventApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def populate_extra_attributes(hash)
    h = super
    country = hash.dig('data', 'attributes', 'country')
    if country && country.length == 2
      h[:country] = CountryCodes.country(country)
    end
    h
  end

  def setup
    user_login
    @project = @current_user.person.projects.first
    @publication = FactoryBot.create(:publication, contributor: current_person)
    @presentation = FactoryBot.create(:presentation, contributor: current_person)
    @data_file = FactoryBot.create(:data_file, contributor: current_person)
    @creator = FactoryBot.create(:person)
    @event = FactoryBot.create(:event, policy: FactoryBot.create(:public_policy), contributor: current_person)
  end

  test 'returns sensible error objects' do
    skip 'Errors are a WIP'
    to_post = load_template('post_bad_event.json.erb')

    assert_no_difference(-> { model.count }) do
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
