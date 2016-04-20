require 'test_helper'

class EventsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  include RestTestCases
  include FunctionalAuthorizationTests
  include SharingFormTestHelper

  def setup
    login_as(:datafile_owner)
  end

  def rest_api_test_object
    @object=events(:event_with_no_files)
  end

  def test_title
    get :index
    assert_response :success
    assert_select "title",:text=>/The Sysmo SEEK.*/, :count=>1
  end

  test "should show index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:events)
  end

  test "should have no avatar element in list" do
    e = Factory :event,
                :contributor => Factory(:user, :person => Factory(:person ,:first_name => "Dont", :last_name => "Display Person")),
                :project_ids => [Factory(:project, :title => "Dont Display Project").id],
                :policy => Factory(:public_policy)
    get :index
    assert_select "div.list_items_container" do
      assert_select "div.list_item" do
        assert_select "div.list_item_avatar",:count=>0
      end
    end
  end

  test "index should not show contributor or project" do
    e = Factory :event,
                :contributor => Factory(:user, :person => Factory(:person ,:first_name => "Dont", :last_name => "Display Person")),
                :project_ids => [Factory(:project, :title => "Dont Display Project").id],
                :policy => Factory(:public_policy)
    get :index
    assert !(/Dont Display Person/ =~ @response.body)
    assert !(/Dont Display Project/ =~ @response.body)
  end

  test "shouldn't show hidden items in index" do
    login_as(:aaron)
    get :index, :page => "all"
    assert_response :success
    assert_equal assigns(:events).sort_by(&:id), Event.authorize_asset_collection(assigns(:events), "view",  users(:aaron)).sort_by(&:id), "events haven't been authorized properly"
    assert assigns(:events).count < Event.find(:all).count #fails if all events are assigned to @events
  end

  test "xml for projectless event" do
    id = Factory(:event, :policy => Factory(:public_policy)).id
    get :show, :id => id, :format => "xml"
    perform_api_checks
  end

  test "should show event" do
    get :show, :id => events(:event_with_no_files).id
    assert_response :success
  end

  fixtures :all
  test "should destroy Event" do
    assert_difference('Event.count', -1) do
      delete :destroy, :id => events(:event_with_no_files)
    end
  end

  test "should get new" do
    get :new
    assert_response :success
    assert_select "h1",:text=>"New #{I18n.t('event')}"
  end

  test "should get unauthorized message" do
    login_as :registered_user_with_no_projects
    get :new
    assert_response :redirect
    assert_not_nil flash[:error]
  end

  test "should create valid event" do
    assert_difference('Event.count', 1) do
      post :create, :event => valid_event, :sharing => valid_sharing
    end
  end

  test "should not create invalid event" do
    assert_difference('Event.count', 0) do
      post :create, :event => {}
    end
  end

  test "should not create event with invalid url" do
    event = valid_event
    event[:url] = "--"
    assert_difference('Event.count', 0) do
      post :create, :event => event
    end
  end

  def valid_event
    {:title => "Barn Raising", :start_date => DateTime.now, :end_date => DateTime.now}
  end

  test "should get edit" do
    get :edit, :id => events(:event_with_no_files)
    assert_response :success
    assert_select "h1", /Editing #{I18n.t('event')}:/
  end

  test "should update events title" do
    before = events(:event_with_no_files)
    put :update, :id => before.id, :event => valid_event
    after = assigns :event
    assert_not_equal before.title, after.title
    assert_equal after.title, valid_event[:title]
  end

  #test "should not add invisible data_file" do
  #  e = Factory :event, :contributor => User.current_user
  #  df = Factory :data_file, :contributor => Factory(:user), :policy => Factory(:private_policy)
  #  put :update, :id => e.id, :data_file_ids => ["#{df.id}"], :event => {}
  #
  #  assert_redirected_to e
  #  assert_equal 0, e.data_files.count
  #end
  #
  #test "should not lose invisible data_files when updating" do
  #  e = Factory :event, :contributor => User.current_user,
  #              :data_files => [Factory(:data_file, :contributor => Factory(:user), :policy => Factory(:private_policy))]
  #  put :update, :id => e.id, :data_file_ids => []
  #
  #  assert_redirected_to e
  #  assert_equal 1, e.data_files.count
  #end

  test "should create and show event without end_date" do
    assert_difference('Event.count', 1) do
      post :create, :event => {:title => "Barn Raising", :start_date => DateTime.now},:sharing => valid_sharing
    end
    assert_redirected_to assigns(:event)

    get :show, :id => assigns(:event).id
    assert_response :success

    get :index
    assert_response :success
  end

  test "programme events through nested routing" do
    assert_routing 'programmes/2/events', { controller: 'events' ,action: 'index', programme_id: '2'}
    programme = Factory(:programme)
    event = Factory(:event, projects: programme.projects, policy: Factory(:public_policy))
    event2 = Factory(:event, policy: Factory(:public_policy))

    get :index, programme_id: programme.id

    assert_response :success
    assert_select "div.list_item_title" do
      assert_select "a[href=?]", event_path(event), text: event.title
      assert_select "a[href=?]", event_path(event2), text: event2.title, count: 0
    end
  end
  
  test "should create event with associated data file" do
    data_file = Factory(:data_file)
    assert_difference('Event.count', 1) do
      post :create, :event => valid_event, :sharing => valid_sharing, :data_files => [{id: data_file.id}]
    end

    assert_includes assigns(:event).data_files, data_file
  end
end
