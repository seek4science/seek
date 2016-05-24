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

  test "can create investigation snapshot" do
    user = Factory(:user)
    investigation = Factory(:investigation, :policy => Factory(:publicly_viewable_policy), :contributor => user.person)
    login_as(user)

    assert_difference('Snapshot.count') do
      post :create, :investigation_id => investigation
    end

    assert investigation.can_manage?(user)
    assert_redirected_to investigation_snapshot_path(investigation, assigns(:snapshot).snapshot_number)
  end

  test "can create study snapshot" do
    user = Factory(:user)
    study = Factory(:study, :policy => Factory(:publicly_viewable_policy), :contributor => user.person)
    login_as(user)

    assert_difference('Snapshot.count') do
      post :create, :study_id => study
    end

    assert study.can_manage?(user)
    assert_redirected_to study_snapshot_path(study, assigns(:snapshot).snapshot_number)
  end

  test "can create assay snapshot" do
    user = Factory(:user)
    assay = Factory(:assay, :policy => Factory(:publicly_viewable_policy), :contributor => user.person)
    login_as(user)

    assert_difference('Snapshot.count') do
      post :create, :assay_id => assay
    end

    assert assay.can_manage?(user)
    assert_redirected_to assay_snapshot_path(assay, assigns(:snapshot).snapshot_number)
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
    create_investigation_snapshot
    login_as(@user)

    get :show, :investigation_id => @investigation, :id => @snapshot.snapshot_number

    assert_response :success
  end

  test "fails gracefully when missing snapshot" do
    create_investigation_snapshot
    login_as(@user)

    get :show, :investigation_id => @investigation, :id => 123

    assert_response :redirect
    assert flash[:error].include?('exist')
  end

  test "can get confirmation when minting DOI for snapshot" do
    datacite_mock
    create_investigation_snapshot
    login_as(@user)

    get :mint_doi_confirm, :investigation_id => @investigation, :id => @snapshot.snapshot_number

    assert_response :success
    assert_nil assigns(:snapshot).doi
  end

  test "can mint DOI for snapshot" do
    datacite_mock
    create_investigation_snapshot
    login_as(@user)

    post :mint_doi, :investigation_id => @investigation, :id => @snapshot.snapshot_number

    assert_redirected_to investigation_snapshot_path(@investigation, @snapshot.snapshot_number)
    assert assigns(:snapshot).doi
  end

  test "can't mint DOI for snapshot if DOI minting disabled" do
    datacite_mock
    create_investigation_snapshot
    login_as(@user)

    with_config_value(:doi_minting_enabled, false) do
      post :mint_doi, :investigation_id => @investigation, :id => @snapshot.snapshot_number
    end

    @snapshot = @snapshot.reload

    assert flash[:error].to_s.include?('minting')
    assert_redirected_to investigation_snapshot_path(@investigation, @snapshot.snapshot_number)
    assert @snapshot.doi.nil?
  end

  test "can't mint DOI for snapshot if not old enough" do
    datacite_mock
    create_investigation_snapshot
    login_as(@user)

    with_config_value(:time_lock_doi_for, 100) do
      post :mint_doi, :investigation_id => @investigation, :id => @snapshot.snapshot_number
    end

    @snapshot = @snapshot.reload

    assert flash[:error].to_s.include?('older')
    assert_redirected_to investigation_snapshot_path(@investigation, @snapshot.snapshot_number)
    assert @snapshot.doi.nil?
  end

  test "can't mint DOI for snapshot if no manage permissions" do
    datacite_mock
    create_investigation_snapshot
    other_user = Factory(:user)
    login_as(other_user)

    post :mint_doi, :investigation_id => @investigation, :id => @snapshot.snapshot_number

    @snapshot = @snapshot.reload
    assert !@investigation.can_manage?(other_user)
    assert_redirected_to investigation_path(@investigation)
    assert @snapshot.doi.nil?
  end

  test "can't get DOI confirmation page when no manage permissions" do
    datacite_mock
    create_investigation_snapshot
    other_user = Factory(:user)
    login_as(other_user)

    get :mint_doi_confirm, :investigation_id => @investigation, :id => @snapshot.snapshot_number

    assert !@investigation.can_manage?(other_user)
    assert_redirected_to investigation_path(@investigation)
  end

  test "error message mentions DataCite when DataCite broken" do
    datacite_mock
    create_investigation_snapshot
    login_as(@user)

    with_config_value(:datacite_url, 'http://idontexist.soup') do
      post :mint_doi, :investigation_id => @investigation, :id => @snapshot.snapshot_number
    end

    @snapshot = @snapshot.reload

    assert flash[:error].to_s.include?('DataCite')
    assert_redirected_to investigation_snapshot_path(@investigation, @snapshot.snapshot_number)
    assert @snapshot.doi.nil?
  end

  test "can retrieve Zenodo preivew page" do
    create_investigation_snapshot
    login_as(@user)

    get :export_preview, :investigation_id => @investigation, :id => @snapshot.snapshot_number, :code => 'abc'

    assert_response :success
  end

  test "can export snapshot to Zenodo" do
    zenodo_mock
    zenodo_oauth_mock
    create_investigation_snapshot
    Factory(:oauth_session, :user_id => @user.id)

    @snapshot.doi = '10.5072/123'
    @snapshot.save
    login_as(@user)

    get :show, :investigation_id => @investigation, :id => @snapshot.snapshot_number
    assert_response :success
    assert_select "a.btn", :text => 'Export to Zenodo', :count => 1

    post :export_submit, :investigation_id => @investigation, :id => @snapshot.snapshot_number, :code => 'abc',
         :metadata => { :access_type => 'open', :license => 'CC-BY-4.0' }

    assert_redirected_to investigation_snapshot_path(@investigation, @snapshot.snapshot_number)
    assert !assigns(:snapshot).zenodo_deposition_id.nil?
    assert !assigns(:snapshot).zenodo_record_url.nil?
  end

  test "can export study snapshot to Zenodo" do
    zenodo_mock
    zenodo_oauth_mock
    create_study_snapshot
    Factory(:oauth_session, :user_id => @user.id)

    @snapshot.doi = '10.5072/123'
    @snapshot.save
    login_as(@user)

    get :show, :study_id => @study, :id => @snapshot.snapshot_number
    assert_response :success
    assert_select "a.btn", :text => 'Export to Zenodo', :count => 1

    post :export_submit, :study_id => @study, :id => @snapshot.snapshot_number, :code => 'abc',
         :metadata => { :access_type => 'open', :license => 'CC-BY-4.0' }

    assert_redirected_to study_snapshot_path(@study, @snapshot.snapshot_number)
    assert !assigns(:snapshot).zenodo_deposition_id.nil?
    assert !assigns(:snapshot).zenodo_record_url.nil?
  end

  test "can export assay snapshot to Zenodo" do
    zenodo_mock
    zenodo_oauth_mock
    create_assay_snapshot
    Factory(:oauth_session, :user_id => @user.id)

    @snapshot.doi = '10.5072/123'
    @snapshot.save
    login_as(@user)

    get :show, :assay_id => @assay, :id => @snapshot.snapshot_number
    assert_response :success
    assert_select "a.btn", :text => 'Export to Zenodo', :count => 1

    post :export_submit, :assay_id => @assay, :id => @snapshot.snapshot_number, :code => 'abc',
         :metadata => { :access_type => 'open', :license => 'CC-BY-4.0' }

    assert_redirected_to assay_snapshot_path(@assay, @snapshot.snapshot_number)
    assert !assigns(:snapshot).zenodo_deposition_id.nil?
    assert !assigns(:snapshot).zenodo_record_url.nil?
  end

  test "redirects to Zenodo auth page if no existing OAuth session" do
    zenodo_mock
    zenodo_oauth_mock
    create_investigation_snapshot

    @snapshot.doi = '10.5072/123'
    @snapshot.save
    login_as(@user)

    assert_empty @user.oauth_sessions.where(:provider => 'Zenodo')

    post :export_submit, :investigation_id => @investigation, :id => @snapshot.snapshot_number, :code => 'abc',
         :metadata => { :access_type => 'open', :license => 'CC-BY-4.0' }

    assert_redirected_to assigns(:zenodo_oauth_client).authorize_url(request.original_url)
  end

  test "can't export snapshot to Zenodo if setting disabled" do
    zenodo_mock
    zenodo_oauth_mock
    create_investigation_snapshot
    Factory(:oauth_session, :user_id => @user.id)

    @snapshot.doi = '10.5072/123'
    @snapshot.save
    login_as(@user)

    with_config_value(:zenodo_publishing_enabled, false) do
      refute @snapshot.can_export_to_zenodo?

      get :show, :investigation_id => @investigation, :id => @snapshot.snapshot_number
      assert_response :success
      assert_select "a.btn", :text => 'Export to Zenodo', :count => 0

      post :export_submit, :investigation_id => @investigation, :id => @snapshot.snapshot_number, :code => 'abc',
           :metadata => { :access_type => 'open', :license => 'CC-BY-4.0' }

      assert_redirected_to investigation_snapshot_path(@investigation, @snapshot.snapshot_number)
      refute flash[:error].blank?
      assert assigns(:snapshot).zenodo_deposition_id.nil?
      assert assigns(:snapshot).zenodo_record_url.nil?
    end
  end

  test "can't export snapshot to Zenodo if no manage permissions" do
    zenodo_mock
    zenodo_oauth_mock
    create_investigation_snapshot
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

  test "error message mentions Zenodo when Zenodo broken" do
    zenodo_mock
    zenodo_oauth_mock
    create_investigation_snapshot
    Factory(:oauth_session, :user_id => @user.id)

    @snapshot.doi = '10.5072/123'
    @snapshot.save
    login_as(@user)

    with_config_value(:zenodo_api_url, 'http://idontexist.soup') do
      post :export_submit, :investigation_id => @investigation, :id => @snapshot.snapshot_number, :code => 'abc',
           :metadata => { :access_type => 'open', :license => 'CC-BY-4.0' }
    end

    @snapshot = @snapshot.reload

    assert flash[:error].to_s.include?('Zenodo')
    assert_redirected_to investigation_snapshot_path(@investigation, @snapshot.snapshot_number)
    assert @snapshot.zenodo_deposition_id.nil?
  end

  test "can delete snapshot without doi" do
    create_investigation_snapshot
    login_as(@user)

    assert_difference('Snapshot.count', -1) do
      delete :destroy, investigation_id: @investigation, id: @snapshot
    end

    assert_redirected_to investigation_path(@investigation)
    assert flash[:notice].include?('deleted')
  end

  test "can't delete snapshot with doi" do
    create_investigation_snapshot
    login_as(@user)
    @snapshot.doi = '10.5072/123'
    @snapshot.save

    assert_no_difference('Snapshot.count') do
      delete :destroy, investigation_id: @investigation, id: @snapshot
    end

    assert_redirected_to investigation_snapshot_path(@investigation, @snapshot)
    assert flash[:error].include?('DOI')
  end

  test "can't delete snapshot without permission" do
    create_investigation_snapshot

    assert_no_difference('Snapshot.count') do
      delete :destroy, investigation_id: @investigation, id: @snapshot
    end

    assert_redirected_to investigation_path(@investigation)
    assert flash[:error].include?('authorized')
  end

  private

  def create_investigation_snapshot
    @user = Factory(:user)
    @investigation = Factory(:investigation, :description => 'not blank', :policy => Factory(:publicly_viewable_policy), :contributor => @user.person)
    @snapshot = @investigation.create_snapshot
  end

  def create_study_snapshot
    @user = Factory(:user)
    @investigation = Factory(:investigation, :description => 'not blank', :policy => Factory(:publicly_viewable_policy), :contributor => @user.person)
    @study = Factory(:study, :description => 'not blank', :policy => Factory(:publicly_viewable_policy), :contributor => @user.person)
    @snapshot = @study.create_snapshot
  end

  def create_assay_snapshot
    @user = Factory(:user)
    @investigation = Factory(:investigation, :description => 'not blank', :policy => Factory(:publicly_viewable_policy), :contributor => @user.person)
    @study = Factory(:study, :description => 'not blank', :policy => Factory(:publicly_viewable_policy), :contributor => @user.person)
    @assay = Factory(:assay, :description => 'not blank', :policy => Factory(:publicly_viewable_policy), :contributor => @user.person)
    @snapshot = @assay.create_snapshot
  end

end
