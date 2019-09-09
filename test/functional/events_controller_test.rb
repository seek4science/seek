require 'test_helper'

class EventsControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  include RestTestCases
  include GeneralAuthorizationTestCases
  include SharingFormTestHelper

  def setup
    login_as(:datafile_owner)
    @project = users(:datafile_owner).person.projects.first
  end

  def rest_api_test_object
    @object = events(:event_with_no_files)
  end

  def test_title
    get :index
    assert_response :success
    assert_select 'title', text: /Events/, count: 1
  end

  test 'should show index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:events)
  end

  test 'should return 406 when requesting RDF' do
    event = Factory :event, contributor: User.current_user.person
    assert event.can_view?

    get :show, params: { id: event, format: :rdf }

    assert_response :not_acceptable
  end

  test 'should have no avatar element in list' do
    e = Factory :event,
                contributor: Factory(:person, first_name: 'Dont', last_name: 'Display Person'),
                project_ids: [Factory(:project, title: 'Dont Display Project').id],
                policy: Factory(:public_policy)
    get :index
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item' do
        assert_select 'div.list_item_avatar', count: 0
      end
    end
  end

  test 'index should not show contributor or project' do
    e = Factory :event,
                contributor: Factory(:person, first_name: 'Dont', last_name: 'Display Person'),
                project_ids: [Factory(:project, title: 'Dont Display Project').id],
                policy: Factory(:public_policy)
    get :index
    assert !(/Dont Display Person/ =~ @response.body)
    assert !(/Dont Display Project/ =~ @response.body)
  end

  test "shouldn't show hidden items in index" do
    login_as(:aaron)
    get :index, params: { page: 'all' }
    assert_response :success
    assert_equal assigns(:events).sort_by(&:id),
                 assigns(:events).authorized_for('view', users(:aaron)).sort_by(&:id), "events haven't been authorized properly"
    assert assigns(:events).count < Event.count # fails if all events are assigned to @events
  end

  test 'should show event' do
    get :show, params: { id: events(:event_with_no_files).id }
    assert_response :success
  end

  fixtures :all
  test 'should destroy Event' do
    assert_difference('Event.count', -1) do
      delete :destroy, params: { id: events(:event_with_no_files) }
    end
  end

  test 'should get new' do
    get :new
    assert_response :success
    assert_select 'h1', text: "New #{I18n.t('event')}"
  end

  test 'should get unauthorized message' do
    login_as :registered_user_with_no_projects
    get :new
    assert_response :redirect
    assert_not_nil flash[:error]
  end

  test 'should create valid event' do
    assert_difference('Event.count', 1) do
      post :create, params: { event: valid_event, sharing: valid_sharing }
    end
  end

  test 'should not create invalid event' do
    assert_difference('Event.count', 0) do
      post :create, params: { event: { title: nil } }
    end
  end

  test 'should not create event with invalid url' do
    event = valid_event
    event[:url] = '--'
    assert_difference('Event.count', 0) do
      post :create, params: { event: event }
    end
  end

  def valid_event
    { title: 'Barn Raising', start_date: DateTime.now, end_date: DateTime.now, project_ids: [@project.id] }
  end

  test 'should get edit' do
    get :edit, params: { id: events(:event_with_no_files) }
    assert_response :success
    assert_select 'h1', /Editing #{I18n.t('event')}:/
  end

  test 'should update events title' do
    before = events(:event_with_no_files)
    put :update, params: { id: before.id, event: valid_event }
    after = assigns :event
    assert_not_equal before.title, after.title
    assert_equal after.title, valid_event[:title]
  end

  # test "should not add invisible data_file" do
  #  e = Factory :event, :contributor => User.current_user.person
  #  df = Factory :data_file, :contributor => Factory(:person), :policy => Factory(:private_policy)
  #  put :update, :id => e.id, :data_file_ids => ["#{df.id}"], :event => {}
  #
  #  assert_redirected_to e
  #  assert_equal 0, e.data_files.count
  # end
  #
  # test "should not lose invisible data_files when updating" do
  #  e = Factory :event, :contributor => User.current_user,
  #              :data_files => [Factory(:data_file, :contributor => Factory(:user), :policy => Factory(:private_policy))]
  #  put :update, :id => e.id, :data_file_ids => []
  #
  #  assert_redirected_to e
  #  assert_equal 1, e.data_files.count
  # end

  test 'should create and show event without end_date' do
    assert_difference('Event.count', 1) do
      post :create, params: { event: { title: 'Barn Raising', start_date: DateTime.now, project_ids: [@project.id] }, sharing: valid_sharing }
    end
    assert_redirected_to assigns(:event)

    get :show, params: { id: assigns(:event).id }
    assert_response :success

    get :index
    assert_response :success
  end

  test 'programme events through nested routing' do
    assert_routing 'programmes/2/events', controller: 'events', action: 'index', programme_id: '2'
    programme = Factory(:programme)
    event = Factory(:event, projects: programme.projects, policy: Factory(:public_policy))
    event2 = Factory(:event, policy: Factory(:public_policy))

    get :index, params: { programme_id: programme.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', event_path(event), text: event.title
      assert_select 'a[href=?]', event_path(event2), text: event2.title, count: 0
    end
  end

  test 'should create event with associated data file' do
    data_file = Factory(:data_file)
    assert_difference('Event.count', 1) do
      post :create, params: { event: valid_event.merge(data_file_ids: [data_file.id]), sharing: valid_sharing }
    end

    assert_includes assigns(:event).data_files, data_file
  end

  test 'should create event and link to document' do
    person = User.current_user.person
    doc = Factory(:document, contributor:person)

    assert_difference('Event.count', 1) do
      post :create, params: { event: valid_event.merge(document_ids: [doc.id.to_s]), sharing: valid_sharing }
    end

    assert event = assigns(:event)
    assert_equal [doc],event.documents
  end

  test 'should not create event with link to none visible document' do
    doc = Factory(:document)
    refute doc.can_view?

    assert_no_difference('Event.count') do
      post :create, params: { event: valid_event.merge(document_ids: [doc.id.to_s]), sharing: valid_sharing }
    end

  end

  test 'should update with link to document' do
    person = User.current_user.person
    doc = Factory(:document, contributor:person)
    event = Factory(:event,documents:[Factory(:document,contributor:person)],contributor:person)
    refute_empty event.documents
    refute_includes event.documents, doc
    put :update, params: { id: event.id, event: {document_ids:[doc.id.to_s]} }
    assert event = assigns(:event)
    assert_equal [doc],event.documents
  end

  test 'manage menu item appears according to permission' do
    check_manage_edit_menu_for_type('event')
  end

  test 'can access manage page with manage rights' do
    person = Factory(:person)
    event = Factory(:event, contributor:person)
    login_as(person)
    assert event.can_manage?
    get :manage, params: {id: event}
    assert_response :success

    # check the project form exists, studies and assays don't have this
    assert_select 'div#add_projects_form', count:1

    # check sharing form exists
    assert_select 'div#sharing_form', count:1

    # should be a temporary sharing link
    assert_select 'div#temporary_links', count:1

    assert_select 'div#author_form', count:0
  end

  test 'cannot access manage page with edit rights' do
    person = Factory(:person)
    event = Factory(:event, policy:Factory(:private_policy, permissions:[Factory(:permission, contributor:person, access_type:Policy::EDITING)]))
    login_as(person)
    assert event.can_edit?
    refute event.can_manage?
    get :manage, params: {id:event}
    assert_redirected_to event
    refute_nil flash[:error]
  end

  test 'manage_update' do
    proj1=Factory(:project)
    proj2=Factory(:project)
    person = Factory(:person,project:proj1)
    other_person = Factory(:person)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!

    event = Factory(:event, contributor:person, projects:[proj1], policy:Factory(:private_policy))

    login_as(person)
    assert event.can_manage?

    patch :manage_update, params: {id: event,
                                   event: {
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    assert_redirected_to event

    event.reload
    assert_equal [proj1,proj2],event.projects.sort_by(&:id)
    assert_equal Policy::VISIBLE,event.policy.access_type
    assert_equal 1,event.policy.permissions.count
    assert_equal other_person,event.policy.permissions.first.contributor
    assert_equal Policy::MANAGING,event.policy.permissions.first.access_type

  end

  test 'manage_update fails without manage rights' do
    proj1=Factory(:project)
    proj2=Factory(:project)
    person = Factory(:person, project:proj1)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!

    other_person = Factory(:person)


    event = Factory(:event, projects:[proj1], policy:Factory(:private_policy,
                                                                           permissions:[Factory(:permission,contributor:person, access_type:Policy::EDITING)]))

    login_as(person)
    refute event.can_manage?
    assert event.can_edit?

    assert_equal [proj1],event.projects

    patch :manage_update, params: {id: event,
                                   event: {
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    refute_nil flash[:error]

    event.reload
    assert_equal [proj1],event.projects
    assert_equal Policy::PRIVATE,event.policy.access_type
    assert_equal 1,event.policy.permissions.count
    assert_equal person,event.policy.permissions.first.contributor
    assert_equal Policy::EDITING,event.policy.permissions.first.access_type

  end


end
