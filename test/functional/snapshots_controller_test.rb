require 'test_helper'

class SnapshotsControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  test "can get snapshot preview page" do
    user = Factory(:user)
    investigation = Factory(:investigation, :policy => Factory(:private_policy), :contributor => user.person)
    login_as(user)

    get :new, :investigation_id => investigation

    assert investigation.can_manage?(user)
    assert_response :success
  end

  test "can't get snapshot preview if no manage permissions" do
    user = Factory(:user)
    investigation = Factory(:investigation, :policy => Factory(:private_policy))
    login_as(user)

    get :new, :investigation_id => investigation

    assert !investigation.can_manage?(user)
    assert_redirected_to investigation_path(investigation)
  end

  test "can create snapshot" do
    user = Factory(:user)
    investigation = Factory(:investigation, :policy => Factory(:private_policy), :contributor => user.person)
    login_as(user)

    assert_difference('Snapshot.count') do
      post :create, :investigation_id => investigation
    end

    assert investigation.can_manage?(user)
    assert_redirected_to investigation_snapshot_path(investigation, assigns(:snapshot).snapshot_number)
  end

  test "can't create snapshot if no manage permissions" do
    user = Factory(:user)
    investigation = Factory(:investigation, :policy => Factory(:private_policy))
    login_as(user)

    assert_no_difference('Snapshot.count') do
      post :create, :investigation_id => investigation
    end

    assert !investigation.can_manage?(user)
    assert_redirected_to investigation_path(investigation)
  end

end
