require 'test_helper'

class ProjectCUDTest < ActionDispatch::IntegrationTest
  include WriteApiTestSuite

  def model
    Project
  end

  def setup
    admin_login
  end

  def post_values
    {title: "Post Project"}
  end

  def patch_values
    p = Factory(:project)
    pr = Factory(:person)
    {id: p.id, person_id: pr.id}
  end

  def test_normal_user_cannot_create_project
    user_login(Factory(:person))
    json = post_json
    assert_no_difference('Project.count') do
      post "/projects.json", params: json
    end
  end

  test 'adds members to project by PATCHing entire project' do
    admin_login

    project = Factory(:project)
    new_institution = Factory(:institution)
    new_person = Factory(:person)
    new_person2 = Factory(:person)
    new_person3 = Factory(:person)

    assert_empty project.people

    get project_path(project, format: :json)

    project_json = JSON.parse(@response.body)

    project_json['data']['attributes']['members'] = [
        { person_id: "#{new_person.id}", institution_id: "#{new_institution.id}" },
        { person_id: "#{new_person2.id}", institution_id: "#{new_institution.id}" },
        { person_id: "#{new_person3.id}", institution_id: "#{new_institution.id}" }
    ]

    patch project_path(project, format: :json), params: project_json.to_json, headers: { 'CONTENT_TYPE' => 'application/vnd.api+json' }
    assert_response :success

    people = project.reload.people.to_a

    assert_includes people, new_person
    assert_includes people, new_person2
    assert_includes people, new_person3
  end

  test 'adds members to project' do
    admin_login

    project = Factory(:project)
    new_institution = Factory(:institution)
    new_person = Factory(:person)
    new_person2 = Factory(:person)
    new_person3 = Factory(:person)

    assert_empty project.people

    to_patch = {
        data: {
            type: "projects",
            id: "#{project.id}",
            attributes: {
                members: [{ person_id: "#{new_person.id}", institution_id: "#{new_institution.id}" },
                          { person_id: "#{new_person2.id}", institution_id: "#{new_institution.id}" },
                          { person_id: "#{new_person3.id}", institution_id: "#{new_institution.id}" }]
            }
        }
    }

    patch project_path(project, format: :json), params: to_patch.to_json, headers: { 'CONTENT_TYPE' => 'application/vnd.api+json' }
    assert_response :success

    people = project.reload.people.to_a

    assert_includes people, new_person
    assert_includes people, new_person2
    assert_includes people, new_person3
  end

  # TO DO: revisit after doing relationships linkage
  # def test_should_not_create_project_with_programme_if_not_programme_admin
  #   person = Factory(:person)
  #   user_login(person)
  #   prog = Factory(:programme)
  #   refute_nil prog
  #   @to_post['data']['attributes']['programme_id'] = prog.id
  #   assert_difference('Project.count') do
  #      post "/projects.json",  @to_post
  #      puts response.body
  #
  #      assert_response :success
  #   end
  #
  #   project = assigns(:project)
  #   assert_empty project.programmes
  #   puts project.programmes
  # end
end
