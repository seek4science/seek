require 'test_helper'

class ProgrammeCUDTest < ActionDispatch::IntegrationTest
  include WriteApiTestSuite

  def model
    Programme
  end

  def setup
    admin_login
    #min object needed for all tests related to post except 'test_create' which will load min and max subsequently
    p = Factory(:programme)
    @to_post = load_template("post_min_#{singular_name}.json.erb", {title: "post programme"})
  end

  def post_values
      {title: "Post programme", admin_id: @current_person.id}
  end

  def patch_values
    p = Factory(:programme)
    {id: p.id}
  end

  #normal user without admin rights
  def test_user_can_create_programme
    a_person = Factory(:person)
    user_login(a_person)
    assert_difference('Programme.count') do
      post "/programmes.json", params: @to_post
      assert_response :success
    end
  end

  #programme_admin role access
  def test_programme_admin_can_update
    person = Factory(:person)
    user_login(person)
    prog = Factory(:programme)
    person.is_programme_administrator = true, prog
    disable_authorization_checks { person.save! }
    @to_post["data"]["id"] = "#{prog.id}"
    @to_post["data"]['attributes']['title'] = "Updated programme"
    #change_funding_codes_before_CU("min")

    patch "/programmes/#{prog.id}.json", params: @to_post
    assert_response :success
  end

   def test_programme_admin_can_delete_when_no_projects
     person = Factory(:person)
     user_login(person)
     prog = Factory(:programme)
     person.is_programme_administrator = true, prog
     disable_authorization_checks { person.save! }

     #programme has projects ==> cannot delete
     assert_no_difference('Programme.count', -1) do
       delete "/programmes/#{prog.id}.json"
       assert_response :forbidden
       validate_json_against_fragment response.body, '#/definitions/errors'
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
     validate_json_against_fragment response.body, '#/definitions/errors'
   end
end
