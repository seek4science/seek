require 'test_helper'

class EventsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  include RestTestCases

  def setup
    login_as(:datafile_owner)
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

  test "index should not show contributor or project" do
    e = Factory :event,
                :contributor => Factory(:user, :person => Factory(:person ,:first_name => "Dont", :last_name => "Display Person")),
                :projects => [Factory(:project, :title => "Dont Display Project")],
                :policy => Factory(:public_policy)
    get :index
    assert !(/Dont Display Person/ =~ @response.body)
    assert !(/Dont Display Project/ =~ @response.body)
  end

  test "shouldn't show hidden items in index" do
    login_as(:aaron)
    get :index, :page => "all"
    assert_response :success
    assert_equal assigns(:events).sort_by(&:id), Authorization.authorize_collection("view", assigns(:events), users(:aaron)).sort_by(&:id), "events haven't been authorized properly"
    assert assigns(:events).count < Event.find(:all).count #fails if all events are assigned to @events
  end

  test "should create hidden event by default" do
    post :create, :event => valid_event
    assert !assigns(:event).can_view?(users(:aaron)) #must be a user other than the one you are logged in as
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
    assert_select "h1",:text=>"New Event"
  end

  test "should get unauthorized message" do
    login_as :registered_user_with_no_projects
    get :new
    assert_redirected_to events_path
    assert_not_nil flash[:error]
  end

  test "should create valid event" do
    assert_difference('Event.count', 1) do
      post :create, :event => valid_event
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
    assert_select "h1", /Editing Event:/
  end

  test "should update events title" do
    before = events(:event_with_no_files)
    put :update, :id => before.id, :event => valid_event
    after = assigns :event
    assert_not_equal before.title, after.title
    assert_equal after.title, valid_event[:title]
  end

  test "should not add invisible data_file" do
    e = Factory :event, :contributor => User.current_user
    df = Factory :data_file, :contributor => Factory(:user), :policy => Factory(:private_policy)
    put :update, :id => e.id, :data_file_ids => ["#{df.id}"], :event => {}

    assert_redirected_to e
    assert_equal 0, e.data_files.count
  end

  test "should not lose invisible data_files when updating" do
    e = Factory :event, :contributor => User.current_user,
                :data_files => [Factory(:data_file, :contributor => Factory(:user), :policy => Factory(:private_policy))]
    put :update, :id => e.id, :data_file_ids => []

    assert_redirected_to e
    assert_equal 1, e.data_files.count
  end
end
