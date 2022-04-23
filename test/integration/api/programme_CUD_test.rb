require 'test_helper'

class ProgrammeCUDTest < ActionDispatch::IntegrationTest
  include WriteApiTestSuite

  def model
    Programme
  end

  def setup
    admin_login
    @programme_administrator = Factory(:person)
    @project = Factory(:project)
    @programme = Factory(:programme)
  end

  #normal user without admin rights
  test 'user can create programme' do
    a_person = Factory(:person)
    user_login(a_person)
    body = api_post_body
    assert_difference('Programme.count') do
      post "/programmes.json", params: body, as: :json
      assert_response :success
    end
  end

  #programme_admin role access
  test 'programme admin can update' do
    person = Factory(:person)
    user_login(person)
    prog = Factory(:programme)
    person.is_programme_administrator = true, prog
    disable_authorization_checks { person.save! }
    body = api_post_body
    body["data"]["id"] = "#{prog.id}"
    body["data"]['attributes']['title'] = "Updated programme"
    #change_funding_codes_before_CU("min")

    patch "/programmes/#{prog.id}.json", params: body, as: :json
    assert_response :success
  end

  test 'programme admin can delete when no projects' do
    person = Factory(:person)
    user_login(person)
    prog = Factory(:programme)
    person.is_programme_administrator = true, prog
    disable_authorization_checks { person.save! }

    #programme has projects ==> cannot delete
    assert_no_difference('Programme.count', -1) do
      delete "/programmes/#{prog.id}.json"
      assert_response :forbidden
      validate_json response.body, '#/definitions/errors'
    end

    #no projects ==> can delete
    prog.projects = []
    prog.save!
    assert_difference('Programme.count', -1) do
      delete "/programmes/#{prog.id}.json"
      assert_response :success
    end

    get "/programmes/#{prog.id}.json"
    assert_response :not_found
    validate_json response.body, '#/definitions/errors'
  end
end
