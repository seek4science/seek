require 'test_helper'

class ProjectApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite
  include WriteApiTestSuite

  def setup
    admin_login

    FactoryBot.create(:topics_controlled_vocab) unless SampleControlledVocab::SystemVocabs.topics_controlled_vocab

    @person = FactoryBot.create(:person)
    @project = FactoryBot.create(:project)
    @institution = FactoryBot.create(:institution)
    @programme = FactoryBot.create(:programme)
    @organism = FactoryBot.create(:organism)
  end

  test 'normal user cannot create project' do
    user_login(FactoryBot.create(:person))
    body = api_max_post_body
    assert_no_difference('Project.count') do
      post "/projects.json", params: body, as: :json
    end
  end

  test 'adds members to project by PATCHing entire project' do
    project = FactoryBot.create(:project)
    new_institution = FactoryBot.create(:institution)
    new_person = FactoryBot.create(:person)
    new_person2 = FactoryBot.create(:person)
    new_person3 = FactoryBot.create(:person)

    assert_empty project.people

    get project_path(project, format: :json)

    project_json = JSON.parse(@response.body)

    project_json['data']['attributes']['members'] = [
      { person_id: "#{new_person.id}", institution_id: "#{new_institution.id}" },
      { person_id: "#{new_person2.id}", institution_id: "#{new_institution.id}" },
      { person_id: "#{new_person3.id}", institution_id: "#{new_institution.id}" }
    ]

    patch project_path(project, format: :json), params: project_json, as: :json
    assert_response :success

    people = project.reload.people.to_a

    assert_includes people, new_person
    assert_includes people, new_person2
    assert_includes people, new_person3
  end

  test 'adds members to project' do
    project = FactoryBot.create(:project)
    new_institution = FactoryBot.create(:institution)
    new_person = FactoryBot.create(:person)
    new_person2 = FactoryBot.create(:person)
    new_person3 = FactoryBot.create(:person)

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

    patch project_path(project, format: :json), params: to_patch, as: :json
    assert_response :success

    people = project.reload.people.to_a

    assert_includes people, new_person
    assert_includes people, new_person2
    assert_includes people, new_person3
  end

  # TO DO: revisit after doing relationships linkage
  # test 'should not create project with programme if not programme admin' do
  #   person = FactoryBot.create(:person)
  #   user_login(person)
  #   prog = FactoryBot.create(:programme)
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
