require 'test_helper'

class StudiesControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases
  include SharingFormTestHelper
  include RdfTestCases
  include GeneralAuthorizationTestCases

  def setup
    login_as Factory(:admin).user
  end

  def rest_api_test_object
    @object = Factory :study, policy: Factory(:public_policy)
  end

  test 'should get index' do
    Factory :study, policy: Factory(:public_policy)
    get :index
    assert_response :success
    assert_not_nil assigns(:studies)
    assert !assigns(:studies).empty?
  end

  test 'should show aggregated publications linked to assay' do
    person = User.current_user.person
    assay1 = Factory :assay, policy: Factory(:public_policy), contributor:person
    assay2 = Factory :assay, policy: Factory(:public_policy), contributor:person

    pub1 = Factory :publication, title: 'pub 1', publication_type: Factory(:journal)
    pub2 = Factory :publication, title: 'pub 2', publication_type: Factory(:journal)
    pub3 = Factory :publication, title: 'pub 3', publication_type: Factory(:journal)
    Factory :relationship, subject: assay1, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub1
    Factory :relationship, subject: assay1, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub2

    Factory :relationship, subject: assay2, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub2
    Factory :relationship, subject: assay2, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub3

    study = Factory(:study, assays: [assay1, assay2], policy: Factory(:public_policy), contributor:person)

    get :show, params: { id: study.id }
    assert_response :success

    assert_select 'ul.nav-pills' do
      assert_select 'a', text: 'Publications (3)', count: 1
    end
  end

  test 'should show draggable icon in index' do
    get :index
    assert_response :success
    studies = assigns(:studies)
    first_study = studies.first
    assert_not_nil first_study
    assert_select 'a[data-favourite-url=?]', add_favourites_path(resource_id: first_study.id,
                                                                 resource_type: first_study.class.name)
  end

  def test_title
    get :index
    assert_select 'title', text: I18n.t('study').pluralize, count: 1
  end

  test 'should get show' do
    study = Factory(:study, policy: Factory(:public_policy))
    get :show, params: { id: study.id }
    assert_response :success
    assert_not_nil assigns(:study)
  end

  test 'should get new' do
    get :new
    assert_response :success
    assert_not_nil assigns(:study)
  end

  test 'should get new with investigation predefined even if not member of project' do
    # this scenario arose whilst fixing the test "should get new with investigation predefined"
    # when passing the investigation_id, if that is editable but current_user is not a member,
    # then the investigation should be added to the list
    inv = investigations(:metabolomics_investigation)

    assert inv.can_edit?, 'model owner should be able to edit this investigation'
    get :new, params: { study: { investigation_id: inv } }
    assert_response :success

    assert_select 'select#study_investigation_id' do
      assert_select "option[selected='selected'][value='#{inv.id}']"
    end
  end

  test 'should get new with investigation predefined' do
    login_as :model_owner
    inv = investigations(:metabolomics_investigation)

    assert inv.can_edit?, 'model owner should be able to edit this investigation'
    get :new, params: { study:{investigation_id: inv }}
    assert_response :success

    assert_select 'select#study_investigation_id' do
      assert_select "option[selected='selected'][value='#{inv.id}']"
    end
  end

  test 'should not allow linking to an investigation from a project you are not a member of' do
    inv = Factory(:investigation)
    user = Factory(:user)
    login_as(user)

    refute inv.projects.map(&:people).flatten.include?(user.person), 'this person should not be a member of the investigations project'
    refute inv.can_edit?(user)
    get :new, params: { study: { investigation_id: inv } }
    assert_response :success

    assert_select 'select#study_investigation_id' do
      assert_select "option[selected='selected'][value='0']"
    end
  end

  test 'should get edit' do
    get :edit, params: { id: studies(:metabolomics_study) }
    assert_response :success
    assert_not_nil assigns(:study)
  end

  test "shouldn't show edit for unauthorized users" do
    s = Factory :study, policy: Factory(:private_policy)
    login_as(Factory(:user))
    get :edit, params: { id: s }
    assert_redirected_to study_path(s)
    assert flash[:error]
  end

  test 'should update' do
    s = studies(:metabolomics_study)
    assert_not_equal 'test', s.title
    put :update, params: { id: s.id, study: { title: 'test' } }
    s = assigns(:study)
    assert_redirected_to study_path(s)
    assert_equal 'test', s.title
  end

  test 'should create' do
    investigation = Factory(:investigation,projects:User.current_user.person.projects,contributor:User.current_user.person)
    assert_difference('Study.count') do
      post :create, params: { study: { title: 'test', investigation_id: investigation.id }, policy_attributes: valid_sharing }
    end
    s = assigns(:study)
    assert_redirected_to study_path(s)
  end

  test 'should update sharing permissions' do
    login_as(Factory(:user))
    s = Factory :study, contributor: User.current_user.person, policy: Factory(:public_policy)
    assert s.can_manage?(User.current_user), 'This user should be able to manage this study'

    assert_equal Policy::EVERYONE, s.policy.access_type

    put :update, params: { id: s, study: { title: s.title }, policy_attributes: { access_type: Policy::NO_ACCESS } }
    s = assigns(:study)
    assert_response :redirect
    s.reload
    assert_equal Policy::NO_ACCESS, s.policy.access_type
  end

  test 'should not update sharing permissions to remove your own manage rights' do
    login_as(Factory(:user))
    s = Factory :study, contributor: Factory(:person), policy: Factory(:public_policy)
    assert s.can_manage?(User.current_user), 'This user should be able to manage this study'

    assert_equal Policy::EVERYONE, s.policy.access_type

    put :update, params: { id: s, study: { title: s.title }, policy_attributes: { access_type: Policy::NO_ACCESS } }
    s = assigns(:study)
    assert_response :unprocessable_entity
    s.reload
    assert_equal Policy::EVERYONE, s.policy.access_type
  end

  test 'should not create with assay already related to study' do
    assert_no_difference('Study.count') do
      post :create, params: { study: { title: 'test', investigation: investigations(:metabolomics_investigation), assay_ids: [assays(:metabolomics_assay3).id] } }
    end
    s = assigns(:study)
    assert flash[:error]
    assert_response :redirect
  end

  test 'should not update with assay already related to study' do
    s = studies(:metabolomics_study)
    put :update, params: { id: s.id, study: { title: 'test', assay_ids: [assays(:metabolomics_assay3).id] } }
    s = assigns(:study)
    assert flash[:error]
    assert_response :redirect
  end

  test 'should can update with assay already related to this study' do
    s = studies(:metabolomics_study)
    put :update, params: { id: s.id, study: { title: 'new title', assay_ids: [assays(:metabolomics_assay).id] } }
    s = assigns(:study)
    assert !flash[:error]
    assert_redirected_to study_path(s)
    assert_equal 'new title', s.title
    assert s.assays.include?(assays(:metabolomics_assay))
  end

  test "no edit button shown for people who can't edit the study" do
    login_as Factory(:user)
    study = Factory :study, policy: Factory(:private_policy)
    get :show, params: { id: study }
    assert_select 'a', text: /Edit #{I18n.t('study')}/i, count: 0
  end

  test 'edit button in show for person in project' do
    get :show, params: { id: studies(:metabolomics_study) }
    assert_select 'a', text: /Edit #{I18n.t('study')}/i, count: 1
  end

  test "unauthorized user can't update" do
    s = Factory :study, policy: Factory(:private_policy)
    login_as(Factory(:user))
    Factory(:permission, contributor: User.current_user.person, policy: s.policy, access_type: Policy::VISIBLE)

    put :update, params: { id: s.id, study: { title: 'test' } }

    assert_redirected_to study_path(s)
    assert flash[:error]
  end

  test 'authorized user can delete if no assays' do
    study = Factory(:study, contributor: Factory(:person))
    login_as study.contributor.user
    assert_difference('Study.count', -1) do
      delete :destroy, params: { id: study.id }
    end
    assert !flash[:error]
    assert_redirected_to studies_path
  end

  test 'study non project member cannot delete even if no assays' do
    login_as(:aaron)
    study = studies(:study_with_no_assays)
    assert_no_difference('Study.count') do
      delete :destroy, params: { id: study.id }
    end
    assert flash[:error]
    assert_redirected_to study
  end

  test 'study project member cannot delete if assays associated' do
    study = studies(:metabolomics_study)
    assert_no_difference('Study.count') do
      delete :destroy, params: { id: study.id }
    end
    assert flash[:error]
    assert_redirected_to study
  end

  def test_should_add_nofollow_to_links_in_show_page
    get :show, params: { id: studies(:study_with_links_in_description) }
    assert_select 'div#description' do
      assert_select 'a[rel="nofollow"]'
    end
  end

  def test_assay_tab_doesnt_show_private_sops_or_datafiles
    login_as(:model_owner)
    study = studies(:study_with_assay_with_public_private_sops_and_datafile)
    get :show, params: { id: study }
    assert_response :success

    assert_select 'ul.nav-pills' do
      assert_select 'a', text: "#{I18n.t('assays.assay').pluralize} (1)", count: 1
      assert_select 'a', text: "#{I18n.t('sop').pluralize} (1+1)", count: 1
      assert_select 'a', text: "#{I18n.t('data_file').pluralize} (1+1)", count: 1
    end

    assert_select 'div.list_item' do
      # the Assay resource_list_item
      assert_select 'p.list_item_attribute a[title=?]', sops(:sop_with_fully_public_policy).title, count: 1
      assert_select 'p.list_item_attribute a[href=?]', sop_path(sops(:sop_with_fully_public_policy)), count: 1
      assert_select 'p.list_item_attribute a[title=?]', sops(:sop_with_private_policy_and_custom_sharing).title, count: 0
      assert_select 'p.list_item_attribute a[href=?]', sop_path(sops(:sop_with_private_policy_and_custom_sharing)), count: 0

      assert_select 'p.list_item_attribute a[title=?]', data_files(:downloadable_data_file).title, count: 1
      assert_select 'p.list_item_attribute a[href=?]', data_file_path(data_files(:downloadable_data_file)), count: 1
      assert_select 'p.list_item_attribute a[title=?]', data_files(:private_data_file).title, count: 0
      assert_select 'p.list_item_attribute a[href=?]', data_file_path(data_files(:private_data_file)), count: 0

      # the Sops and DataFiles resource_list_item
      assert_select 'div.list_item_title a[href=?]', sop_path(sops(:sop_with_fully_public_policy)), text: 'SOP with fully public policy', count: 1
      assert_select 'div.list_item_actions a[href=?]', download_sop_path(sops(:sop_with_fully_public_policy)), count: 1
      assert_select 'div.list_item_title a[href=?]', sop_path(sops(:sop_with_private_policy_and_custom_sharing)), count: 0
      assert_select 'div.list_item_actions a[href=?]', download_sop_path(sops(:sop_with_private_policy_and_custom_sharing)), count: 0

      assert_select 'div.list_item_title a[href=?]', data_file_path(data_files(:downloadable_data_file)), text: 'Downloadable Only', count: 1
      assert_select 'div.list_item_actions a[href=?]', download_data_file_path(data_files(:downloadable_data_file)), count: 1
      assert_select 'div.list_item_title a[href=?]', data_file_path(data_files(:private_data_file)), count: 0
      assert_select 'div.list_item_actions a[href=?]', download_data_file_path(data_files(:private_data_file)), count: 0
    end
  end

  def test_should_show_investigation_tab
    s = studies(:metabolomics_study)
    get :show, params: { id: s }
    assert_response :success
    assert_select 'ul.nav-pills' do
      assert_select 'a', text: "#{I18n.t('investigation').pluralize} (1)", count: 1
    end
  end

  test 'filtering by investigation' do
    inv = investigations(:metabolomics_investigation)
    get :index, params: { filter: { investigation: inv.id } }
    assert_response :success
  end

  test 'filtering by project' do
    project = projects(:sysmo_project)
    get :index, params: { filter: { project: project.id } }
    assert_response :success
  end

  test 'filter by person using nested routes' do
    assert_routing 'people/2/studies', controller: 'studies', action: 'index', person_id: '2'
    study = Factory(:study, policy: Factory(:public_policy))
    study2 = Factory(:study, policy: Factory(:public_policy))
    person = study.contributor
    refute_equal study.contributor, study2.contributor
    assert person.is_a?(Person)
    get :index, params: { person_id: person.id }
    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', study_path(study), text: study.title
      assert_select 'a[href=?]', study_path(study2), text: study2.title, count: 0
    end
  end

  test 'edit study with selected projects scope policy' do
    proj = User.current_user.person.projects.first
    study = Factory(:study, contributor: User.current_user.person,
                            investigation: Factory(:investigation, contributor: User.current_user.person),
                            policy: Factory(:policy,
                                            access_type: Policy::NO_ACCESS,
                                            permissions: [Factory(:permission, contributor: proj, access_type: Policy::EDITING)]))
    get :edit, params: { id: study.id }
  end

  test 'should show the contributor avatar' do
    study = Factory(:study, policy: Factory(:public_policy))
    get :show, params: { id: study }
    assert_response :success
    assert_select '.author_avatar' do
      assert_select 'a[href=?]', person_path(study.contributing_user.person) do
        assert_select 'img'
      end
    end
  end

  test 'object based on existing study' do
    person = User.current_user.person
    inv = Factory :investigation, policy: Factory(:public_policy), contributor:person
    study = Factory :study, title: 'the study', policy: Factory(:public_policy),
                            investigation: inv, contributor:person
    get :new_object_based_on_existing_one, params: { id: study.id }
    assert_response :success
    assert_select '#study_title[value=?]', 'the study'
    assert_select "select#study_investigation_id option[selected][value='#{study.investigation.id}']", count: 1
  end

  test 'object based on existing one when unauthorized to view' do
    study = Factory :study, title: 'the private study', policy: Factory(:private_policy)
    refute study.can_view?
    get :new_object_based_on_existing_one, params: { id: study.id }
    assert_response :forbidden
  end

  test "logged out user can't see new" do
    logout
    get :new
    assert_redirected_to studies_path
  end

  test 'new object based on existing one when can view but not logged in' do
    study = Factory(:study, policy: Factory(:public_policy))
    logout
    assert study.can_view?
    get :new_object_based_on_existing_one, params: { id: study.id }
    assert_redirected_to study
    refute_nil flash[:error]
  end

  test 'object based on existing one when unauthorized to edit investigation' do
    person = Factory(:person)
    inv = Factory(:investigation, policy: Factory(:private_policy), contributor: person)

    study = Factory :study, title: 'the private study', policy: Factory(:public_policy), investigation: inv, contributor:person
    assert study.can_view?
    refute study.investigation.can_edit?
    get :new_object_based_on_existing_one, params: { id: study.id }
    assert_response :success
    assert_select '#study_title[value=?]', 'the private study'
    assert_select "select#study_investigation_id option[selected][value='#{study.investigation.id}']", count: 0
    refute_nil flash.now[:notice]
  end

  test 'studies filtered by assay through nested routing' do
    assert_routing 'assays/22/studies', controller: 'studies', action: 'index', assay_id: '22'
    contributor = Factory(:person)
    assay1 = Factory :assay, contributor: contributor, study: Factory(:study, contributor: contributor)
    assay2 = Factory :assay, contributor: contributor, study: Factory(:study, contributor: contributor)
    login_as contributor
    assert assay1.study.can_view?
    assert assay2.study.can_view?
    get :index, params: { assay_id: assay1.id }
    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', study_path(assay1.study), text: assay1.study.title
      assert_select 'a[href=?]', study_path(assay2.study), text: assay2.study.title, count: 0
    end
  end

  test 'should add creators' do
    study = Factory(:study, policy: Factory(:public_policy))
    creator = Factory(:person)
    assert study.creators.empty?

    put :update, params: { id: study.id, study: { title: study.title, creator_ids: [creator.id] } }
    assert_redirected_to study_path(study)

    assert study.creators.include?(creator)
  end

  test 'should show creators' do
    study = Factory(:study, policy: Factory(:public_policy))
    creator = Factory(:person)
    study.creators = [creator]
    study.save
    study.reload
    assert study.creators.include?(creator)

    get :show, params: { id: study.id }
    assert_response :success
    assert_select 'span.author_avatar a[href=?]', "/people/#{creator.id}"
  end

  test 'should show other creators' do
    study = Factory(:study, policy: Factory(:public_policy))
    other_creators = 'other creators'
    study.other_creators = other_creators
    study.save
    study.reload

    get :show, params: { id: study.id }
    assert_response :success
    assert_select 'div.panel-body div', text: other_creators
  end

  test 'should not multiply creators after calling show' do
    study = Factory(:study, policy: Factory(:public_policy))
    creator = Factory(:person)
    study.creators = [creator]
    study.save
    study.reload
    assert study.creators.include?(creator)
    assert_equal 1, study.creators.count

    get :show, params: { id: study.id }
    assert_response :success

    study.reload
    assert_equal 1, study.creators.count
  end

  test 'programme studies through nested routing' do
    assert_routing 'programmes/2/studies', { controller: 'studies', action: 'index', programme_id: '2' }
    programme = Factory(:programme)
    person = Factory(:person,project:programme.projects.first)
    investigation = Factory(:investigation, projects: programme.projects, policy: Factory(:public_policy),contributor:person)
    investigation2 = Factory(:investigation, policy: Factory(:public_policy))
    study = Factory(:study, investigation: investigation, policy: Factory(:public_policy), contributor:investigation.contributor)
    study2 = Factory(:study, investigation: investigation2, policy: Factory(:public_policy), contributor:investigation2.contributor)

    get :index, params: { programme_id: programme.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', study_path(study), text: study.title
      assert_select 'a[href=?]', study_path(study2), text: study2.title, count: 0
    end
  end

  def edit_max_object(study)
    study.person_responsible = Factory(:max_person)
    add_creator_to_test_object(study)
  end

  test 'can delete a study with subscriptions' do
    study = Factory(:study, policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    p = Factory(:person)
    Factory(:subscription, person: study.contributor, subscribable: study)
    Factory(:subscription, person: p, subscribable: study)

    login_as(study.contributor)

    assert_difference('Subscription.count', -2) do
      assert_difference('Study.count', -1) do
        delete :destroy, params: { id: study.id }
      end
    end

    assert_redirected_to studies_path
  end

  test 'cannot create with link to investigation in another project' do
    person = Factory(:person)
    another_person = Factory(:person)
    login_as(person)
    investigation = Factory(:investigation,contributor:another_person,projects:another_person.projects,policy:Factory(:publicly_viewable_policy))
    assert investigation.can_view?
    assert_empty person.projects & investigation.projects
    assert_no_difference('Study.count') do
      post :create, params: { study: { title: 'test', investigation_id: investigation.id }, policy_attributes: valid_sharing }
    end
    assert_response :unprocessable_entity
  end

  test 'cannot create with hidden investigation in same project' do
    person = Factory(:person)
    another_person = Factory(:person)
    another_person.add_to_project_and_institution(person.projects.first,person.institutions.first)
    another_person.save!
    login_as(person)
    investigation = Factory(:investigation,contributor:another_person,projects:person.projects,policy:Factory(:private_policy))
    refute investigation.can_view?
    refute_empty person.projects & investigation.projects

    assert_no_difference('Study.count') do
      post :create, params: { study: { title: 'test', investigation_id: investigation.id }, policy_attributes: valid_sharing }
    end
    assert_response :unprocessable_entity
  end

  test 'cannot update with link to investigation in another project' do
    person = Factory(:person)
    another_person = Factory(:person)
    login_as(person)
    investigation = Factory(:investigation,contributor:another_person,projects:another_person.projects,policy:Factory(:publicly_viewable_policy))
    study = Factory(:study,contributor:person,investigation:Factory(:investigation,contributor:person,projects:person.projects))

    assert investigation.can_view?
    assert_empty person.projects & investigation.projects

    refute_equal investigation,study.investigation


    put :update, params: { id:study.id, study:{investigation_id:investigation.id} }

    assert_response :unprocessable_entity
    study.reload
    refute_equal investigation,study.investigation
  end

  test 'cannot update with link to hidden investigation in same project' do
    person = Factory(:person)
    another_person = Factory(:person)
    another_person.add_to_project_and_institution(person.projects.first,person.institutions.first)
    another_person.save!
    login_as(person)
    investigation = Factory(:investigation,contributor:another_person,projects:person.projects,policy:Factory(:private_policy))
    study = Factory(:study,contributor:person,investigation:Factory(:investigation,contributor:person,projects:person.projects))

    refute investigation.can_view?
    refute_empty person.projects & investigation.projects
    refute_equal investigation,study.investigation

    put :update, params: { id:study.id, study:{investigation_id:investigation.id} }

    assert_response :unprocessable_entity
    study.reload
    refute_equal investigation,study.investigation
  end

  test 'can create with link to investigation in multiple projects' do
    person = Factory(:person)
    another_person = Factory(:person)
    login_as(person)
    projects = [person.projects.first, another_person.projects.first]
    assert_includes projects[0].people, person
    refute_includes projects[1].people, person
    investigation = Factory(:investigation, contributor: another_person, projects:projects, policy: Factory(:publicly_viewable_policy))
    assert_difference('Study.count', 1) do
      post :create, params: { study: { title: 'test', investigation_id: investigation.id }, policy_attributes: valid_sharing }
    end
  end

  test 'manage menu item appears according to permission' do
    check_manage_edit_menu_for_type('study')
  end

  test 'can access manage page with manage rights' do
    person = Factory(:person)
    study = Factory(:study, contributor:person)
    login_as(person)
    assert study.can_manage?
    get :manage, params: {id: study}
    assert_response :success

    #shouldn't be a projects block
    assert_select 'div#add_projects_form', count:0

    # check sharing form exists
    assert_select 'div#sharing_form', count:1

    #no sharing link, not for Investigation, Study and Assay
    assert_select 'div#temporary_links', count:0

    assert_select 'div#author_form', count:1
  end

  test 'cannot access manage page with edit rights' do
    person = Factory(:person)
    study = Factory(:study, policy:Factory(:private_policy, permissions:[Factory(:permission, contributor:person, access_type:Policy::EDITING)]))
    login_as(person)
    assert study.can_edit?
    refute study.can_manage?
    get :manage, params: {id:study}
    assert_redirected_to study
    refute_nil flash[:error]
  end

  test 'manage_update' do
    proj1=Factory(:project)
    person = Factory(:person,project:proj1)
    other_person = Factory(:person)

    other_creator = Factory(:person,project:proj1)

    study = Factory(:study, contributor:person, policy:Factory(:private_policy))

    login_as(person)
    assert study.can_manage?

    patch :manage_update, params: {id: study,
                                   study: {
                                       creator_ids: [other_creator.id],
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    assert_redirected_to study

    study.reload
    assert_equal [other_creator],study.creators
    assert_equal Policy::VISIBLE,study.policy.access_type
    assert_equal 1,study.policy.permissions.count
    assert_equal other_person,study.policy.permissions.first.contributor
    assert_equal Policy::MANAGING,study.policy.permissions.first.access_type

  end

  test 'manage_update fails without manage rights' do
    proj1=Factory(:project)

    person = Factory(:person, project:proj1)


    other_person = Factory(:person)

    other_creator = Factory(:person,project:proj1)


    study = Factory(:study, policy:Factory(:private_policy, permissions:[Factory(:permission,contributor:person, access_type:Policy::EDITING)]))

    login_as(person)
    refute study.can_manage?
    assert study.can_edit?

    assert_empty study.creators

    patch :manage_update, params: {id: study,
                                   study: {
                                       creator_ids: [other_creator.id],
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    refute_nil flash[:error]

    study.reload
    assert_equal Policy::PRIVATE,study.policy.access_type
    assert_equal 1,study.policy.permissions.count
    assert_equal person,study.policy.permissions.first.contributor
    assert_equal Policy::EDITING,study.policy.permissions.first.access_type

  end

  test 'experimentalists only shown if set' do
    person = Factory(:person)
    login_as(person)
    study = Factory(:study,experimentalists:'some experimentalists',contributor:person)
    refute study.experimentalists.blank?

    get :edit, params:{id:study}
    assert_response :success

    assert_select 'input#study_experimentalists', count:1

    get :show, params:{id:study}
    assert_response :success

    assert_select 'p',text:/Experimentalists:/,count:1

    study = Factory(:study,contributor:person)
    assert study.experimentalists.blank?

    get :edit, params:{id:study}
    assert_response :success

    assert_select 'input#study_experimentalists', count:0

    get :show, params:{id:study}
    assert_response :success

    assert_select 'p',text:/Experimentalists:/, count:0

    get :new
    assert_response :success

    assert_select 'input#study_experimentalists', count:0


  end
end
