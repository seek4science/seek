require 'test_helper'

class ProgrammeApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def setup
    admin_login
    @programme_administrator = FactoryBot.create(:person)
    @project = FactoryBot.create(:project)
    @programme = FactoryBot.create(:programme)
  end

  #normal user without admin rights
  test 'user can create programme' do
    a_person = FactoryBot.create(:person)
    user_login(a_person)
    body = api_max_post_body
    assert_difference('Programme.count') do
      post collection_url, params: body, as: :json, headers: { 'Authorization' => write_access_auth }
      assert_response :success
    end
  end

  #programme_admin role access
  test 'programme admin can update' do
    person = FactoryBot.create(:person)
    user_login(person)
    prog = FactoryBot.create(:programme)
    person.is_programme_administrator = true, prog
    disable_authorization_checks { person.save! }
    body = api_max_post_body
    body["data"]["id"] = "#{prog.id}"
    body["data"]['attributes']['title'] = "Updated programme"
    #change_funding_codes_before_CU("min")

    patch member_url(prog), params: body, as: :json, headers: { 'Authorization' => write_access_auth }
    assert_response :success
  end

  test 'programme admin can delete when no projects' do
    person = FactoryBot.create(:person)
    user_login(person)
    prog = FactoryBot.create(:programme)
    person.is_programme_administrator = true, prog
    disable_authorization_checks { person.save! }

    #programme has projects ==> cannot delete
    assert_no_difference('Programme.count', -1) do
      delete member_url(prog), headers: { 'Authorization' => write_access_auth }
      assert_response :forbidden
      assert_nothing_raised { validate_json(response.body, '#/components/schemas/forbiddenResponse') }
    end

    #no projects ==> can delete
    prog.projects = []
    prog.save!
    assert_difference('Programme.count', -1) do
      delete member_url(prog), headers: { 'Authorization' => write_access_auth }
      assert_response :success
    end

    get member_url(prog), headers: { 'Authorization' => read_access_auth }
    assert_response :not_found
    assert_nothing_raised { validate_json(response.body, '#/components/schemas/notFoundResponse') }
  end
end
