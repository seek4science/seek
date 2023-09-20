require 'test_helper'

class SnapshotsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  include MockHelper

  setup do
    doi_citation_mock
  end

  test 'should return 406 when requesting RDF' do
    create_assay_snapshot
    get :show, params: { assay_id: @assay.id, id: @snapshot.snapshot_number, format: :rdf }

    assert_response :not_acceptable
  end

  test 'can get snapshot preview page' do
    user = FactoryBot.create(:user)
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:publicly_viewable_policy), contributor: user.person)
    login_as(user)

    get :new, params: { investigation_id: investigation }

    assert investigation.can_manage?(user)
    assert_response :success
  end

  test "can't get snapshot preview if no manage permissions" do
    user = FactoryBot.create(:user)
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:publicly_viewable_policy))
    login_as(user)

    get :new, params: { investigation_id: investigation }

    assert !investigation.can_manage?(user)
    assert_redirected_to investigation_path(investigation)
    assert flash[:error].include?('authorized')
  end

  test "can't get snapshot preview if not publicly accessible" do
    user = FactoryBot.create(:user)
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:private_policy), contributor: user.person)
    login_as(user)

    get :new, params: { investigation_id: investigation }

    assert investigation.can_manage?(user)
    assert_redirected_to investigation_path(investigation)
    assert flash[:error].include?('accessible')
  end

  test 'can create investigation snapshot' do
    user = FactoryBot.create(:user)
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:publicly_viewable_policy), contributor: user.person)
    login_as(user)

    assert_difference('Snapshot.count') do
      post :create, params: { investigation_id: investigation, snapshot: empty_snapshot }
    end

    assert investigation.can_manage?(user)
    assert_redirected_to investigation_snapshot_path(investigation, assigns(:snapshot).snapshot_number)
  end

  test 'can create study snapshot' do
    user = FactoryBot.create(:user)
    study = FactoryBot.create(:study, policy: FactoryBot.create(:publicly_viewable_policy), contributor: user.person)
    login_as(user)

    assert_difference('Snapshot.count') do
      post :create, params: { study_id: study, snapshot: empty_snapshot }
    end

    assert study.can_manage?(user)
    assert_redirected_to study_snapshot_path(study, assigns(:snapshot).snapshot_number)
  end

  test 'can create assay snapshot' do
    user = FactoryBot.create(:user)
    assay = FactoryBot.create(:assay, policy: FactoryBot.create(:publicly_viewable_policy), contributor: user.person)
    login_as(user)

    assert_difference('Snapshot.count') do
      post :create, params: { assay_id: assay, snapshot: empty_snapshot }
    end

    assert assay.can_manage?(user)
    assert_redirected_to assay_snapshot_path(assay, assigns(:snapshot).snapshot_number)
  end

  test 'snapshot title saved correctly' do
    user = FactoryBot.create(:user)
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:publicly_viewable_policy), contributor: user.person)
    login_as(user)
    assert_difference('Snapshot.count') do
      post :create, params: { investigation_id: investigation, 
                              snapshot: { title: 'MyTitle', description: 'Some info' } }
    end
    assert_equal 'MyTitle', investigation.snapshots.last.title
    assert_equal 'Some info', investigation.snapshots.last.description
  end

  test 'snapshot title and description correctly displayed' do
    user = FactoryBot.create(:user)
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:publicly_viewable_policy), 
                                      contributor: user.person, description: 'Not a snapshot', title: 'My Investigation')
    login_as(user)
    post :create, params: { investigation_id: investigation,
                            snapshot: { title: 'My first snapshot', description: 'Some info' } }
    post :create, params: { investigation_id: investigation,
                            snapshot: { title: 'My second snapshot', description: 'Other info' } }
    post :create, params: { investigation_id: investigation, snapshot: empty_snapshot }

    get :show, params: { investigation_id: investigation, id: 1 }
    assert_response :success
    assert_select 'h1', 'My first snapshot'
    assert_select 'div#description', 'Some info'
    assert_select 'div#snapshots' do
      assert_select 'strong', 'My first snapshot'
      assert_select 'a[href=?]', investigation_snapshot_path(investigation, 2), text: 'My second snapshot'
      assert_select 'a[data-tooltip=?]', 'Other info'
      assert_select 'a[href=?]', investigation_snapshot_path(investigation, 3), text: 'Snapshot 3'
    end
  end

  test 'snapshot shows captured state' do
    user = FactoryBot.create(:user)
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:publicly_viewable_policy),
                                      contributor: user.person, title: 'Old Title', description: 'Old description')
    login_as(user)
    post :create, params: { investigation_id: investigation,
                            snapshot: { title: 'My snapshot', description: 'Snapshot info' } }
    investigation.update(title: 'New title', description: 'New description')
    get :show, params: { investigation_id: investigation, id: 1 }
    assert_response :success
    assert_select 'h1', 'My snapshot'
    assert_select 'div#description', 'Snapshot info'
    assert_select 'div.panel-body' do
      assert_select 'h1', 'Old Title'
      assert_select 'div#description', 'Old description'
    end
  end

  test "can't create snapshot if no manage permissions" do
    user = FactoryBot.create(:user)
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:publicly_viewable_policy))
    login_as(user)

    assert_no_difference('Snapshot.count') do
      post :create, params: { investigation_id: investigation }
    end

    assert !investigation.can_manage?(user)
    assert_redirected_to investigation_path(investigation)
    assert flash[:error].include?('authorized')
  end

  test "can't create snapshot if not publicly accessible" do
    user = FactoryBot.create(:user)
    investigation = FactoryBot.create(:investigation, policy: FactoryBot.create(:private_policy), contributor: user.person)
    login_as(user)

    assert_no_difference('Snapshot.count') do
      post :create, params: { investigation_id: investigation }
    end

    assert investigation.can_manage?(user)
    assert_redirected_to investigation_path(investigation)
    assert flash[:error].include?('accessible')
  end

  test 'can get snapshot show page' do
    create_investigation_snapshot
    login_as(@user)

    get :show, params: { investigation_id: @investigation, id: @snapshot.snapshot_number }

    assert_response :success
  end

  test 'fail gracefully for snapshot with no blob' do
    create_investigation_snapshot
    assert @snapshot.content_blob.destroy
    @snapshot.reload

    assert_nil @snapshot.content_blob
    login_as(@user)

    get :show, params: { investigation_id: @investigation, id: @snapshot.snapshot_number }
    assert_response :success
    assert_select 'div.alert-warning' do
      assert_select 'p', text:/cannot currently be displayed as it is incomplete/
      assert_select 'a[href=?]', investigation_path(@investigation), text:@investigation.title
    end

    get :show, params: { investigation_id: @investigation, id: @snapshot.snapshot_number, format: :json }
    assert_response :unprocessable_entity
    expected = { errors: [{ title: 'Incomplete snapshot', details: 'Snapshot has no content. It may still be being generated' }] }.with_indifferent_access
    assert_equal expected , JSON.parse(@response.body)
  end

  test 'fails gracefully when missing snapshot' do
    create_investigation_snapshot
    login_as(@user)

    get :show, params: { investigation_id: @investigation, id: 123 }

    assert_response :redirect
    assert flash[:error].include?('exist')
  end

  test 'edit button is shown for authorized users' do
    create_investigation_snapshot
    login_as(@user)
    get :show, params: { investigation_id: @investigation, id: @snapshot.snapshot_number }
    assert_select 'a', text: 'Edit'
  end

  test 'edit button not shown for unauthorized users' do
    create_investigation_snapshot
    login_as(FactoryBot.create(:user))
    get :show, params: { investigation_id: @investigation, id: @snapshot.snapshot_number }
    assert_select 'a', text: 'Edit', count: 0
  end

  test 'edit button not shown for snapshots with DOI' do
    create_investigation_snapshot
    login_as(@user)
    @snapshot.doi = '10.5072/123'
    @snapshot.save
    get :show, params: { investigation_id: @investigation, id: @snapshot.snapshot_number }
    assert_select 'a', text: 'Edit', count: 0
  end

  test 'authorized users can edit snapshot title and description' do
    create_investigation_snapshot
    login_as(@user)
    get :edit, params: { investigation_id: @investigation, id: @snapshot.snapshot_number }
    assert_response :success
  end

  test "unauthorized user can't edit snapshot" do
    create_investigation_snapshot
    login_as(FactoryBot.create(:user))
    get :edit, params: { investigation_id: @investigation, id: @snapshot.snapshot_number }
    assert_redirected_to investigation_path(@investigation)
    assert flash[:error]
  end

  test "can't edit snapshot with DOI" do
    create_investigation_snapshot
    login_as(@user)
    @snapshot.doi = '10.5072/123'
    @snapshot.save
    get :edit, params: { investigation_id: @investigation, id: @snapshot.snapshot_number }
    assert_redirected_to investigation_snapshot_path(@investigation, @snapshot)
    assert flash[:error].include?('DOI')
  end

  test 'authorized users can update snapshot' do
    create_investigation_snapshot
    login_as(@user)
    put :update, params: { investigation_id: @investigation, id: @snapshot.snapshot_number,
                           snapshot: { title: 'My mod snapshot', description: 'Snapshot mod info' } }
    assert_redirected_to investigation_snapshot_path(@investigation, @snapshot)
    @snapshot.reload
    assert_equal 'My mod snapshot', @snapshot.title
    assert_equal 'Snapshot mod info', @snapshot.description
  end

  test "unauthorized users can't update snapshot" do
    create_investigation_snapshot
    login_as(FactoryBot.create(:user))
    put :update, params: { investigation_id: @investigation, id: @snapshot.snapshot_number,
                           snapshot: { title: 'My mod snapshot', description: 'Snapshot mod info' } }
    assert_redirected_to investigation_path(@investigation)
    assert flash[:error]
  end

  test "can't update snapshot with doi" do
    create_investigation_snapshot
    login_as(@user)
    @snapshot.doi = '10.5072/123'
    @snapshot.save
    put :update, params: { investigation_id: @investigation, id: @snapshot.snapshot_number,
                           snapshot: { title: 'My mod snapshot', description: 'Snapshot mod info' } }
    assert_redirected_to investigation_snapshot_path(@investigation, @snapshot)
    assert flash[:error].include?('DOI')
  end

  test 'can get confirmation when minting DOI for snapshot' do
    datacite_mock
    create_investigation_snapshot
    login_as(@user)

    get :mint_doi_confirm, params: { investigation_id: @investigation, id: @snapshot.snapshot_number }

    assert_response :success
    assert_nil assigns(:snapshot).doi
  end

  test 'can mint DOI for snapshot' do
    datacite_mock
    create_investigation_snapshot
    login_as(@user)

    post :mint_doi, params: { investigation_id: @investigation, id: @snapshot.snapshot_number }

    assert_redirected_to investigation_snapshot_path(@investigation, @snapshot.snapshot_number)
    assert assigns(:snapshot).doi
  end

  test 'logs user when minting DOI for snapshot' do
    datacite_mock
    create_investigation_snapshot
    login_as(@user)

    assert_equal 0, @snapshot.doi_logs.count

    assert_difference('AssetDoiLog.count', 1) do
      post :mint_doi, params: { investigation_id: @investigation, id: @snapshot.snapshot_number }
    end

    assert_equal 1, @snapshot.doi_logs.count
    log = @snapshot.doi_logs.last
    assert_equal @user, log.user
  end

  test "can't mint DOI for snapshot if DOI minting disabled" do
    datacite_mock
    create_investigation_snapshot
    login_as(@user)

    with_config_value(:doi_minting_enabled, false) do
      post :mint_doi, params: { investigation_id: @investigation, id: @snapshot.snapshot_number }
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
      post :mint_doi, params: { investigation_id: @investigation, id: @snapshot.snapshot_number }
    end

    @snapshot = @snapshot.reload

    assert flash[:error].to_s.include?('older')
    assert_redirected_to investigation_snapshot_path(@investigation, @snapshot.snapshot_number)
    assert @snapshot.doi.nil?
  end

  test "can't mint DOI for snapshot if no manage permissions" do
    datacite_mock
    create_investigation_snapshot
    other_user = FactoryBot.create(:user)
    login_as(other_user)

    post :mint_doi, params: { investigation_id: @investigation, id: @snapshot.snapshot_number }

    @snapshot = @snapshot.reload
    assert !@investigation.can_manage?(other_user)
    assert_redirected_to investigation_path(@investigation)
    assert @snapshot.doi.nil?
  end

  test "can't get DOI confirmation page when no manage permissions" do
    datacite_mock
    create_investigation_snapshot
    other_user = FactoryBot.create(:user)
    login_as(other_user)

    get :mint_doi_confirm, params: { investigation_id: @investigation, id: @snapshot.snapshot_number }

    assert !@investigation.can_manage?(other_user)
    assert_redirected_to investigation_path(@investigation)
  end

  test 'error message mentions DataCite when DataCite broken' do
    datacite_mock
    create_investigation_snapshot
    login_as(@user)
    stub_request(:post, 'http://idontexist.soup/metadata').with(basic_auth: ['test', 'test']).to_return(status: 500)

    with_config_value(:datacite_url, 'http://idontexist.soup') do
      post :mint_doi, params: { investigation_id: @investigation, id: @snapshot.snapshot_number }
    end

    @snapshot = @snapshot.reload

    assert flash[:error].to_s.include?('DataCite')
    assert_redirected_to investigation_snapshot_path(@investigation, @snapshot.snapshot_number)
    assert @snapshot.doi.nil?
  end

  test 'can retrieve Zenodo preivew page' do
    create_investigation_snapshot
    login_as(@user)

    get :export_preview, params: { investigation_id: @investigation, id: @snapshot.snapshot_number, code: 'abc' }

    assert_response :success
  end

  test 'can export snapshot to Zenodo' do
    zenodo_mock
    zenodo_oauth_mock
    create_investigation_snapshot
    FactoryBot.create(:oauth_session, user_id: @user.id)

    @snapshot.doi = '10.5072/123'
    @snapshot.save
    login_as(@user)

    get :show, params: { investigation_id: @investigation, id: @snapshot.snapshot_number }
    assert_response :success
    assert_select 'a.btn', text: 'Export to Zenodo', count: 1

    post :export_submit, params: { investigation_id: @investigation, id: @snapshot.snapshot_number, code: 'abc',
                                   metadata: { access_type: 'open',
                                               license: 'CC-BY-4.0',
                                               embargo_date: 3.years.from_now,
                                               access_conditions: 'Must wear blindfold',
                                               creators: [{ name: 'Bob' }] } }

    assert_redirected_to investigation_snapshot_path(@investigation, @snapshot.snapshot_number)
    assert !assigns(:snapshot).zenodo_deposition_id.nil?
    assert !assigns(:snapshot).zenodo_record_url.nil?
  end

  test 'can export snapshot to Zenodo without DOI' do
    zenodo_mock
    zenodo_oauth_mock
    create_investigation_snapshot
    FactoryBot.create(:oauth_session, user_id: @user.id)
    assert_nil @snapshot.doi

    login_as(@user)

    get :show, params: { investigation_id: @investigation, id: @snapshot.snapshot_number }
    assert_response :success
    assert_select 'a.btn', text: 'Export to Zenodo', count: 1

    post :export_submit, params: { investigation_id: @investigation, id: @snapshot.snapshot_number, code: 'abc', metadata: { access_type: 'open', license: 'CC-BY-4.0' } }

    assert_redirected_to investigation_snapshot_path(@investigation, @snapshot.snapshot_number)
    refute_nil assigns(:snapshot).zenodo_deposition_id
    refute_nil assigns(:snapshot).zenodo_record_url
    refute_nil assigns(:snapshot).doi
  end

  test 'can export study snapshot to Zenodo' do
    zenodo_mock
    zenodo_oauth_mock
    create_study_snapshot
    FactoryBot.create(:oauth_session, user_id: @user.id)

    @snapshot.doi = '10.5072/123'
    @snapshot.save
    login_as(@user)

    get :show, params: { study_id: @study, id: @snapshot.snapshot_number }
    assert_response :success
    assert_select 'a.btn', text: 'Export to Zenodo', count: 1

    post :export_submit, params: { study_id: @study, id: @snapshot.snapshot_number, code: 'abc', metadata: { access_type: 'open', license: 'CC-BY-4.0' } }

    assert_redirected_to study_snapshot_path(@study, @snapshot.snapshot_number)
    assert !assigns(:snapshot).zenodo_deposition_id.nil?
    assert !assigns(:snapshot).zenodo_record_url.nil?
  end

  test 'can export assay snapshot to Zenodo' do
    zenodo_mock
    zenodo_oauth_mock
    create_assay_snapshot
    FactoryBot.create(:oauth_session, user_id: @user.id)

    @snapshot.doi = '10.5072/123'
    @snapshot.save
    login_as(@user)

    get :show, params: { assay_id: @assay, id: @snapshot.snapshot_number }
    assert_response :success
    assert_select 'a.btn', text: 'Export to Zenodo', count: 1

    post :export_submit, params: { assay_id: @assay, id: @snapshot.snapshot_number, code: 'abc', metadata: { access_type: 'open', license: 'CC-BY-4.0' } }

    assert_redirected_to assay_snapshot_path(@assay, @snapshot.snapshot_number)
    assert !assigns(:snapshot).zenodo_deposition_id.nil?
    assert !assigns(:snapshot).zenodo_record_url.nil?
  end

  test 'redirects to Zenodo auth page if no existing OAuth session' do
    zenodo_mock
    zenodo_oauth_mock
    create_investigation_snapshot

    @snapshot.doi = '10.5072/123'
    @snapshot.save
    login_as(@user)

    assert_empty @user.oauth_sessions.where(provider: 'Zenodo')

    post :export_submit, params: { investigation_id: @investigation, id: @snapshot.snapshot_number, code: 'abc', metadata: { access_type: 'open', license: 'CC-BY-4.0' } }

    assert_redirected_to assigns(:zenodo_oauth_client).authorize_url(request.original_url)
  end

  test "can't export snapshot to Zenodo if setting disabled" do
    zenodo_mock
    zenodo_oauth_mock
    create_investigation_snapshot
    FactoryBot.create(:oauth_session, user_id: @user.id)

    @snapshot.doi = '10.5072/123'
    @snapshot.save
    login_as(@user)

    with_config_value(:zenodo_publishing_enabled, false) do
      refute @snapshot.can_export_to_zenodo?

      get :show, params: { investigation_id: @investigation, id: @snapshot.snapshot_number }
      assert_response :success
      assert_select 'a.btn', text: 'Export to Zenodo', count: 0

      post :export_submit, params: { investigation_id: @investigation, id: @snapshot.snapshot_number, code: 'abc', metadata: { access_type: 'open', license: 'CC-BY-4.0' } }

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
    other_user = FactoryBot.create(:user)
    login_as(other_user)

    post :export_submit, params: { investigation_id: @investigation, id: @snapshot.snapshot_number, code: 'abc', metadata: { access_type: 'open', license: 'CC-BY-4.0' } }

    @snapshot = @snapshot.reload
    assert_redirected_to investigation_path(@investigation)
    assert @snapshot.zenodo_deposition_id.nil?
  end

  test 'error message mentions Zenodo when Zenodo broken' do
    zenodo_mock
    zenodo_oauth_mock
    create_investigation_snapshot
    FactoryBot.create(:oauth_session, user_id: @user.id)

    @snapshot.doi = '10.5072/123'
    @snapshot.save
    login_as(@user)

    with_config_value(:zenodo_api_url, 'http://idontexist.soup') do
      post :export_submit, params: { investigation_id: @investigation, id: @snapshot.snapshot_number, code: 'abc', metadata: { access_type: 'open', license: 'CC-BY-4.0' } }
    end

    @snapshot = @snapshot.reload

    assert flash[:error].to_s.include?('Zenodo')
    assert_redirected_to investigation_snapshot_path(@investigation, @snapshot.snapshot_number)
    assert @snapshot.zenodo_deposition_id.nil?
  end

  test 'can delete snapshot without doi' do
    create_investigation_snapshot
    login_as(@user)

    assert_difference('Snapshot.count', -1) do
      delete :destroy, params: { investigation_id: @investigation, id: @snapshot }
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
      delete :destroy, params: { investigation_id: @investigation, id: @snapshot }
    end

    assert_redirected_to investigation_snapshot_path(@investigation, @snapshot)
    assert flash[:error].include?('DOI')
  end

  test "can't delete snapshot without permission" do
    create_investigation_snapshot

    assert_no_difference('Snapshot.count') do
      delete :destroy, params: { investigation_id: @investigation, id: @snapshot }
    end

    assert_redirected_to investigation_path(@investigation)
    assert flash[:error].include?('authorized')
  end

  test 'can get citation for snapshot with DOI' do
    create_investigation_snapshot
    login_as(@user)
    @snapshot.doi = '10.5072/test'
    @snapshot.save

    get :show, params: { investigation_id: @investigation, id: @snapshot }
    assert_response :success
    assert_select '#citation', text: /Bacall, F/
  end

  test "broken DOI metadata response doesn't raise exception" do
    create_investigation_snapshot
    login_as(@user)
    @snapshot.doi = '10.5072/broken'
    @snapshot.save

    assert_nothing_raised do
      get :show, params: { investigation_id: @investigation, id: @snapshot }
    end
    assert_response :success
    assert_select '#citation', text: /error occurred/
  end

  test 'logs activities' do
    create_investigation_snapshot
    login_as(@user)

    assert_difference('ActivityLog.count') do
      get :show, params: { investigation_id: @investigation, id: @snapshot }
      assert_response :success
    end

    activity = ActivityLog.last
    assert_equal @snapshot, activity.activity_loggable
    assert_equal @investigation, activity.referenced
    assert_equal @user, activity.culprit
    assert_equal 'show', activity.action

    assert_difference('ActivityLog.count') do
      get :download, params: { investigation_id: @investigation, id: @snapshot }
      assert_response :success
    end

    activity = ActivityLog.last
    assert_equal @snapshot, activity.activity_loggable
    assert_equal @investigation, activity.referenced
    assert_equal @user, activity.culprit
    assert_equal 'download', activity.action
  end

  private

  def empty_snapshot
    { title: '', description: '' }
  end

  def create_investigation_snapshot
    @user = FactoryBot.create(:user)
    @investigation = FactoryBot.create(:investigation, description: 'not blank', policy: FactoryBot.create(:publicly_viewable_policy), contributor: @user.person)
    @snapshot = @investigation.create_snapshot
  end

  def create_study_snapshot
    @user = FactoryBot.create(:user)
    @investigation = FactoryBot.create(:investigation, description: 'not blank', policy: FactoryBot.create(:publicly_viewable_policy), contributor: @user.person)
    @study = FactoryBot.create(:study, description: 'not blank', policy: FactoryBot.create(:publicly_viewable_policy), contributor: @user.person)
    @snapshot = @study.create_snapshot
  end

  def create_assay_snapshot
    @user = FactoryBot.create(:user)
    @investigation = FactoryBot.create(:investigation, description: 'not blank', policy: FactoryBot.create(:publicly_viewable_policy), contributor: @user.person)
    @study = FactoryBot.create(:study, description: 'not blank', policy: FactoryBot.create(:publicly_viewable_policy), contributor: @user.person)
    @assay = FactoryBot.create(:assay, description: 'not blank', policy: FactoryBot.create(:publicly_viewable_policy), contributor: @user.person)
    @snapshot = @assay.create_snapshot
  end
end
