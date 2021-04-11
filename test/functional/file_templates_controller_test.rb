require 'test_helper'
require 'minitest/mock'

class FileTemplatesControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases
  include SharingFormTestHelper
  include MockHelper
  include HtmlHelper
  include GeneralAuthorizationTestCases

  def test_json_content
    login_as(Factory(:user))
    super
  end

  def rest_api_test_object
    @object = Factory(:public_file_template)
  end

  def edit_max_object(file_template)
    add_tags_to_test_object(file_template)
    add_creator_to_test_object(file_template)
  end

  test 'should return 406 when requesting RDF' do
    login_as(Factory(:user))
    ft = Factory :file_template, contributor: User.current_user.person
    assert ft.can_view?

    get :show, params: { id: ft, format: :rdf }

    assert_response :not_acceptable
  end

  test 'should get index' do
    FactoryGirl.create_list(:public_file_template, 3)

    get :index

    assert_response :success
    assert assigns(:file_templates).any?
  end

  test "shouldn't show hidden items in index" do
    visible_ft = Factory(:public_file_template)
    hidden_ft = Factory(:private_file_template)

    get :index, params: { page: 'all' }

    assert_response :success
    assert_includes assigns(:file_templates), visible_ft
    assert_not_includes assigns(:file_templates), hidden_ft
  end

  test 'should show' do
    visible_ft = Factory(:public_file_template)

    get :show, params: { id: visible_ft }

    assert_response :success
  end

  test 'should not show hidden file template' do
    hidden_ft = Factory(:private_file_template)

    get :show, params: { id: hidden_ft }

    assert_response :forbidden
  end

  test 'should get new' do
    login_as(Factory(:person))

    get :new
    assert_response :success
    assert_select 'h1', text: "New #{I18n.t('file_template')}"
  end

  test 'should get edit' do
    login_as(Factory(:person))

    get :new
    assert_response :success
    assert_select 'h1', text: "New #{I18n.t('file_template')}"
  end

  test 'should create file template' do
    person = Factory(:person)
    login_as(person)

    assert_difference('ActivityLog.count') do
      assert_difference('FileTemplate.count') do
        assert_difference('FileTemplate::Version.count') do
          assert_difference('ContentBlob.count') do
            post :create, params: { file_template: { title: 'File Template', project_ids: [person.projects.first.id]}, content_blobs: [valid_content_blob], policy_attributes: valid_sharing }
          end
        end
      end
    end

    assert_redirected_to file_template_path(assigns(:file_template))
  end

  test 'should create file template version' do
    ft = Factory(:file_template)
    login_as(ft.contributor)

    assert_difference('ActivityLog.count') do
      assert_no_difference('FileTemplate.count') do
        assert_difference('FileTemplate::Version.count') do
          assert_difference('ContentBlob.count') do
            post :create_version, params: { id: ft.id, content_blobs: [{ data: fixture_file_upload('files/little_file.txt') }], revision_comments: 'new version!' }
          end
        end
      end
    end

    assert_redirected_to file_template_path(assigns(:file_template))
    assert_equal 2, assigns(:file_template).version
    assert_equal 2, assigns(:file_template).versions.count
    assert_equal 'new version!', assigns(:file_template).latest_version.revision_comments
  end

  test 'should update file template' do
    person = Factory(:person)
    ft = Factory(:file_template, contributor: person)
    login_as(person)

    assert_difference('ActivityLog.count') do
      put :update, params: { id: ft.id, file_template: { title: 'Different title', project_ids: [person.projects.first.id]} }
    end

    assert_redirected_to file_template_path(assigns(:file_template))
    assert_equal 'Different title', assigns(:file_template).title
  end

  test 'should destroy file template' do
    person = Factory(:person)
    document = Factory(:file_template, contributor: person)
    login_as(person)

    assert_difference('FileTemplate.count', -1) do
      assert_no_difference('ContentBlob.count') do
        delete :destroy, params: { id: document }
      end
    end

    assert_redirected_to file_templates_path
  end

  test 'should be able to view pdf content' do
    ft = Factory(:public_file_template)
    assert ft.content_blob.is_content_viewable?
    get :show, params: { id: ft.id }
    assert_response :success
    assert_select 'a', text: /View content/, count: 1
  end

  test "people file_templates through nested routing" do
    assert_routing 'people/2/file_templates', controller: 'file_templates', action: 'index', person_id: '2'
    person = Factory(:person)
    login_as(person)
    ft = Factory(:file_template,contributor:person)
    ft2 = Factory(:file_template, policy: Factory(:public_policy),contributor:Factory(:person))


    get :index, params: { person_id: person.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]',file_template_path(ft), text: ft.title
      assert_select 'a[href=?]', file_template_path(ft2), text: ft2.title, count: 0
    end
  end

  test "project file templates through nested routing" do
    assert_routing 'projects/2/file_templates', controller: 'file_templates', action: 'index', project_id: '2'
    person = Factory(:person)
    login_as(person)
    ft = Factory(:file_template,contributor:person)
    ft2 = Factory(:file_template,policy: Factory(:public_policy),contributor:Factory(:person))


    get :index, params: { project_id: person.projects.first.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', file_template_path(ft), text: ft.title
      assert_select 'a[href=?]', file_template_path(ft2), text: ft2.title, count: 0
    end
  end

  test 'manage menu item appears according to permission' do
    check_manage_edit_menu_for_type('file_template')
  end

  test 'can access manage page with manage rights' do
    person = Factory(:person)
    ft = Factory(:file_template, contributor:person)
    login_as(person)
    assert ft.can_manage?
    get :manage, params: {id: ft}
    assert_response :success

    # check the project form exists
    assert_select 'div#add_projects_form', count:1

    # check sharing form exists
    assert_select 'div#sharing_form', count:1

    # should be a temporary sharing link
    assert_select 'div#temporary_links', count:1

    assert_select 'div#author_form', count:1
  end

  test 'cannot access manage page with edit rights' do
    person = Factory(:person)
    ft = Factory(:file_template, policy:Factory(:private_policy, permissions:[Factory(:permission, contributor:person, access_type:Policy::EDITING)]))
    login_as(person)
    assert ft.can_edit?
    refute ft.can_manage?
    get :manage, params: {id: ft}
    assert_redirected_to ft
    refute_nil flash[:error]
  end

  test 'create with no creators' do
    person = Factory(:person)
    login_as(person)
    ft = {title: 'FileTemplate', project_ids: [person.projects.first.id], creator_ids: []}
    assert_difference('FileTemplate.count') do
      post :create, params: {file_template: ft, content_blobs: [{data: file_for_upload}], policy_attributes: {access_type: Policy::VISIBLE}}
    end

    ft = assigns(:file_template)
    assert_empty ft.creators
  end

  test 'update with no creators' do
    person = Factory(:person)
    creators = [Factory(:person), Factory(:person)]
    ft = Factory(:file_template, contributor: person, creators:creators)

    assert_equal creators.sort, ft.creators.sort
    login_as(person)

    assert ft.can_manage?


    patch :manage_update,
          params: {id: ft,
                   file_template: {
                       title:'changed title',
                       creator_ids:[""]
                   }
          }

    assert_redirected_to file_template_path(ft = assigns(:file_template))
    assert_equal 'changed title', ft.title
    assert_empty ft.creators
  end

  test 'manage_update' do
    proj1=Factory(:project)
    proj2=Factory(:project)
    person = Factory(:person,project:proj1)
    other_person = Factory(:person)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!
    other_creator = Factory(:person,project:proj1)
    other_creator.add_to_project_and_institution(proj2,other_creator.institutions.first)
    other_creator.save!

    ft = Factory(:file_template, contributor:person, projects:[proj1], policy:Factory(:private_policy))

    login_as(person)
    assert ft.can_manage?

    patch :manage_update, params: {id: ft,
                                   file_template: {
                                       creator_ids: [other_creator.id],
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    assert_redirected_to ft

    ft.reload
    assert_equal [proj1,proj2],ft.projects.sort_by(&:id)
    assert_equal [other_creator],ft.creators
    assert_equal Policy::VISIBLE,ft.policy.access_type
    assert_equal 1,ft.policy.permissions.count
    assert_equal other_person,ft.policy.permissions.first.contributor
    assert_equal Policy::MANAGING,ft.policy.permissions.first.access_type

  end

  test 'manage_update fails without manage rights' do
    proj1=Factory(:project)
    proj2=Factory(:project)
    person = Factory(:person, project:proj1)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!

    other_person = Factory(:person)

    other_creator = Factory(:person,project:proj1)
    other_creator.add_to_project_and_institution(proj2,other_creator.institutions.first)
    other_creator.save!

    ft = Factory(:file_template, projects:[proj1], policy:Factory(:private_policy,
                                                         permissions:[Factory(:permission,contributor:person, access_type:Policy::EDITING)]))

    login_as(person)
    refute ft.can_manage?
    assert ft.can_edit?

    assert_equal [proj1],ft.projects
    assert_empty ft.creators

    patch :manage_update, params: {id: ft,
                                   file_template: {
                                       creator_ids: [other_creator.id],
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    refute_nil flash[:error]

    ft.reload
    assert_equal [proj1],ft.projects
    assert_empty ft.creators
    assert_equal Policy::PRIVATE,ft.policy.access_type
    assert_equal 1,ft.policy.permissions.count
    assert_equal person,ft.policy.permissions.first.contributor
    assert_equal Policy::EDITING,ft.policy.permissions.first.access_type
  end

  test 'numeric pagination' do
    FactoryGirl.create_list(:public_file_template, 20)

    with_config_value(:results_per_page_default, 5) do
      get :index

      assert_equal 5, assigns(:file_templates).length
      assert_equal '1', assigns(:page)
      assert_equal 5, assigns(:per_page)
      assert_select '.pagination-container a', href: file_templates_path(page: 2), text: /Next/
      assert_select '.pagination-container a', href: file_templates_path(page: 2), text: /2/
      assert_select '.pagination-container a', href: file_templates_path(page: 3), text: /3/

      get :index, params: { page: 2 }

      assert_equal 5, assigns(:file_templates).length
      assert_equal '2', assigns(:page)
      assert_select '.pagination-container a', href: file_templates_path(page: 3), text: /Next/
      assert_select '.pagination-container a', href: file_templates_path(page: 1), text: /Previous/
      assert_select '.pagination-container a', href: file_templates_path(page: 1), text: /1/
      assert_select '.pagination-container a', href: file_templates_path(page: 3), text: /3/
    end
  end

  def valid_content_blob
    { data: fixture_file_upload('files/a_pdf_file.pdf'), data_url: '' }
  end

end
