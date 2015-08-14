require 'test_helper'

class SnapshotsControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  include MockHelper

  test "can get snapshot preview page" do
    user = Factory(:user)
    investigation = Factory(:investigation, :policy => Factory(:publicly_viewable_policy), :contributor => user.person)
    login_as(user)

    get :new, :investigation_id => investigation

    assert investigation.can_manage?(user)
    assert_response :success
  end

  test "can't get snapshot preview if no manage permissions" do
    user = Factory(:user)
    investigation = Factory(:investigation, :policy => Factory(:publicly_viewable_policy))
    login_as(user)

    get :new, :investigation_id => investigation

    assert !investigation.can_manage?(user)
    assert_redirected_to investigation_path(investigation)
    assert flash[:error].include?('authorized')
  end

  test "can't get snapshot preview if not publicly accessible" do
    user = Factory(:user)
    investigation = Factory(:investigation, :policy => Factory(:private_policy), :contributor => user.person)
    login_as(user)

    get :new, :investigation_id => investigation

    assert investigation.can_manage?(user)
    assert_redirected_to investigation_path(investigation)
    assert flash[:error].include?('accessible')
  end

  test "can create snapshot" do
    user = Factory(:user)
    investigation = Factory(:investigation, :policy => Factory(:publicly_viewable_policy), :contributor => user.person)
    login_as(user)

    assert_difference('Snapshot.count') do
      post :create, :investigation_id => investigation
    end

    assert investigation.can_manage?(user)
    assert_redirected_to investigation_snapshot_path(investigation, assigns(:snapshot).snapshot_number)
  end

  test "can't create snapshot if no manage permissions" do
    user = Factory(:user)
    investigation = Factory(:investigation, :policy => Factory(:publicly_viewable_policy))
    login_as(user)

    assert_no_difference('Snapshot.count') do
      post :create, :investigation_id => investigation
    end

    assert !investigation.can_manage?(user)
    assert_redirected_to investigation_path(investigation)
    assert flash[:error].include?('authorized')
  end

  test "can't create snapshot if not publicly accessible" do
    user = Factory(:user)
    investigation = Factory(:investigation, :policy => Factory(:private_policy), :contributor => user.person)
    login_as(user)

    assert_no_difference('Snapshot.count') do
      post :create, :investigation_id => investigation
    end

    assert investigation.can_manage?(user)
    assert_redirected_to investigation_path(investigation)
    assert flash[:error].include?('accessible')
  end

  test "can get snapshot show page" do
    create_snapshot
    login_as(@user)

    get :show, :investigation_id => @investigation, :id => @snapshot.snapshot_number

    assert_response :success
  end

  test "can mint DOI for snapshot" do
    datacite_mock
    create_snapshot
    login_as(@user)

    post :mint_doi, :investigation_id => @investigation, :id => @snapshot.snapshot_number

    assert_redirected_to investigation_snapshot_path(@investigation, @snapshot.snapshot_number)
    assert assigns(:snapshot).doi
  end

  test "can't mint DOI for snapshot if no manage permissions" do
    datacite_mock
    create_snapshot
    other_user = Factory(:user)
    login_as(other_user)

    post :mint_doi, :investigation_id => @investigation, :id => @snapshot.snapshot_number

    @snapshot = @snapshot.reload
    assert !@investigation.can_manage?(other_user)
    assert_redirected_to investigation_path(@investigation)
    assert @snapshot.doi.nil?
  end

  test "can retrieve Zenodo preivew page" do
    create_snapshot
    login_as(@user)

    get :export_preview, :investigation_id => @investigation, :id => @snapshot.snapshot_number, :code => 'abc'

    assert_response :success
  end

  test "can export snapshot to Zenodo" do
    zenodo_mock
    zenodo_oauth_mock
    create_snapshot
    @snapshot.doi = '123'
    @snapshot.save
    login_as(@user)

    post :export_submit, :investigation_id => @investigation, :id => @snapshot.snapshot_number, :code => 'abc',
         :metadata => { :access_type => 'open', :license => 'CC-BY-4.0' }

    assert_redirected_to investigation_snapshot_path(@investigation, @snapshot.snapshot_number)
    assert !assigns(:snapshot).zenodo_deposition_id.nil?
  end

  test "can't export snapshot to Zenodo if no manage permissions" do
    zenodo_mock
    zenodo_oauth_mock
    create_snapshot
    @snapshot.doi = '123'
    @snapshot.save
    other_user = Factory(:user)
    login_as(other_user)

    post :export_submit, :investigation_id => @investigation, :id => @snapshot.snapshot_number, :code => 'abc',
         :metadata => { :access_type => 'open', :license => 'CC-BY-4.0' }

    @snapshot = @snapshot.reload
    assert_redirected_to investigation_path(@investigation)
    assert @snapshot.zenodo_deposition_id.nil?
  end

  private

  def create_snapshot
    @user = Factory(:user)
    @investigation = Factory(:investigation, :description => 'not blank', :policy => Factory(:publicly_viewable_policy), :contributor => @user.person)
    @snapshot = @investigation.create_snapshot
  end

end
