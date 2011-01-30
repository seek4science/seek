require 'test_helper'

class EventsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  include RestTestCases

  def setup
    login_as(:datafile_owner)
    @object=events(:event_with_no_files)
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

  def valid_event
    {:title => "Barn Raising"}
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
end
