require 'test_helper'

class StudiesControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include SharingFormTestHelper
  include RdfTestCases
  include GeneralAuthorizationTestCases

  def setup
    login_as FactoryBot.create(:admin).user
  end

  test 'should get index' do
    FactoryBot.create :study, policy: FactoryBot.create(:public_policy)
    get :index
    assert_response :success
    assert_not_nil assigns(:studies)
    refute assigns(:studies).empty?
  end

  test 'should show aggregated publications linked to assay' do
    person = User.current_user.person
    assay1 = FactoryBot.create :assay, policy: FactoryBot.create(:public_policy), contributor:person
    assay2 = FactoryBot.create :assay, policy: FactoryBot.create(:public_policy), contributor:person

    pub1 = FactoryBot.create :publication, title: 'pub 1', publication_type: FactoryBot.create(:journal)
    pub2 = FactoryBot.create :publication, title: 'pub 2', publication_type: FactoryBot.create(:journal)
    pub3 = FactoryBot.create :publication, title: 'pub 3', publication_type: FactoryBot.create(:journal)
    FactoryBot.create :relationship, subject: assay1, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub1
    FactoryBot.create :relationship, subject: assay1, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub2

    FactoryBot.create :relationship, subject: assay2, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub2
    FactoryBot.create :relationship, subject: assay2, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub3

    study = FactoryBot.create(:study, assays: [assay1, assay2], policy: FactoryBot.create(:public_policy), contributor:person)

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
    study = FactoryBot.create(:study, policy: FactoryBot.create(:public_policy))
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
    inv = FactoryBot.create(:investigation)
    user = FactoryBot.create(:user)
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
    s = FactoryBot.create :study, policy: FactoryBot.create(:private_policy)
    login_as(FactoryBot.create(:user))
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
    investigation = FactoryBot.create(:investigation,projects:User.current_user.person.projects,contributor:User.current_user.person)
    assert_difference('Study.count') do
      post :create, params: { study: { title: 'test', investigation_id: investigation.id }, policy_attributes: valid_sharing }
    end
    s = assigns(:study)
    assert_redirected_to study_path(s)
  end

  test 'should update sharing permissions' do
    login_as(FactoryBot.create(:user))
    s = FactoryBot.create :study, contributor: User.current_user.person, policy: FactoryBot.create(:public_policy)
    assert s.can_manage?(User.current_user), 'This user should be able to manage this study'

    assert_equal Policy::EVERYONE, s.policy.access_type

    put :update, params: { id: s, study: { title: s.title }, policy_attributes: { access_type: Policy::NO_ACCESS } }
    s = assigns(:study)
    assert_response :redirect
    s.reload
    assert_equal Policy::NO_ACCESS, s.policy.access_type
  end

  test 'should not update sharing permissions to remove your own manage rights' do
    login_as(FactoryBot.create(:user))
    s = FactoryBot.create :study, contributor: FactoryBot.create(:person), policy: FactoryBot.create(:public_policy)
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
    login_as FactoryBot.create(:user)
    study = FactoryBot.create :study, policy: FactoryBot.create(:private_policy)
    get :show, params: { id: study }
    assert_select 'a', text: /Edit #{I18n.t('study')}/i, count: 0
  end

  test 'edit button in show for person in project' do
    get :show, params: { id: studies(:metabolomics_study) }
    assert_select 'a', text: /Edit #{I18n.t('study')}/i, count: 1
  end

  test "unauthorized user can't update" do
    s = FactoryBot.create :study, policy: FactoryBot.create(:private_policy)
    login_as(FactoryBot.create(:user))
    FactoryBot.create(:permission, contributor: User.current_user.person, policy: s.policy, access_type: Policy::VISIBLE)

    put :update, params: { id: s.id, study: { title: 'test' } }

    assert_redirected_to study_path(s)
    assert flash[:error]
  end

  test 'authorized user can delete if no assays' do
    study = FactoryBot.create(:study, contributor: FactoryBot.create(:person))
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
    study = FactoryBot.create(:study, policy: FactoryBot.create(:public_policy))
    study2 = FactoryBot.create(:study, policy: FactoryBot.create(:public_policy))
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
    study = FactoryBot.create(:study, contributor: User.current_user.person,
                            investigation: FactoryBot.create(:investigation, contributor: User.current_user.person),
                            policy: FactoryBot.create(:policy,
                                            access_type: Policy::NO_ACCESS,
                                            permissions: [FactoryBot.create(:permission, contributor: proj, access_type: Policy::EDITING)]))
    get :edit, params: { id: study.id }
  end

  test 'should show the contributor avatar' do
    study = FactoryBot.create(:study, policy: FactoryBot.create(:public_policy))
    get :show, params: { id: study }
    assert_response :success
    assert_select 'li.author-list-item' do
      assert_select 'a[href=?]', person_path(study.contributing_user.person) do
        assert_select 'img'
      end
    end
  end

  test 'object based on existing study' do
    person = User.current_user.person
    inv = FactoryBot.create :investigation, policy: FactoryBot.create(:public_policy), contributor:person
    study = FactoryBot.create :study, title: 'the study', policy: FactoryBot.create(:public_policy),
                            investigation: inv, contributor:person
    get :new_object_based_on_existing_one, params: { id: study.id }
    assert_response :success
    assert_select '#study_title[value=?]', 'the study'
    assert_select "select#study_investigation_id option[selected][value='#{study.investigation.id}']", count: 1
  end

  test 'object based on existing one when unauthorized to view' do
    study = FactoryBot.create :study, title: 'the private study', policy: FactoryBot.create(:private_policy)
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
    study = FactoryBot.create(:study, policy: FactoryBot.create(:public_policy))
    logout
    assert study.can_view?
    get :new_object_based_on_existing_one, params: { id: study.id }
    assert_redirected_to study
    refute_nil flash[:error]
  end

  test 'object based on existing one when unauthorized to edit investigation' do
    person = FactoryBot.create(:person)
    inv = FactoryBot.create(:investigation, policy: FactoryBot.create(:private_policy), contributor: person)

    study = FactoryBot.create :study, title: 'the private study', policy: FactoryBot.create(:public_policy), investigation: inv, contributor:person
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
    contributor = FactoryBot.create(:person)
    assay1 = FactoryBot.create :assay, contributor: contributor, study: FactoryBot.create(:study, contributor: contributor)
    assay2 = FactoryBot.create :assay, contributor: contributor, study: FactoryBot.create(:study, contributor: contributor)
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
    study = FactoryBot.create(:study, policy: FactoryBot.create(:public_policy))
    creator = FactoryBot.create(:person)
    assert study.creators.empty?

    put :update, params: { id: study.id, study: { title: study.title, creator_ids: [creator.id] } }
    assert_redirected_to study_path(study)

    assert study.creators.include?(creator)
  end

  test 'should show creators' do
    study = FactoryBot.create(:study, policy: FactoryBot.create(:public_policy))
    creator = FactoryBot.create(:person)
    study.creators = [creator]
    study.save
    study.reload
    assert study.creators.include?(creator)

    get :show, params: { id: study.id }
    assert_response :success
    assert_select 'li.author-list-item a[href=?]', "/people/#{creator.id}"
  end

  test 'should show other creators' do
    study = FactoryBot.create(:study, policy: FactoryBot.create(:public_policy))
    other_creators = 'frodo baggins'
    study.other_creators = other_creators
    study.save
    study.reload

    get :show, params: { id: study.id }
    assert_response :success
    assert_select '#author-box .additional-credit', text: 'frodo baggins', count: 1
  end

  test 'should not multiply creators after calling show' do
    study = FactoryBot.create(:study, policy: FactoryBot.create(:public_policy))
    creator = FactoryBot.create(:person)
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
    programme = FactoryBot.create(:programme)
    person = FactoryBot.create(:person,project:programme.projects.first)
    investigation = FactoryBot.create(:investigation, projects: programme.projects, policy: FactoryBot.create(:public_policy),contributor:person)
    investigation2 = FactoryBot.create(:investigation, policy: FactoryBot.create(:public_policy))
    study = FactoryBot.create(:study, investigation: investigation, policy: FactoryBot.create(:public_policy), contributor:investigation.contributor)
    study2 = FactoryBot.create(:study, investigation: investigation2, policy: FactoryBot.create(:public_policy), contributor:investigation2.contributor)

    get :index, params: { programme_id: programme.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', study_path(study), text: study.title
      assert_select 'a[href=?]', study_path(study2), text: study2.title, count: 0
    end
  end

  test 'can delete a study with subscriptions' do
    study = FactoryBot.create(:study, policy: FactoryBot.create(:public_policy, access_type: Policy::VISIBLE))
    p = FactoryBot.create(:person)
    FactoryBot.create(:subscription, person: study.contributor, subscribable: study)
    FactoryBot.create(:subscription, person: p, subscribable: study)

    login_as(study.contributor)

    assert_difference('Subscription.count', -2) do
      assert_difference('Study.count', -1) do
        delete :destroy, params: { id: study.id }
      end
    end

    assert_redirected_to studies_path
  end

  test 'cannot create with link to investigation in another project' do
    person = FactoryBot.create(:person)
    another_person = FactoryBot.create(:person)
    login_as(person)
    investigation = FactoryBot.create(:investigation,contributor:another_person,projects:another_person.projects,policy:FactoryBot.create(:publicly_viewable_policy))
    assert investigation.can_view?
    assert_empty person.projects & investigation.projects
    assert_no_difference('Study.count') do
      post :create, params: { study: { title: 'test', investigation_id: investigation.id }, policy_attributes: valid_sharing }
    end
    assert_response :unprocessable_entity
  end

  test 'cannot create with hidden investigation in same project' do
    person = FactoryBot.create(:person)
    another_person = FactoryBot.create(:person)
    another_person.add_to_project_and_institution(person.projects.first,person.institutions.first)
    another_person.save!
    login_as(person)
    investigation = FactoryBot.create(:investigation,contributor:another_person,projects:person.projects,policy:FactoryBot.create(:private_policy))
    refute investigation.can_view?
    refute_empty person.projects & investigation.projects

    assert_no_difference('Study.count') do
      post :create, params: { study: { title: 'test', investigation_id: investigation.id }, policy_attributes: valid_sharing }
    end
    assert_response :unprocessable_entity
  end

  test 'cannot update with link to investigation in another project' do
    person = FactoryBot.create(:person)
    another_person = FactoryBot.create(:person)
    login_as(person)
    investigation = FactoryBot.create(:investigation,contributor:another_person,projects:another_person.projects,policy:FactoryBot.create(:publicly_viewable_policy))
    study = FactoryBot.create(:study,contributor:person,investigation:FactoryBot.create(:investigation,contributor:person,projects:person.projects))

    assert investigation.can_view?
    assert_empty person.projects & investigation.projects

    refute_equal investigation,study.investigation


    put :update, params: { id:study.id, study:{investigation_id:investigation.id} }

    assert_response :unprocessable_entity
    study.reload
    refute_equal investigation,study.investigation
  end

  test 'cannot update with link to hidden investigation in same project' do
    person = FactoryBot.create(:person)
    another_person = FactoryBot.create(:person)
    another_person.add_to_project_and_institution(person.projects.first,person.institutions.first)
    another_person.save!
    login_as(person)
    investigation = FactoryBot.create(:investigation,contributor:another_person,projects:person.projects,policy:FactoryBot.create(:private_policy))
    study = FactoryBot.create(:study,contributor:person,investigation:FactoryBot.create(:investigation,contributor:person,projects:person.projects))

    refute investigation.can_view?
    refute_empty person.projects & investigation.projects
    refute_equal investigation,study.investigation

    put :update, params: { id:study.id, study:{investigation_id:investigation.id} }

    assert_response :unprocessable_entity
    study.reload
    refute_equal investigation,study.investigation
  end

  test 'can create with link to investigation in multiple projects' do
    person = FactoryBot.create(:person)
    another_person = FactoryBot.create(:person)
    login_as(person)
    projects = [person.projects.first, another_person.projects.first]
    assert_includes projects[0].people, person
    refute_includes projects[1].people, person
    investigation = FactoryBot.create(:investigation, contributor: another_person, projects:projects, policy: FactoryBot.create(:publicly_viewable_policy))
    assert_difference('Study.count', 1) do
      post :create, params: { study: { title: 'test', investigation_id: investigation.id }, policy_attributes: valid_sharing }
    end
  end

  test 'manage menu item appears according to permission' do
    check_manage_edit_menu_for_type('study')
  end

  test 'can access manage page with manage rights' do
    person = FactoryBot.create(:person)
    study = FactoryBot.create(:study, contributor:person)
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

    assert_select 'div#author-form', count:1
  end

  test 'cannot access manage page with edit rights' do
    person = FactoryBot.create(:person)
    study = FactoryBot.create(:study, policy:FactoryBot.create(:private_policy, permissions:[FactoryBot.create(:permission, contributor:person, access_type:Policy::EDITING)]))
    login_as(person)
    assert study.can_edit?
    refute study.can_manage?
    get :manage, params: {id:study}
    assert_redirected_to study
    refute_nil flash[:error]
  end

  test 'manage_update' do
    proj1=FactoryBot.create(:project)
    person = FactoryBot.create(:person,project:proj1)
    other_person = FactoryBot.create(:person)

    other_creator = FactoryBot.create(:person,project:proj1)

    study = FactoryBot.create(:study, contributor:person, policy:FactoryBot.create(:private_policy))

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
    proj1=FactoryBot.create(:project)

    person = FactoryBot.create(:person, project:proj1)


    other_person = FactoryBot.create(:person)

    other_creator = FactoryBot.create(:person,project:proj1)


    study = FactoryBot.create(:study, policy:FactoryBot.create(:private_policy, permissions:[FactoryBot.create(:permission,contributor:person, access_type:Policy::EDITING)]))

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

  test 'create and update a study with custom metadata' do
    cmt = FactoryBot.create(:simple_study_custom_metadata_type)

    login_as(FactoryBot.create(:person))

    #test create
    assert_difference('Study.count') do
      investigation = FactoryBot.create(:investigation,projects:User.current_user.person.projects,contributor:User.current_user.person)
      study_attributes = { title: 'test', investigation_id: investigation.id }
      cm_attributes = {custom_metadata_attributes:{ custom_metadata_type_id: cmt.id,
                                                   data:{
                                                   "name":'fred',
                                                   "age":22}}}

      post :create, params: { study: study_attributes.merge(cm_attributes), sharing: valid_sharing }
    end

    assert study=assigns(:study)
    assert cm = study.custom_metadata
    assert_equal cmt, cm.custom_metadata_type
    assert_equal 'fred',cm.get_attribute_value('name')
    assert_equal '22',cm.get_attribute_value('age')
    assert_nil cm.get_attribute_value('date')

    # test update
    old_id = cm.id
    assert_no_difference('Study.count') do
      assert_no_difference('CustomMetadata.count') do
        put :update, params: { id: study.id, study: { title: "new title",
          custom_metadata_attributes: { custom_metadata_type_id: cmt.id, id: cm.id,
                                        data: {
                                          "name": 'max',
                                          "age": 20 } }
        }
        }
      end
    end

    assert new_study = assigns(:study)
    assert_equal 'new title', new_study.title
    assert_equal 'max', new_study.custom_metadata.get_attribute_value('name')
    assert_equal '20', new_study.custom_metadata.get_attribute_value('age')
    assert_equal old_id, new_study.custom_metadata.id
  end

  test 'create a study with custom metadata validated' do
    cmt = FactoryBot.create(:simple_study_custom_metadata_type)

    login_as(FactoryBot.create(:person))

    # invalid age - needs to be a number
    assert_no_difference('Study.count') do
      investigation = FactoryBot.create(:investigation,projects:User.current_user.person.projects,contributor:User.current_user.person)
      study_attributes = { title: 'test', investigation_id: investigation.id }
      cm_attributes = {custom_metadata_attributes:{custom_metadata_type_id: cmt.id, data:{'name':'fred','age':'not a number'}}}

      put :create, params: { study: study_attributes.merge(cm_attributes), sharing: valid_sharing }
    end

    assert study=assigns(:study)
    refute study.valid?

    # name is required
    assert_no_difference('Study.count') do
      investigation = FactoryBot.create(:investigation,projects:User.current_user.person.projects,contributor:User.current_user.person)
      study_attributes = { title: 'test', investigation_id: investigation.id }
      cm_attributes = {custom_metadata_attributes:{custom_metadata_type_id: cmt.id, data:{'name':nil,'age':22}}}

      put :create, params: { study: study_attributes.merge(cm_attributes), sharing: valid_sharing }
    end

    assert study=assigns(:study)
    refute study.valid?
  end

  test 'create a study with custom metadata with spaces in attribute names' do
    cmt = FactoryBot.create(:study_custom_metadata_type_with_spaces)

    login_as(FactoryBot.create(:person))

    assert_difference('Study.count') do
      investigation = FactoryBot.create(:investigation,projects:User.current_user.person.projects,contributor:User.current_user.person)
      study_attributes = { title: 'test', investigation_id: investigation.id }
      cm_attributes = {custom_metadata_attributes:{custom_metadata_type_id: cmt.id,
                                                   data:{
                                                   "full name":'Paul Jones',
                                                   "full address":'London, UK'}}}

      put :create, params: { study: study_attributes.merge(cm_attributes), sharing: valid_sharing }
    end

    assert study=assigns(:study)

    assert study.valid?
    assert cm = study.custom_metadata

    assert_equal cmt, cm.custom_metadata_type
    assert_equal 'Paul Jones',cm.get_attribute_value('full name')
    assert_equal 'London, UK',cm.get_attribute_value('full address')
  end

  test 'create a study with custom metadata with clashing attribute names' do
    cmt = FactoryBot.create(:study_custom_metadata_type_with_clashes)

    login_as(FactoryBot.create(:person))

    assert_difference('Study.count') do
      investigation = FactoryBot.create(:investigation,projects:User.current_user.person.projects,contributor:User.current_user.person)
      study_attributes = { title: 'test', investigation_id: investigation.id }
      cm_attributes = {custom_metadata_attributes:{custom_metadata_type_id: cmt.id,
                                                   data:{
                                                   "full name":'full name',
                                                   "Full name":'Full name',
                                                   "full  name":'full  name'}}}

      put :create, params: { study: study_attributes.merge(cm_attributes), sharing: valid_sharing }
    end

    assert study=assigns(:study)

    assert study.valid?
    assert cm = study.custom_metadata

    assert_equal cmt, cm.custom_metadata_type
    assert_equal 'full name',cm.get_attribute_value('full name')
    assert_equal 'Full name',cm.get_attribute_value('Full name')
    assert_equal 'full  name',cm.get_attribute_value('full  name')
  end

  test 'create a study with custom metadata with attribute names with symbols' do
    cmt = FactoryBot.create(:study_custom_metadata_type_with_symbols)

    login_as(FactoryBot.create(:person))

    assert_difference('Study.count') do
      investigation = FactoryBot.create(:investigation,projects:User.current_user.person.projects,contributor:User.current_user.person)
      study_attributes = { title: 'test', investigation_id: investigation.id }
      cm_attributes = {custom_metadata_attributes:{custom_metadata_type_id: cmt.id,
                                        data:{
                                            "+name":'+name',
                                            "-name":'-name',
                                            "&name":'&name',
                                            "name(name)":'name(name)'
                                        }}}

      put :create, params: { study: study_attributes.merge(cm_attributes), sharing: valid_sharing }
    end

    assert study=assigns(:study)

    assert study.valid?
    assert cm = study.custom_metadata

    assert_equal cmt, cm.custom_metadata_type
    assert_equal '+name',cm.get_attribute_value('+name')
    assert_equal '-name',cm.get_attribute_value('-name')
    assert_equal '&name',cm.get_attribute_value('&name')
    assert_equal 'name(name)',cm.get_attribute_value('name(name)')
  end

  test 'create a study with custom metadata cv type' do
    cmt = FactoryBot.create(:study_custom_metadata_type_with_cv_and_cv_list_type)
    login_as(FactoryBot.create(:person))

    assert_difference('Study.count') do
      investigation = FactoryBot.create(:investigation,projects:User.current_user.person.projects,contributor:User.current_user.person)
      study_attributes = { title: 'test', investigation_id: investigation.id }
      cm_attributes = {custom_metadata_attributes:{custom_metadata_type_id: cmt.id,
                                                   data:{
                                                     "apple name":"Newton's Apple",
                                                     "apple list":['Granny Smith','Bramley'],
                                                     "apple controlled vocab": ['Granny Smith']}}}

      post :create, params: { study: study_attributes.merge(cm_attributes), sharing: valid_sharing }
    end

    assert study=assigns(:study)

    assert cm = study.custom_metadata

    assert_equal cmt, cm.custom_metadata_type
    assert_equal "Newton's Apple",cm.get_attribute_value('apple name')
    assert_equal 'Granny Smith',cm.get_attribute_value('apple controlled vocab')
    assert_equal ['Granny Smith','Bramley'],cm.get_attribute_value('apple list')

    get :show, params: { id: study }
    assert_response :success

    assert_select 'div.custom_metadata',text:/Granny Smith/, count:2
  end

  test 'should create and update study with linked custom metadata type' do

    cmt = FactoryBot.create(:role_custom_metadata_type)
    login_as(FactoryBot.create(:person))

    # test create
    assert_difference('Study.count') do
      assert_difference('CustomMetadata.count') do
        investigation = FactoryBot.create(:investigation,projects:User.current_user.person.projects,contributor:User.current_user.person)
        study_attributes = { title: 'Alice in Wonderland', investigation_id: investigation.id }
        cm_attributes = { custom_metadata_attributes: {
          custom_metadata_type_id: cmt.id, data: {
            "role_email":"alice@email.com",
            "role_phone":"0012345",
            "role_name": {
                "first_name":"alice",
                "last_name": "liddell"
              }
          }
        }
        }

        post :create, params: { study: study_attributes.merge(cm_attributes), sharing: valid_sharing }
      end
    end

    assert study = assigns(:study)
    assert cm = study.custom_metadata
    assert_equal cmt, cm.custom_metadata_type
    assert_equal "alice@email.com", cm.data['role_email']
    assert_equal '0012345',cm.data['role_phone']
    assert_equal 'alice', cm.data['role_name']['first_name']
    assert_equal 'liddell', cm.data['role_name']['last_name']

    # test show
    get :show, params:{ id:study}
    assert_response :success


    # test update
    assert_no_difference('Study.count') do
      assert_no_difference('CustomMetadata.count') do
        put :update, params: { id: study.id, study: { title: "Alice Through the Looking Glass",
                                                      custom_metadata_attributes: {
                                                        custom_metadata_type_id: cmt.id, id:cm.id, data: {
                                                          "role_email":"rabbit@email.com",
                                                          "role_name": {
                                                            "first_name":"rabbit"
                                                          }
                                                        }
                                                      }
        }
        }
      end
    end

    assert new_study = assigns(:study)
    assert_equal 'Alice Through the Looking Glass', new_study.title
    assert_equal 'rabbit@email.com', new_study.custom_metadata.data['role_email']
    assert_equal 'rabbit', new_study.custom_metadata.data['role_name']['first_name']
  end

  test 'should create and update study, whose custom metadata type contains attributes which link to the same custom metadata type' do
    cmt = FactoryBot.create(:family_custom_metadata_type)
    login_as(FactoryBot.create(:person))
    linked_cmts = cmt.attributes_with_linked_custom_metadata_type
    assert_difference('Study.count') do
      assert_difference('CustomMetadata.count') do
        investigation = FactoryBot.create(:investigation,projects:User.current_user.person.projects,contributor:User.current_user.person)
        study_attributes = { title: 'Family', investigation_id: investigation.id }
        cm_attributes = { custom_metadata_attributes: {
          custom_metadata_type_id: cmt.id, data: {
            "dad":{"first_name":"john", "last_name":"liddell"},
            "mom":{"first_name":"lily", "last_name":"liddell"},
            "child":{"0":{"first_name":"alice", "last_name":"liddell"}}
            }
          }
        }
        post :create, params: { study: study_attributes.merge(cm_attributes), sharing: valid_sharing }
      end
    end

    assert study = assigns(:study)
    cm = study.custom_metadata
    assert_equal cmt, cm.custom_metadata_type
    data = cm.data
    assert_equal %w[dad mom child], linked_cmts.map(&:title)
    assert_equal "john",data["dad"]["first_name"]
    assert_equal "liddell",data["dad"]['last_name']
    assert_equal "lily",data["mom"]["first_name"]
    assert_equal "alice",data["child"].first["first_name"]

    # test show
    get :show, params:{ id:study}
    assert_response :success

    # test update
    assert_no_difference('Study.count') do
      assert_no_difference('CustomMetadata.count') do
        put :update, params: { id: study.id, study: { title: "Alice Through the Looking Glass",
                                                      custom_metadata_attributes: {
                                                        custom_metadata_type_id: cmt.id, id:cm.id, data: {
                                                          "dad":{"first_name":"tom", "last_name":"liddell"},
                                                          "child":{"0":{"first_name":"rabbit", "last_name":"wonderland"},"1":{"first_name":"mad", "last_name":"hatter"}}
                                                        }
                                                      }
        }
        }
      end
    end
    assert new_study = assigns(:study)
    data = new_study.custom_metadata.data

    assert_equal "tom",data["dad"]["first_name"]
    assert_equal "liddell",data["dad"]['last_name']
    assert_equal "lily",data["mom"]["first_name"]
    assert_equal "liddell",data["mom"]['last_name']
    assert_equal "rabbit",data["child"].first["first_name"]
    assert_equal "wonderland",data["child"].first['last_name']
    assert_equal "mad",data["child"].last["first_name"]
    assert_equal "hatter",data["child"].last['last_name']

  end

  test 'should create and update study with multiple linked custom metadata types without entering non-required values' do
    cmt = FactoryBot.create(:family_custom_metadata_type)
    login_as(FactoryBot.create(:person))
    assert_difference('Study.count') do
      assert_difference('CustomMetadata.count') do
        investigation = FactoryBot.create(:investigation, projects: User.current_user.person.projects, contributor: User.current_user.person)
        study_attributes = { title: 'Family', investigation_id: investigation.id }
        cm_attributes = { custom_metadata_attributes: {
          custom_metadata_type_id: cmt.id, data: {
            "dad": { "first_name": "john", "last_name": "liddell" },
            "mom": { "first_name": "lily", "last_name": "liddell" },
            # the not reqiured attributes can be removed
            "child": { "row-template": { "first_name": "alice", "last_name": "liddell" } }
          }
        }
        }
        post :create, params: { study: study_attributes.merge(cm_attributes), sharing: valid_sharing }
      end
    end

    assert study = assigns(:study)
    assert cm = study.custom_metadata
    assert_equal cmt, cm.custom_metadata_type
    assert_equal "john",cm.data["dad"]["first_name"]
    assert_equal "liddell",cm.data["dad"]['last_name']
    assert_equal "lily",cm.data["mom"]["first_name"]
    assert_equal "liddell",cm.data["mom"]["last_name"]
    assert_empty cm.data["child"]
  end

  test 'should create and update study with multiple linked custom metadata types' do
    cmt = FactoryBot.create(:role_multiple_custom_metadata_type)
    login_as(FactoryBot.create(:person))

    # test create
    assert_difference('Study.count') do
      assert_difference('CustomMetadata.count') do
        investigation = FactoryBot.create(:investigation,projects:User.current_user.person.projects,contributor:User.current_user.person)
        study_attributes = { title: 'Alice in Wonderland', investigation_id: investigation.id }
        cm_attributes = { custom_metadata_attributes: {
          custom_metadata_type_id: cmt.id, data: {
            "role_email":"alice@email.com",
            "role_phone":"0012345",
            "role_name": {"first_name":"alice", "last_name": "liddell"},
            "role_address": {"street":"wonder","city": "land" }
          }
        }
        }
        post :create, params: { study: study_attributes.merge(cm_attributes), sharing: valid_sharing }
      end
    end

    assert study = assigns(:study)
    assert cm = study.custom_metadata
    assert_equal cmt, cm.custom_metadata_type
    assert_equal "alice@email.com",cm.data['role_email']
    assert_equal '0012345',cm.data['role_phone']
    assert_equal 'alice', cm.data['role_name']['first_name']
    assert_equal 'liddell', cm.data['role_name']['last_name']
    assert_equal 'wonder', cm.data['role_address']['street']
    assert_equal 'land', cm.data['role_address']['city']

    # test show
    get :show, params:{ id:study}
    assert_response :success


    # test update
    assert_no_difference('Study.count') do
      assert_no_difference('CustomMetadata.count') do
        put :update, params: { id: study.id, study: { title: "Alice Through the Looking Glass",
                                                      custom_metadata_attributes: {
                                                        custom_metadata_type_id: cmt.id, id:cm.id, data: {
                                                          "role_email":"rabbit@email.com",
                                                          "role_name":{
                                                              "first_name":"rabbit"
                                                          }
                                                        }
                                                      }
        }
        }
      end
    end


    assert new_study = assigns(:study)
    assert_equal 'Alice Through the Looking Glass', new_study.title
    cm = new_study.custom_metadata
    assert_equal 'rabbit@email.com', cm.data['role_email']
    assert_equal 'rabbit', cm.data['role_name']['first_name']
  end

  test 'multiple levels of has many relationship' do
    cmt = FactoryBot.create(:study_custom_metadata_type)
    # linked_cmt = cmt.attributes_with_linked_custom_metadata_type.last.linked_custom_metadata_type
    # linked_linked_cmt = linked_cmt.attributes_with_linked_custom_metadata_type.last.linked_custom_metadata_type
    # linked_linked_linked_cmt = linked_linked_cmt.attributes_with_linked_custom_metadata_type.last.linked_custom_metadata_type
    login_as(FactoryBot.create(:person))

    assert_difference('Study.count') do
      assert_difference('CustomMetadata.count') do
        investigation = FactoryBot.create(:investigation,projects:User.current_user.person.projects,contributor:User.current_user.person)
        study_attributes = { title: 'my study', investigation_id: investigation.id }
        cm_attributes = { custom_metadata_attributes: {
          custom_metadata_type_id: cmt.id,
          data: {
            "study_title":"happy study",
            "study_sites":{
              "0":{
                  "study_site_name":"site1",
                  "study_site_location":"fairyland",
                  "participants":{
                    "0":{
                      "participant_name":{
                        "first_name":"alice",
                        "last_name":"liddell"
                      },
                      "participant_age":"7"
                    },
                    "1":{
                      "participant_name":{
                        "first_name":"pippi",
                        "last_name":"langstrumpf"
                      },
                      "participant_age":"9"
                    }
                  }
              },
              "1":{
                "study_site_name":"site2",
                "study_site_location":"space",
                "participants":{
                  "0":{
                    "participant_name":{
                      "first_name":"arthur",
                      "last_name":"Dent"
                    },
                    "participant_age":"40"
                  }
                }
              }
            }
          }
        }
        }
        post :create, params: { study: study_attributes.merge(cm_attributes), sharing: valid_sharing }

      end
    end

    assert study = assigns(:study)
    assert cm = study.custom_metadata

    assert_equal cmt, cm.custom_metadata_type
    assert_equal "happy study",cm.data['study_title']
    assert_equal "site1", cm.data['study_sites'][0]['study_site_name']
    assert_equal "fairyland", cm.data['study_sites'][0]['study_site_location']
    assert_equal "alice", cm.data['study_sites'][0]['participants'][0]['participant_name']['first_name']
    assert_equal "langstrumpf", cm.data['study_sites'][0]['participants'][1]['participant_name']['last_name']
    assert_equal "Dent", cm.data['study_sites'][1]['participants'][0]['participant_name']['last_name']
    assert_equal "40", cm.data['study_sites'][1]['participants'][0]['participant_age']


    # test show
    get :show, params:{ id:study}
    assert_response :success

    # test update
    assert_no_difference('Study.count') do
      assert_no_difference('CustomMetadata.count') do
        put :update, params: {
          id: study.id,
          study: {
            title: 'Updated Study',
            custom_metadata_attributes: {
              id:cm.id,
              custom_metadata_type_id: cmt.id,
              data: {
                "study_title":"happy study new",
                "study_sites":{
                  "0":{
                    "study_site_name":"site1",
                    "study_site_location":"better fairyland",
                    "participants":{
                      "0":{
                        "participant_name":{
                          "first_name":"mad",
                          "last_name":"hatter"
                        },
                        "participant_age":"unknown"
                      },
                      "1":{
                        "participant_name":{
                          "first_name":"pippi",
                          "last_name":"langstrumpf"
                        },
                        "participant_age":"9"
                      }
                    }
                  }
                }
              }
            }
          }
        }
      end
    end

    assert new_study = assigns(:study)
    assert cm = new_study.custom_metadata


    assert_equal "site1", cm.data['study_sites'][0]['study_site_name']
    assert_equal "better fairyland", cm.data['study_sites'][0]['study_site_location']
    assert_equal "mad", cm.data['study_sites'][0]['participants'][0]['participant_name']['first_name']
    assert_equal "hatter", cm.data['study_sites'][0]['participants'][0]['participant_name']['last_name']
    assert_nil cm.data['study_sites'][1]


  end


  test 'when removing the study with the custom metadata, all its related custom metadtas should be destroyed' do
    cmt = FactoryBot.create(:role_affiliation_custom_metadata_type)
    login_as(FactoryBot.create(:person))

    assert_difference('Study.count') do
      assert_difference('CustomMetadata.count') do
        investigation = FactoryBot.create(:investigation,projects:User.current_user.person.projects,contributor:User.current_user.person)
        study_attributes = { title: 'my study', investigation_id: investigation.id }
        cm_attributes = { custom_metadata_attributes: {
          custom_metadata_type_id: cmt.id,
          data: {
            "role_affiliation_name":"HITS",
            "role_affiliation_identifiers":{
              "0":{"identifier":"01f7bcy98", "scheme":"ROR"},
              "1":{"identifier":"grid.424699.4", "scheme":"GRID"}
            }
          }
        }
        }
        post :create, params: { study: study_attributes.merge(cm_attributes), sharing: valid_sharing }

      end
    end

    assert study = assigns(:study)



    assert_difference('Study.count', -1) do
      assert_difference('CustomMetadata.count',-1) do
           delete :destroy, params: { id: study.id }
      end
    end

    assert !flash[:error]
    assert_redirected_to studies_path
  end



  test 'should create and update study whose custom metadata type contains linked custom metadata multi type' do
    cmt = FactoryBot.create(:role_affiliation_custom_metadata_type)
    login_as(FactoryBot.create(:person))


    # test create
    assert_difference('Study.count') do
      assert_difference('CustomMetadata.count') do
        investigation = FactoryBot.create(:investigation,projects:User.current_user.person.projects,contributor:User.current_user.person)
        study_attributes = { title: 'my study', investigation_id: investigation.id }
        cm_attributes = { custom_metadata_attributes: {
          custom_metadata_type_id: cmt.id,
          data: {
            "role_affiliation_name":"HITS",
            "role_affiliation_identifiers":{
              "0":{ "identifier":"01f7bcy98", "scheme":"ROR"},
              "1":{"identifier":"grid.424699.4", "scheme":"GRID"}
            }
          }
        }
        }
        post :create, params: { study: study_attributes.merge(cm_attributes), sharing: valid_sharing }
      end
    end


    assert study = assigns(:study)
    assert_redirected_to study_path(study)
    study.reload


    cm = study.custom_metadata
    assert_equal cmt, cm.custom_metadata_type

    assert_equal 'my study', study.title
    assert_equal 'HITS',cm.data['role_affiliation_name']
    assert_equal '01f7bcy98', cm.data['role_affiliation_identifiers'].first['identifier']
    assert_equal 'ROR', cm.data['role_affiliation_identifiers'].first['scheme']
    assert_equal 'grid.424699.4',cm.data['role_affiliation_identifiers'].last['identifier']
    assert_equal 'GRID', cm.data['role_affiliation_identifiers'].last['scheme']

    # test show
    get :show, params:{ id:study}
    assert_response :success

    # test update
    assert_no_difference('Study.count') do
      assert_no_difference('CustomMetadata.count') do
        put :update, params: {
          id: study.id,
          study: {
            title: 'Updated Study',
            custom_metadata_attributes: {
              id:cm.id,
              custom_metadata_type_id: cmt.id,
              data: {
                "role_affiliation_name": "University of Manchester",
                "role_affiliation_identifiers": {
                  "0": { "identifier": "027m9bs27", "scheme": "ROR"},
                  "1": { "identifier": "grid.5379.8", "scheme": "GRID" }
                }
              }
            }
          }
        }
      end
    end


    assert new_study = assigns(:study)
    assert_redirected_to study_path(new_study)
    new_study.reload
    cm = new_study.custom_metadata
    assert_equal cmt, cm.custom_metadata_type

    assert_equal 'Updated Study', new_study.title
    assert_equal 'University of Manchester',cm.data['role_affiliation_name']
    assert_equal '027m9bs27', cm.data['role_affiliation_identifiers'].first['identifier']
    assert_equal 'ROR', cm.data['role_affiliation_identifiers'].first['scheme']
    assert_equal 'grid.5379.8', cm.data['role_affiliation_identifiers'].last['identifier']
    assert_equal 'GRID', cm.data['role_affiliation_identifiers'].last['scheme']

    # test update: adding an element in the array of linked custom metadatas
    assert_no_difference('Study.count') do
      assert_no_difference('CustomMetadata.count') do
        put :update, params: {
          id: study.id,
          study: {
            title: 'Updated Study',
            custom_metadata_attributes: {
              id:cm.id,
              custom_metadata_type_id: cmt.id,
              data: {
                "role_affiliation_name": "University of Manchester",
                "role_affiliation_identifiers": {
                  "0": { "identifier": "027m9bs27", "scheme": "ROR" },
                  "1": {"identifier": "grid.5379.8", "scheme": "GRID" },
                  "2": { "identifier": "0000 0001 2166 2407", "scheme": "ISNI" }

                }
              }
            }
          }
        }
      end
    end

    assert new_study = assigns(:study)
    assert_redirected_to study_path(new_study)
    new_study.reload
    cm = new_study.custom_metadata
    assert_equal cmt, cm.custom_metadata_type



    assert_equal 'University of Manchester',cm.data['role_affiliation_name']
    assert_equal '027m9bs27', cm.data['role_affiliation_identifiers'][0]['identifier']
    assert_equal 'ROR', cm.data['role_affiliation_identifiers'][0]['scheme']
    assert_equal 'grid.5379.8', cm.data['role_affiliation_identifiers'][1]['identifier']
    assert_equal 'GRID', cm.data['role_affiliation_identifiers'][1]['scheme']
    assert_equal '0000 0001 2166 2407', cm.data['role_affiliation_identifiers'][2]['identifier']
    assert_equal 'ISNI', cm.data['role_affiliation_identifiers'][2]['scheme']


    # test update: adding an element and at the same time removing two elements in the array of linked custom metadatas
    assert_no_difference('Study.count') do
      assert_no_difference('CustomMetadata.count') do

        put :update, params: {
          id: study.id,
          study: {
            title: 'Updated Study',
            custom_metadata_attributes: {
              id:cm.id,
              custom_metadata_type_id: cmt.id,
              data: {
                "role_affiliation_name": "University of Manchester",
                "role_affiliation_identifiers": {
                  "0": { "identifier": "027m9bs27", "scheme": "ROR" },
                  # new element
                  "1": { "identifier": "Q230899", "scheme": "Wikidata" }
                }
              }
            }
          }
        }

      end
    end

    assert new_study = assigns(:study)
    assert_redirected_to study_path(new_study)
    new_study.reload
    cm = new_study.custom_metadata
    assert_equal cmt, cm.custom_metadata_type

    assert_equal 'Updated Study', new_study.title
    assert_equal 'University of Manchester',cm.data['role_affiliation_name']
    assert_equal '027m9bs27', cm.data['role_affiliation_identifiers'][0]['identifier']
    assert_equal 'ROR', cm.data['role_affiliation_identifiers'][0]['scheme']
    assert_equal 'Q230899', cm.data['role_affiliation_identifiers'][1]['identifier']
    assert_equal 'Wikidata', cm.data['role_affiliation_identifiers'][1]['scheme']


  end




  test 'should not create a study and reload the form for incomplete details' do

    cmt = FactoryBot.create(:role_affiliation_custom_metadata_type)
    login_as(FactoryBot.create(:person))


    # missing investigation
    assert_no_difference('Study.count') do
      assert_no_difference('CustomMetadata.count') do
        study_attributes = { title: 'my study' }
        cm_attributes = { custom_metadata_attributes: {
          custom_metadata_type_id: cmt.id,
          data: {
            "role_affiliation_name":"HITS",
            "role_affiliation_identifiers":{
              "0":{"identifier":"01f7bcy98", "scheme":"ROR"},
              "1":{"identifier":"grid.424699.4", "scheme":"GRID"}
            }
          }
        }
        }
        post :create, params: { study: study_attributes.merge(cm_attributes), sharing: valid_sharing }
      end
    end

    # should show error message
    assert_select 'div#error_explanation' do
      assert_select 'ul > li', text: "Investigation is blank or invalid"
    end

    # should reload the form with title
    assert_select 'form#new_study' do
      assert_select 'input#study_title[value=?]', 'my study'
      assert_select 'input#study_custom_metadata_attributes_data_role_affiliation_name[value=?]', 'HITS'
    end

    # should reload the form with two role_affiliation_identifiers
      assert_select 'div[id$="role-0"]' do
      assert_select 'input#study_custom_metadata_attributes_data_role_affiliation_identifiers_0_identifier[value=?]', '01f7bcy98'
      assert_select 'input#study_custom_metadata_attributes_data_role_affiliation_identifiers_0_scheme[value=?]', 'ROR'
    end

    assert_select 'div[id$="role-1"]' do

      assert_select 'input#study_custom_metadata_attributes_data_role_affiliation_identifiers_1_identifier[value=?]', 'grid.424699.4'
      assert_select 'input#study_custom_metadata_attributes_data_role_affiliation_identifiers_1_scheme[value=?]', 'GRID'
    end


    investigation = FactoryBot.create(:investigation,projects:User.current_user.person.projects,contributor:User.current_user.person)

    # missing required custom metadata value
    assert_no_difference('Study.count') do
      assert_no_difference('CustomMetadata.count') do
          study_attributes = { title: 'my study',investigation_id: investigation.id}
          cm_attributes = { custom_metadata_attributes: {
            custom_metadata_type_id: cmt.id,
            data: {
              "role_affiliation_name":"HITS",
              "role_affiliation_identifiers":{
                "0":{"identifier":"", "scheme":"ROR"},
                "1":{"identifier":"grid.424699.4", "scheme":""}
              }
            }
          }
          }
          post :create, params: { study: study_attributes.merge(cm_attributes), sharing: valid_sharing }
      end
    end

    # should show error message
    assert_select 'div#error_explanation' do
      assert_select 'ul > li', text: "Custom metadata role affiliation identifiers 1 identifier is required"
      assert_select 'ul > li', text: "Custom metadata role affiliation identifiers 2 scheme is required"
    end

    # should reload the form with title
    assert_select 'form#new_study' do
      assert_select 'input#study_title[value=?]', 'my study'
      assert_select 'input#study_custom_metadata_attributes_data_role_affiliation_name[value=?]', 'HITS'
    end

    # should reload the form with two role_affiliation_identifiers
    assert_select 'div[id$="role-0"]' do
      assert_select 'input#study_custom_metadata_attributes_data_role_affiliation_identifiers_0_identifier[value=?]', ''
      assert_select 'input#study_custom_metadata_attributes_data_role_affiliation_identifiers_0_scheme[value=?]', 'ROR'
    end

    assert_select 'div[id$="role-1"]' do
      assert_select 'input#study_custom_metadata_attributes_data_role_affiliation_identifiers_1_identifier[value=?]', 'grid.424699.4'
      assert_select 'input#study_custom_metadata_attributes_data_role_affiliation_identifiers_1_scheme[value=?]', ''
    end

  end

  test 'should not update a study and reload the form for incomplete details' do

    cmt = FactoryBot.create(:role_affiliation_custom_metadata_type)
    login_as(FactoryBot.create(:person))
    investigation = FactoryBot.create(:investigation,projects:User.current_user.person.projects,contributor:User.current_user.person)
    study_attributes = { title: 'my study', investigation_id: investigation.id }


    cm_attributes = { custom_metadata_attributes: {
          custom_metadata_type_id: cmt.id,
          data: {
            "role_affiliation_name":"HITS",
            "role_affiliation_identifiers":{
              "0":{"identifier":"01f7bcy98", "scheme":"ROR"},
              "1":{"identifier":"grid.424699.4", "scheme":"GRID"}
            }
          }
        }
        }
    post :create, params: { study: study_attributes.merge(cm_attributes), sharing: valid_sharing }

    assert study = assigns(:study)
    assert_redirected_to study_path(study)
    study.reload
    cm = study.custom_metadata


    #  should not update when the investigation is deleted
    assert_no_difference('Study.count') do
      assert_no_difference('CustomMetadata.count') do
        put :update, params: {
          id: study.id,
          study: {
            title: 'my new study title',
            investigation_id: nil,
            custom_metadata_attributes: {
              id:cm.id,
              custom_metadata_type_id: cmt.id,
              data: {
                "role_affiliation_name": "University of Manchester",
                "role_affiliation_identifiers": {
                  "0": { "identifier": "027m9bs27", "scheme": "ROR" },
                  # remove a previous row
                  # "1": { "identifier": "grid.5379.8", "scheme": "GRID" },

                  # add a new row
                  "2": {"identifier": "Q230899", "scheme": "Wikidata" }
                }
              }
            }
          }
        }
      end
    end

    # the value of study in database should not change
    assert_equal 'my study', study.title
    assert_equal 'HITS',cm.data['role_affiliation_name']
    assert_equal '01f7bcy98', cm.data['role_affiliation_identifiers'][0]['identifier']
    assert_equal 'ROR', cm.data['role_affiliation_identifiers'][0]['scheme']
    assert_equal 'grid.424699.4', cm.data['role_affiliation_identifiers'][1]['identifier']
    assert_equal 'GRID', cm.data['role_affiliation_identifiers'][1]['scheme']


    # should show error message
    assert_select 'div#error_explanation' do
      assert_select 'ul > li', text: "Investigation is blank or invalid"
    end

    # the form should load updated title value
    assert_select 'form.edit_study' do
      assert_select 'input#study_title[value=?]', 'my new study title'
      assert_select 'input#study_custom_metadata_attributes_data_role_affiliation_name[value=?]', 'University of Manchester'
    end

    # the form should load updated role_affiliation_identifiers value
    assert_select 'div[id$="role-0"]' do
      assert_select 'input#study_custom_metadata_attributes_data_role_affiliation_identifiers_0_identifier[value=?]', '027m9bs27'
      assert_select 'input#study_custom_metadata_attributes_data_role_affiliation_identifiers_0_scheme[value=?]', 'ROR'
    end

    # the form should not show removed value
    assert_select 'input[value="grid.5379.8"]', count: 0
    assert_select 'input[value="GRID"]', count: 0

    # the form should show new value
    assert_select "input[id^='study_custom_metadata_attributes_data_role_affiliation_identifiers_'][id$='_identifier'][value=?]",'Q230899'
    assert_select "input[id^='study_custom_metadata_attributes_data_role_affiliation_identifiers_'][id$='_scheme'][value=?]",'Wikidata'

  end

  test 'should not update a study and reload the form for missing required linked custom metadata values' do

    cmt = FactoryBot.create(:role_affiliation_custom_metadata_type)
    login_as(FactoryBot.create(:person))

    investigation = FactoryBot.create(:investigation,projects:User.current_user.person.projects,contributor:User.current_user.person)
    study_attributes = { title: 'my study', investigation_id: investigation.id }


    cm_attributes = { custom_metadata_attributes: {
      custom_metadata_type_id: cmt.id,
      data: {
        "role_affiliation_name":"HITS",
        "role_affiliation_identifiers":{
          "0":{"identifier":"01f7bcy98", "scheme":"ROR"},
          "1":{"identifier":"grid.424699.4", "scheme":"GRID"}
        }
      }
    }
    }
    post :create, params: { study: study_attributes.merge(cm_attributes), sharing: valid_sharing }

    assert study = assigns(:study)
    assert_redirected_to study_path(study)
    study.reload
    cm = study.custom_metadata

    #  should not update when the required linked custom metadata is missing
    assert_no_difference('Study.count') do
      assert_no_difference('CustomMetadata.count') do
          put :update, params: {
            id: study.id,
            study: {
              title: 'my new study title',
              custom_metadata_attributes: {
                id:cm.id,
                custom_metadata_type_id: cmt.id,
                data: {
                  "role_affiliation_name": "University of Manchester",
                  "role_affiliation_identifiers": {
                    "0": { "identifier": "", "scheme": "ROR" },
                    # remove a previous row
                    # "1": {"identifier": "grid.5379.8", "scheme": "GRID" },
                    # add a new row
                    "2": { "identifier": "Q230899", "scheme": "Wikidata" }
                    }
                }
              }
            }
          }
      end
    end

    assert new_study = assigns(:study)


    # the value of study in database should not change
    assert_equal 'my study', study.title
    assert_equal 'HITS',cm.data['role_affiliation_name']
    assert_equal '01f7bcy98', cm.data['role_affiliation_identifiers'][0]['identifier']
    assert_equal 'ROR', cm.data['role_affiliation_identifiers'][0]['scheme']
    assert_equal 'grid.424699.4', cm.data['role_affiliation_identifiers'][1]['identifier']
    assert_equal 'GRID',cm.data['role_affiliation_identifiers'][1]['scheme']

    # should show error message
    assert_select 'div#error_explanation' do
      assert_select 'ul > li', text: "Custom metadata role affiliation identifiers 1 identifier is required"
    end

    # the form should load updated title value
    assert_select 'form.edit_study' do
      assert_select 'input#study_title[value=?]', 'my new study title'
      assert_select 'input#study_custom_metadata_attributes_data_role_affiliation_name[value=?]', 'University of Manchester'
    end

    # the form should load updated role_affiliation_identifiers value
    assert_select 'div[id$="role-0"]' do
      assert_select 'input#study_custom_metadata_attributes_data_role_affiliation_identifiers_0_identifier[value=?]', ''
      assert_select 'input#study_custom_metadata_attributes_data_role_affiliation_identifiers_0_scheme[value=?]', 'ROR'
    end

    # the form should not show removed value
    assert_select 'input[value="grid.5379.8"]', count: 0
    assert_select 'input[value="GRID"]', count: 0

    # the form should show new value
    assert_select "input[id^='study_custom_metadata_attributes_data_role_affiliation_identifiers_'][id$='_identifier'][value=?]",'Q230899'
    assert_select "input[id^='study_custom_metadata_attributes_data_role_affiliation_identifiers_'][id$='_scheme'][value=?]",'Wikidata'


  end


  test 'experimentalists only shown if set' do
    person = FactoryBot.create(:person)
    login_as(person)
    study = FactoryBot.create(:study,experimentalists:'some experimentalists',contributor:person)
    refute study.experimentalists.blank?

    get :edit, params:{id:study}
    assert_response :success

    assert_select 'input#study_experimentalists', count:1

    get :show, params:{id:study}
    assert_response :success

    assert_select 'p',text:/Experimentalists:/,count:1

    study = FactoryBot.create(:study,contributor:person)
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

  test 'should create with discussion link' do
    person = FactoryBot.create(:person)
    login_as(person)
    assert_difference('AssetLink.discussion.count') do
      assert_difference('Study.count') do
        post :create, params: { study: { title: 'test',
                                         investigation_id: FactoryBot.create(:investigation, contributor: person).id,
                                         discussion_links_attributes: [{url: "http://www.slack.com/"}]},
                                policy_attributes: valid_sharing }
      end
    end
    study = assigns(:study)
    assert_equal 'http://www.slack.com/', study.discussion_links.first.url
    assert_equal AssetLink::DISCUSSION, study.discussion_links.first.link_type
  end

  test 'should show discussion link' do
    disc_link = FactoryBot.create(:discussion_link)
    study = FactoryBot.create(:study, contributor: User.current_user.person)
    study.discussion_links = [disc_link]
    get :show, params: { id: study }
    assert_response :success
    assert_select 'div.panel-heading', text: /Discussion Channel/, count: 1
  end

  test 'should update node with discussion link' do
    person = FactoryBot.create(:person)
    study = FactoryBot.create(:study, contributor: person)
    login_as(person)
    assert_nil study.discussion_links.first
    assert_difference('AssetLink.discussion.count') do
      assert_difference('ActivityLog.count') do
        put :update, params: { id: study.id, study: { discussion_links_attributes:[{url: "http://www.slack.com/"}] } }
      end
    end
    assert_redirected_to study_path(assigns(:study))
    assert_equal 'http://www.slack.com/', study.discussion_links.first.url
  end

  test 'should destroy related assetlink when the discussion link is removed ' do
    person = FactoryBot.create(:person)
    login_as(person)
    asset_link = FactoryBot.create(:discussion_link)
    study = FactoryBot.create(:study, contributor: person)
    study.discussion_links = [asset_link]
    assert_difference('AssetLink.discussion.count', -1) do
      put :update, params: { id: study.id, study: { discussion_links_attributes:[{id:asset_link.id, _destroy:'1'}] } }
    end
    assert_redirected_to study_path(study = assigns(:study))
    assert_empty study.discussion_links
  end

  test 'study needs more than one assay for ordering' do
    person = FactoryBot.create(:admin)
    login_as(person)
    study = FactoryBot.create(:study,
                            policy: FactoryBot.create(:public_policy),
                            contributor: person)
    get :show, params: { id: study.id }

    assert_response :success
    assert_select 'a[href=?]',
                  order_assays_study_path(study), count: 0

    study.assays += [FactoryBot.create(:assay,
                                      policy: FactoryBot.create(:public_policy),
                                      contributor: person)]
    get :show, params: { id: study.id }
    assert_response :success
    assert_select 'a[href=?]',
                  order_assays_study_path(study), count: 0

    study.assays +=  [FactoryBot.create(:assay,
                                      policy: FactoryBot.create(:public_policy),
                                      contributor: person)]
    get :show, params: { id: study.id }
    assert_response :success
    assert_select 'a[href=?]',
                  order_assays_study_path(study), count: 1
  end

  test 'ordering only by editor' do
    person = FactoryBot.create(:admin)
    login_as(person)
    study = FactoryBot.create(:study,
                            policy: FactoryBot.create(:all_sysmo_viewable_policy),
                            contributor: person)
    study.assays += [FactoryBot.create(:assay,
                                      policy: FactoryBot.create(:public_policy),
                                      contributor: person)]
    study.assays += [FactoryBot.create(:assay,
                                      policy: FactoryBot.create(:public_policy),
                                      contributor: person)]
    get :show, params: { id: study.id }
    assert_response :success
    assert_select 'a[href=?]',
                  order_assays_study_path(study), count: 1

    login_as(:aaron)
    get :show, params: { id: study.id }
    assert_response :success
    assert_select 'a[href=?]',
                  order_assays_study_path(study), count: 0
  end

  test 'sample type studies through nested routing' do
    person = FactoryBot.create(:person)
    login_as(person)
    assert_routing 'sample_types/2/studies', controller: 'studies', action: 'index', sample_type_id: '2'
    study = FactoryBot.create(:study, contributor: person)
    study2 = FactoryBot.create(:study, contributor: person)
    sample_type = FactoryBot.create(:patient_sample_type, studies: [study], contributor: person)

    assert_equal [study], sample_type.studies
    study.reload
    assert_equal [sample_type], study.sample_types

    get :index, params: { sample_type_id: sample_type.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', study_path(study), text: study.title
      assert_select 'a[href=?]', study_path(study2), text: study2.title, count: 0
    end
  end

  test 'shows "New Investigation" button if no investigations available' do
    Investigation.delete_all
    person = FactoryBot.create(:person)
    login_as(person)
    assert Investigation.authorized_for('view', person.user).none?

    get :new

    assert_select 'a.btn[href=?]', new_investigation_path, count: 1
  end

  test 'does not show "New Investigation" button if investigations available' do
    person = FactoryBot.create(:person)
    login_as(person)
    FactoryBot.create(:investigation, contributor: person)
    assert Investigation.authorized_for('view', person.user).any?

    get :new

    assert_select 'a.btn[href=?]', new_investigation_path, count: 0
  end

  test 'new should include tags element' do
    get :new
    assert_response :success
    assert_select 'div.panel-heading', text: /Tags/, count: 1
    assert_select 'input#tag_list', count: 1
  end

  test 'new should not include tags element when tags disabled' do
    with_config_value :tagging_enabled, false do
      get :new
      assert_response :success
      assert_select 'div.panel-heading', text: /Tags/, count: 0
      assert_select 'input#tag_list', count: 0
    end
  end

  test 'edit should include tags element' do
    study = FactoryBot.create(:study, policy: FactoryBot.create(:public_policy))
    get :edit, params: { id: study.id }
    assert_response :success

    assert_select 'div.panel-heading', text: /Tags/, count: 1
    assert_select 'input#tag_list', count: 1
  end

  test 'edit should not include tags element when tags disabled' do
    with_config_value :tagging_enabled, false do
      study = FactoryBot.create(:study, policy: FactoryBot.create(:public_policy))
      get :edit, params: { id: study.id }
      assert_response :success

      assert_select 'div.panel-heading', text: /Tags/, count: 0
      assert_select 'input#tag_list', count: 0
    end
  end

  test 'show should include tags box' do
    study = FactoryBot.create(:study, policy: FactoryBot.create(:public_policy))
    get :show, params: { id: study.id }
    assert_response :success

    assert_select 'div.panel-heading', text: /Tags/, count: 1
    assert_select 'input#tag_list', count: 1
  end

  test 'show should not include tags box when tags disabled' do
    with_config_value :tagging_enabled, false do
      study = FactoryBot.create(:study, policy: FactoryBot.create(:public_policy))
      get :show, params: { id: study.id }
      assert_response :success

      assert_select 'div.panel-heading', text: /Tags/, count: 0
      assert_select 'input#tag_list', count: 0
    end
  end

  test 'should add tag on creation' do
    person = FactoryBot.create(:person)
    projects = person.person.projects
    investigation = FactoryBot.create(:investigation, projects: projects, contributor: person)
    login_as(person)
    assert_difference('Study.count') do
      put :create, params: { study: { title: 'Study', investigation_id: investigation.id },
                             tag_list: 'my_tag' }
    end
    assert_equal 'my_tag', assigns(:study).tags_as_text_array.first
  end

  test 'should add tag on edit' do
    person = FactoryBot.create(:person)
    study = FactoryBot.create(:study, creator_ids: [person.id])
    login_as(person)
    put :update, params: { id: study.id, study: { title: 'test' }, tag_list: 'my_tag' }
    assert_equal 'my_tag', assigns(:study).tags_as_text_array.first
  end

  test 'should delete empty study with linked sample type' do
    person = FactoryBot.create(:person)
    study_source_sample_type = FactoryBot.create :linked_sample_type, contributor: person
    study_sample_sample_type = FactoryBot.create :linked_sample_type, contributor: person
    study = FactoryBot.create(:study,
                              policy:FactoryBot.create(:private_policy, permissions:[FactoryBot.create(:permission,contributor: person, access_type:Policy::EDITING)]),
                              sample_types: [study_source_sample_type, study_sample_sample_type],
                              contributor: person)

    login_as(person)

    assert_difference('SampleType.count', -2) do
      assert_difference('Study.count', -1) do
        delete :destroy, params: { id: study.id, return_to: '/single_pages/' }
      end
    end
  end

end
