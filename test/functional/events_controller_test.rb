require 'test_helper'

class EventsControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  include GeneralAuthorizationTestCases
  include SharingFormTestHelper

  def setup
    login_as(:datafile_owner)
    @project = users(:datafile_owner).person.projects.first
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
    event = FactoryBot.create :event, contributor: User.current_user.person
    assert event.can_view?

    get :show, params: { id: event, format: :rdf }

    assert_response :not_acceptable
  end

  test 'should have no avatar element in list' do
    e = FactoryBot.create :event,
                contributor: FactoryBot.create(:person, first_name: 'Dont', last_name: 'Display Person'),
                project_ids: [FactoryBot.create(:project, title: 'Dont Display Project').id],
                policy: FactoryBot.create(:public_policy)
    get :index
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item' do
        assert_select 'div.list_item_avatar', count: 0
      end
    end
  end

  test 'index should not show contributor or project' do
    e = FactoryBot.create :event,
                contributor: FactoryBot.create(:person, first_name: 'Dont', last_name: 'Display Person'),
                project_ids: [FactoryBot.create(:project, title: 'Dont Display Project').id],
                policy: FactoryBot.create(:public_policy)
    get :index

    assert_select '.list_items_container .list_item'
    assert_select '.list_items_container .list_item', text:/Don't Display Person/, count:0
    assert_select '.list_items_container .list_item', text:/Don't Display Project/, count:0
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
    assert_equal 'FR',assigns(:event).country
  end

  test 'should create valid event with country name' do
    assert_difference('Event.count', 1) do
      event_params = valid_event
      event_params[:country]='Germany'
      post :create, params: { event:event_params, sharing: valid_sharing }
    end
    assert_equal 'DE',assigns(:event).country
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
    { title: 'Barn Raising', start_date: DateTime.now, end_date: DateTime.now, project_ids: [@project.id], country:'FR' }
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
  #  e = FactoryBot.create :event, :contributor => User.current_user.person
  #  df = FactoryBot.create :data_file, :contributor => FactoryBot.create(:person), :policy => FactoryBot.create(:private_policy)
  #  put :update, :id => e.id, :data_file_ids => ["#{df.id}"], :event => {}
  #
  #  assert_redirected_to e
  #  assert_equal 0, e.data_files.count
  # end
  #
  # test "should not lose invisible data_files when updating" do
  #  e = FactoryBot.create :event, :contributor => User.current_user,
  #              :data_files => [FactoryBot.create(:data_file, :contributor => FactoryBot.create(:user), :policy => FactoryBot.create(:private_policy))]
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


  test 'create, update and show an event with extended metadata' do
    cmt = FactoryBot.create(:simple_event_extended_metadata_type)

    assert_difference('ActivityLog.count') do
      assert_difference('Event.count') do
        assert_difference('ExtendedMetadata.count') do
          post :create, params: { event: { title: 'Barn Raising', start_date: DateTime.now, project_ids: [@project.id], country:'FR',
                                           extended_metadata_attributes:{ extended_metadata_type_id: cmt.id,
                                                                          data:{ 'age': 22,'name':'fred'}}}
          }
        end
      end
    end

    event = assigns(:event)

    cm = event.extended_metadata
    assert_equal cmt, cm.extended_metadata_type
    assert_equal 'fred',cm.get_attribute_value('name')
    assert_equal 22,cm.get_attribute_value('age')
    assert_nil cm.get_attribute_value('date')

    get :show, params: { id: event }
    assert_response :success

    assert_select 'div.extended_metadata',text:/fred/, count:1
    assert_select 'div.extended_metadata',text:/22/, count:1

    # test update
    old_id = cm.id
    assert_no_difference('Event.count') do
      assert_no_difference('ExtendedMetadata.count') do
        put :update, params: { id: event.id, event: { title: "new title",
                                                      extended_metadata_attributes: { extended_metadata_type_id: cmt.id, id: cm.id,
                                                                                      data: {
                                                                                        "age": 20,
                                                                                        "name": 'max'
                                                                                      } }
        }
        }
      end
    end

    assert new_event = assigns(:event)
    assert_equal 'new title', new_event.title
    assert_equal 'max', new_event.extended_metadata.get_attribute_value('name')
    assert_equal 20, new_event.extended_metadata.get_attribute_value('age')
    assert_equal old_id, new_event.extended_metadata.id
  end

  test 'programme events through nested routing' do
    assert_routing 'programmes/2/events', controller: 'events', action: 'index', programme_id: '2'
    programme = FactoryBot.create(:programme)
    event = FactoryBot.create(:event, projects: programme.projects, policy: FactoryBot.create(:public_policy))
    event2 = FactoryBot.create(:event, policy: FactoryBot.create(:public_policy))

    get :index, params: { programme_id: programme.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', event_path(event), text: event.title
      assert_select 'a[href=?]', event_path(event2), text: event2.title, count: 0
    end
  end

  test 'should create event with associated data file' do
    data_file = FactoryBot.create(:data_file)
    assert_difference('Event.count', 1) do
      post :create, params: { event: valid_event.merge(data_file_ids: [data_file.id]), sharing: valid_sharing }
    end

    assert_includes assigns(:event).data_files, data_file
  end

  test 'should create event and link to document' do
    person = User.current_user.person
    doc = FactoryBot.create(:document, contributor:person)

    assert_difference('Event.count', 1) do
      post :create, params: { event: valid_event.merge(document_ids: [doc.id.to_s]), sharing: valid_sharing }
    end

    assert event = assigns(:event)
    assert_equal [doc],event.documents
  end

  test 'should not create event with link to none visible document' do
    doc = FactoryBot.create(:document)
    refute doc.can_view?

    assert_no_difference('Event.count') do
      post :create, params: { event: valid_event.merge(document_ids: [doc.id.to_s]), sharing: valid_sharing }
    end

  end

  test 'should update with link to document' do
    person = User.current_user.person
    doc = FactoryBot.create(:document, contributor:person)
    event = FactoryBot.create(:event,documents:[FactoryBot.create(:document,contributor:person)],contributor:person)
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
    person = FactoryBot.create(:person)
    event = FactoryBot.create(:event, contributor:person)
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

    assert_select 'div#author-form', count:0
  end

  test 'cannot access manage page with edit rights' do
    person = FactoryBot.create(:person)
    event = FactoryBot.create(:event, policy:FactoryBot.create(:private_policy, permissions:[FactoryBot.create(:permission, contributor:person, access_type:Policy::EDITING)]))
    login_as(person)
    assert event.can_edit?
    refute event.can_manage?
    get :manage, params: {id:event}
    assert_redirected_to event
    refute_nil flash[:error]
  end

  test 'manage_update' do
    proj1=FactoryBot.create(:project)
    proj2=FactoryBot.create(:project)
    person = FactoryBot.create(:person,project:proj1)
    other_person = FactoryBot.create(:person)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!

    event = FactoryBot.create(:event, contributor:person, projects:[proj1], policy:FactoryBot.create(:private_policy))

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
    proj1=FactoryBot.create(:project)
    proj2=FactoryBot.create(:project)
    person = FactoryBot.create(:person, project:proj1)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!

    other_person = FactoryBot.create(:person)


    event = FactoryBot.create(:event, projects:[proj1], policy:FactoryBot.create(:private_policy,
                                                                           permissions:[FactoryBot.create(:permission,contributor:person, access_type:Policy::EDITING)]))

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

  test 'should not duplicate related programmes' do
    person = FactoryBot.create(:admin)
    login_as(person)
    projects = [FactoryBot.create(:project),FactoryBot.create(:project)]
    programme = FactoryBot.create(:programme,projects:projects)
    event = FactoryBot.create(:event, projects:projects, policy:FactoryBot.create(:public_policy))

    get :show, params: { id: event }
    assert_response :success

    assert_select('div.related-items div#programmes div.list_item_title a[href=?]',programme_path(programme),count:1)
  end

  test 'do not get index if feature disabled' do
    with_config_value(:events_enabled, false) do
      get :index
      assert_redirected_to root_path
      assert flash[:error].include?('disabled')
    end
  end
end
