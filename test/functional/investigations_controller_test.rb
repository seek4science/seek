require 'test_helper'

class InvestigationsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases
  include SharingFormTestHelper
  include RdfTestCases
  include GeneralAuthorizationTestCases

  def setup
    login_as(:quentin)
  end

  def rest_api_test_object
    @object = Factory(:investigation, policy: Factory(:public_policy))
  end

  def test_title
    get :index
    assert_select 'title', text: I18n.t('investigation').pluralize, count: 1
  end

  test 'should show index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:investigations)
  end

  test 'should respond to ro for research object' do
    inv = Factory :investigation, contributor: User.current_user.person
    get :show, params: { id: inv, format: 'ro' }
    assert_response :success
    assert_equal "attachment; filename=\"investigation-#{inv.id}.ro.zip\"", @response.header['Content-Disposition']
    assert_equal 'application/vnd.wf4ever.robundle+zip', @response.header['Content-Type']
    assert @response.header['Content-Length'].to_i > 10
  end

  test 'should show aggregated publications linked to assay' do
    person = Factory(:person)
    study=nil
    User.with_current_user(person.user) do
      assay1 = Factory :assay, policy: Factory(:public_policy),contributor:person
      assay2 = Factory :assay, policy: Factory(:public_policy),contributor:person

      pub1 = Factory :publication, title: 'pub 1',contributor:person, publication_type: Factory(:journal)
      pub2 = Factory :publication, title: 'pub 2',contributor:person, publication_type: Factory(:journal)
      pub3 = Factory :publication, title: 'pub 3',contributor:person, publication_type: Factory(:journal)
      Factory :relationship, subject: assay1, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub1
      Factory :relationship, subject: assay1, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub2

      Factory :relationship, subject: assay2, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub2
      Factory :relationship, subject: assay2, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub3

      investigation = Factory(:investigation, policy: Factory(:public_policy),contributor:person)
      study = Factory(:study, policy: Factory(:public_policy),
                      assays: [assay1, assay2],
                      investigation: investigation,contributor:person)
    end


    get :show, params: { id: study.investigation.id }
    assert_response :success

    assert_select 'ul.nav-pills' do
      assert_select 'a', text: 'Publications (3)', count: 1
    end
  end

  test 'should show draggable icon in index' do
    get :index
    assert_response :success
    investigations = assigns(:investigations)
    first_investigations = investigations.first
    assert_not_nil first_investigations
    assert_select 'a[data-favourite-url=?]', add_favourites_path(resource_id: first_investigations.id,
                                                                 resource_type: first_investigations.class.name)
  end

  test 'should show item' do
    get :show, params: { id: investigations(:metabolomics_investigation) }
    assert_response :success
    assert_not_nil assigns(:investigation)
  end

  test 'should show new' do
    get :new
    assert_response :success
    assert assigns(:investigation)
  end

  test "logged out user can't see new" do
    logout
    get :new
    assert_redirected_to investigations_path
  end

  test 'should show edit' do
    get :edit, params: { id: investigations(:metabolomics_investigation) }
    assert_response :success
    assert assigns(:investigation)
  end

  test "shouldn't show edit for unauthorized user" do
    i = Factory(:investigation, policy: Factory(:private_policy))
    login_as(Factory(:user))
    get :edit, params: { id: i }
    assert_redirected_to investigation_path(i)
    assert flash[:error]
  end

  test 'should update' do
    i = investigations(:metabolomics_investigation)
    put :update, params: { id: i.id, investigation: { title: 'test' } }

    assert_redirected_to investigation_path(i)
    assert assigns(:investigation)
    assert_equal 'test', assigns(:investigation).title
  end

  test 'should create' do
    login_as(Factory :user)
    assert_difference('Investigation.count') do
      put :create, params: { investigation: Factory.attributes_for(:investigation, project_ids: [User.current_user.person.projects.first.id]), sharing: valid_sharing }
    end
    assert assigns(:investigation)
    assert !assigns(:investigation).new_record?
  end

  test 'should create an investigations and associate it with a publication without publication type' do
    user = Factory(:user)
    project = user.person.projects.first
    p = Factory(:publication)
    p.publication_type_id = nil
    disable_authorization_checks { p.save! }
    login_as(user)
    assert_difference('Investigation.count',1) do
      post :create, params: { investigation: { title: 'investigation with publication', project_ids: [project.id.to_s],publication_ids: [p.id.to_s] } }
    end
    investigation = assigns(:investigation)
    assert_nil p.publication_type_id
    assert p.investigations.include?(investigation)
    assert investigation.publications.include?(p)
  end

  test 'should create with policy' do
    user = Factory(:user)
    project = user.person.projects.first
    another_project = Factory(:project)
    login_as(user)
    assert_difference('Investigation.count') do
      post :create, params: { investigation: Factory.attributes_for(:investigation, project_ids: [User.current_user.person.projects.first.id]), policy_attributes: { access_type: Policy::ACCESSIBLE,
                                permissions_attributes: project_permissions([project, another_project], Policy::EDITING) } }
    end

    investigation = assigns(:investigation)
    assert investigation
    projects_with_permissions = investigation.policy.permissions.map(&:contributor)
    assert_includes projects_with_permissions, project
    assert_includes projects_with_permissions, another_project
    assert_equal 2, investigation.policy.permissions.count
    assert_equal Policy::EDITING, investigation.policy.permissions[0].access_type
    assert_equal Policy::EDITING, investigation.policy.permissions[1].access_type
  end

  test 'should fall back to form when no title validation fails' do
    login_as(Factory :user)

    assert_no_difference('Investigation.count') do
      post :create, params: { investigation: { project_ids: [User.current_user.person.projects.first.id] } }
    end
    assert_template :new

    assert assigns(:investigation)
    assert !assigns(:investigation).valid?
    assert !assigns(:investigation).errors.empty?
  end

  test 'should fall back to form when no projects validation fails' do
    login_as(Factory :user)

    assert_no_difference('Investigation.count') do
      post :create, params: { investigation: { title: 'investigation with no projects' } }
    end
    assert_template :new

    assert assigns(:investigation)
    assert !assigns(:investigation).valid?
    assert !assigns(:investigation).errors.empty?
  end

  test 'no edit button in show for unauthorized user' do
    login_as(Factory(:user))
    get :show, params: { id: Factory(:investigation, policy: Factory(:private_policy)) }
    assert_select 'a', text: /Edit #{I18n.t('investigation')}/i, count: 0
  end

  test 'edit button in show for authorized user' do
    get :show, params: { id: investigations(:metabolomics_investigation) }
    assert_select 'a[href=?]', edit_investigation_path(investigations(:metabolomics_investigation)), text: /Edit #{I18n.t('investigation')}/i, count: 1
  end

  test 'no add study button for person that cannot edit' do
    inv = Factory(:investigation)
    login_as(Factory(:user))

    assert !inv.can_edit?

    get :show, params: { id: inv }
    assert_select 'a', text: /Add a #{I18n.t('study')}/i, count: 0
  end

  test "unauthorized user can't edit investigation" do
    i = Factory(:investigation, policy: Factory(:private_policy))
    login_as(Factory(:user))
    get :edit, params: { id: i }
    assert_redirected_to investigation_path(i)
    assert flash[:error]
  end

  test "unauthorized users can't update investigation" do
    i = Factory(:investigation, policy: Factory(:private_policy))
    login_as(Factory(:user))
    put :update, params: { id: i.id, investigation: { title: 'test' } }

    assert_redirected_to investigation_path(i)
  end

  test 'should destroy investigation' do
    i = Factory(:investigation, contributor: User.current_user.person)
    assert_difference('Investigation.count', -1) do
      delete :destroy, params: { id: i.id }
    end
    assert !flash[:error]
    assert_redirected_to investigations_path
  end

  test 'unauthorized user should not destroy investigation' do
    i = Factory(:investigation, policy: Factory(:private_policy))
    login_as(Factory(:user))
    assert_no_difference('Investigation.count') do
      delete :destroy, params: { id: i.id }
    end
    assert flash[:error]
    assert_redirected_to i
  end

  test 'should not destroy investigation with a study' do
    investigation = investigations(:metabolomics_investigation)
    assert_no_difference('Investigation.count') do
      delete :destroy, params: { id: investigation.id }
    end
    assert flash[:error]
    assert_redirected_to investigation
  end

  test 'option to delete investigation without study' do
    get :show, params: { id: Factory(:investigation, contributor: User.current_user.person).id }
    assert_select 'a', text: /Delete #{I18n.t('investigation')}/i, count: 1
  end

  test 'no option to delete investigation with study' do
    get :show, params: { id: investigations(:metabolomics_investigation).id }
    assert_select 'a', text: /Delete #{I18n.t('investigation')}/i, count: 0
  end

  test 'no option to delete investigation when unauthorized' do
    i = Factory :investigation, policy: Factory(:private_policy)
    login_as Factory(:user)
    get :show, params: { id: i.id }
    assert_select 'a', text: /Delete #{I18n.t('investigation')}/i, count: 0
  end

  test 'should_add_nofollow_to_links_in_show_page' do
    get :show, params: { id: investigations(:investigation_with_links_in_description) }
    assert_select 'div#description' do
      assert_select 'a[rel="nofollow"]'
    end
  end

  test 'object based on existing one' do
    inv = Factory :investigation, title: 'the inv', policy: Factory(:public_policy)
    get :new_object_based_on_existing_one, params: { id: inv.id }
    assert_response :success
    assert_select '#investigation_title[value=?]', 'the inv'
  end

  test 'object based on existing one when unauthorised' do
    inv = Factory :investigation, title: 'the inv', policy: Factory(:private_policy), contributor: Factory(:person)
    refute inv.can_view?
    get :new_object_based_on_existing_one, params: { id: inv.id }
    assert_response :forbidden
  end

  test 'new object based on existing one when can view but not logged in' do
    inv = Factory(:investigation, policy: Factory(:public_policy))
    logout
    assert inv.can_view?
    get :new_object_based_on_existing_one, params: { id: inv.id }
    assert_redirected_to inv
    refute_nil flash[:error]
  end

  test 'filtering by project' do
    project = projects(:sysmo_project)
    get :index, params: { filter: { project: project.id } }
    assert_response :success
  end

  test 'should show the contributor avatar' do
    investigation = Factory(:investigation, policy: Factory(:public_policy))
    get :show, params: { id: investigation }
    assert_response :success
    assert_select '.author-list-item' do
      assert_select 'a[href=?]', person_path(investigation.contributing_user.person) do
        assert_select 'img'
      end
    end
  end

  test 'should add creators' do
    investigation = Factory(:investigation, policy: Factory(:public_policy))
    creator = Factory(:person)
    assert investigation.creators.empty?

    put :update, params: { id: investigation.id, investigation: { title: investigation.title, creator_ids: [creator.id] } }
    assert_redirected_to investigation_path(investigation)

    assert investigation.creators.include?(creator)
  end

  test 'should not have creators association box when editing' do
    investigation = Factory(:investigation, policy: Factory(:public_policy))

    get :edit, params: { id: investigation.id }
    assert_response :success
    assert_select '#creators_list', count:0
  end

  test 'should show creators' do
    investigation = Factory(:investigation, policy: Factory(:public_policy))
    creator = Factory(:person)
    investigation.creators = [creator]
    investigation.save
    investigation.reload
    assert investigation.creators.include?(creator)

    get :show, params: { id: investigation.id }
    assert_response :success
    assert_select 'li.author-list-item a[href=?]', "/people/#{creator.id}"
  end

  test 'should show other creators' do
    investigation = Factory(:investigation, policy: Factory(:public_policy))
    other_creators = 'john smith'
    investigation.other_creators = other_creators
    investigation.save
    investigation.reload

    get :show, params: { id: investigation.id }
    assert_response :success
    assert_select 'li.author-list-item', text: 'john smith'
  end

  test 'programme investigations through nested routing' do
    assert_routing 'programmes/2/investigations', controller: 'investigations', action: 'index', programme_id: '2'
    programme = Factory(:programme)
    person = Factory(:person,project:programme.projects.first)
    investigation = Factory(:investigation, projects: programme.projects, policy: Factory(:public_policy),contributor:person)
    investigation2 = Factory(:investigation, policy: Factory(:public_policy))

    get :index, params: { programme_id: programme.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', investigation_path(investigation), text: investigation.title
      assert_select 'a[href=?]', investigation_path(investigation2), text: investigation2.title, count: 0
    end
  end

  test 'send publish approval request' do
    gatekeeper = Factory(:asset_gatekeeper)
    investigation = Factory(:investigation, projects: [gatekeeper.projects.first], policy: Factory(:private_policy),contributor:Factory(:person,project:gatekeeper.projects.first))
    login_as(investigation.contributor)

    refute investigation.can_view?(nil)

    assert_enqueued_emails 1 do
      put :update, params: { investigation: { title: investigation.title }, id: investigation.id, policy_attributes: { access_type: Policy::VISIBLE } }
    end

    refute investigation.can_view?(nil)

    assert_includes ResourcePublishLog.requested_approval_assets_for(gatekeeper), investigation
  end

  test 'dont send publish approval request if elevating permissions from VISIBLE -> ACCESSIBLE' do # They're the same for ISA things
    gatekeeper = Factory(:asset_gatekeeper)
    person = Factory(:person,project:gatekeeper.projects.first)
    investigation = Factory(:investigation, projects: gatekeeper.projects, contributor:person,
                            policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    login_as(person)

    assert investigation.is_published?

    assert_no_enqueued_emails do
      put :update, params: { investigation: { title: investigation.title }, id: investigation.id, policy_attributes: { access_type: Policy::ACCESSIBLE } }
    end

    assert_empty ResourcePublishLog.requested_approval_assets_for(gatekeeper)
  end

  test 'can delete an investigation with subscriptions' do
    i = Factory(:investigation, policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    p = Factory(:person)
    Factory(:subscription, person: i.contributor, subscribable: i)
    Factory(:subscription, person: p, subscribable: i)

    login_as(i.contributor)

    assert_difference('Subscription.count', -2) do
      assert_difference('Investigation.count', -1) do
        delete :destroy, params: { id: i.id }
      end
    end

    assert_redirected_to investigations_path
  end

  test 'shows how to create snapshot to get a citation' do
    study = Factory(:study)
    investigation = Factory(:investigation, policy: Factory(:publicly_viewable_policy), studies: [study], contributor:study.contributor)
    login_as(investigation.contributor)

    refute investigation.snapshots.any?

    get :show, params: { id: investigation }

    assert_response :success
    assert_select '#citation-instructions a[href=?]', new_investigation_snapshot_path(investigation)
  end

  test 'shows how to publish investigation to get a citation' do
    study = Factory(:study)
    investigation = Factory(:investigation, policy: Factory(:private_policy),
                            studies: [study], contributor:study.contributor)
    login_as(investigation.contributor)

    refute investigation.permitted_for_research_object?

    get :show, params: { id: investigation }

    assert_response :success
    assert_select '#citation-instructions a[href=?]', check_related_items_investigation_path(investigation)
  end

  test 'shows how to get a citation for a snapshotted investigation' do
    study = Factory(:study)
    investigation = Factory(:investigation, policy: Factory(:publicly_viewable_policy),
                            studies: [study], contributor:study.contributor)

    login_as(investigation.contributor)
    investigation.create_snapshot

    assert investigation.permitted_for_research_object?
    assert investigation.snapshots.any?

    get :show, params: { id: investigation }

    assert_response :success
    assert_select '#citation-instructions .alert p', text: /You have created 1 snapshot of this Investigation/
    assert_select '#citation-instructions a[href=?]', '#snapshots'
  end

  test 'does not show how to get a citation if no manage permission' do
    person = Factory(:person)
    another_person = Factory(:person,project:person.projects.first)
    study = Factory(:study,contributor:another_person)
    investigation = Factory(:investigation, projects:another_person.projects, contributor:another_person,
                            policy: Factory(:publicly_viewable_policy), studies: [study])

    login_as(person)
    investigation.create_snapshot

    assert investigation.permitted_for_research_object?
    assert investigation.snapshots.any?
    refute investigation.can_manage?(person.user)
    assert investigation.can_view?(person.user)

    get :show, params: { id: investigation }

    assert_response :success
    assert_select '#citation-instructions', count: 0
  end

  test 'manage menu item appears according to permission' do
    check_manage_edit_menu_for_type('investigation')
  end

  test 'can access manage page with manage rights' do
    person = Factory(:person)
    investigation = Factory(:investigation, contributor:person)
    login_as(person)
    assert investigation.can_manage?
    get :manage, params: {id: investigation}
    assert_response :success

    # check the project form exists, studies and assays don't have this
    assert_select 'div#add_projects_form', count:1

    #no sharing link, not for Investigation, Study and Assay
    assert_select 'div#temporary_links', count:0

    assert_select 'div#author_form', count:1
  end

  test 'cannot access manage page with edit rights' do
    person = Factory(:person)
    investigation = Factory(:investigation, policy:Factory(:private_policy, permissions:[Factory(:permission, contributor:person, access_type:Policy::EDITING)]))
    login_as(person)
    assert investigation.can_edit?
    refute investigation.can_manage?
    get :manage, params: {id:investigation}
    assert_redirected_to investigation_path(investigation)
    refute_nil flash[:error]
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

    investigation = Factory(:investigation, contributor:person, projects:[proj1], policy:Factory(:private_policy))

    login_as(person)
    assert investigation.can_manage?

    patch :manage_update, params: {id: investigation,
                                 investigation: {
                                     creator_ids: [other_creator.id],
                                     project_ids: [proj1.id, proj2.id]
                                 },
                                 policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                 }}

    assert_redirected_to investigation

    investigation.reload
    assert_equal [proj1,proj2],investigation.projects.sort_by(&:id)
    assert_equal [other_creator],investigation.creators
    assert_equal Policy::VISIBLE,investigation.policy.access_type
    assert_equal 1,investigation.policy.permissions.count
    assert_equal other_person,investigation.policy.permissions.first.contributor
    assert_equal Policy::MANAGING,investigation.policy.permissions.first.access_type

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

    investigation = Factory(:investigation, projects:[proj1], policy:Factory(:private_policy,
                                                                             permissions:[Factory(:permission,contributor:person, access_type:Policy::EDITING)]))

    login_as(person)
    refute investigation.can_manage?
    assert investigation.can_edit?

    assert_equal [proj1],investigation.projects
    assert_empty investigation.creators

    patch :manage_update, params: {id: investigation,
                                 investigation: {
                                     creator_ids: [other_creator.id],
                                     project_ids: [proj1.id, proj2.id]
                                 },
                                 policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                 }}

    refute_nil flash[:error]

    investigation.reload
    assert_equal [proj1],investigation.projects
    assert_empty investigation.creators
    assert_equal Policy::PRIVATE,investigation.policy.access_type
    assert_equal 1,investigation.policy.permissions.count
    assert_equal person,investigation.policy.permissions.first.contributor
    assert_equal Policy::EDITING,investigation.policy.permissions.first.access_type

  end

  def edit_max_object(investigation)
    investigation.creators = [Factory(:person)]
    disable_authorization_checks { investigation.save! }
  end
end
