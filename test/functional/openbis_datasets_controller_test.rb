require 'test_helper'
require 'openbis_test_helper'

include SharingFormTestHelper

class OpenbisDatasetsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  def setup
    mock_openbis_calls
    @project_administrator = Factory(:project_administrator)
    @project = @project_administrator.projects.first
    @user = Factory(:person)
    @user.add_to_project_and_institution(@project, @user.institutions.first)
    assert @user.save
    @endpoint = Factory(:openbis_endpoint, project: @project)
    @dataset = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')
  end

  test 'test setup works' do
    assert @user
    assert @project_administrator
    assert @project
    assert_includes @user.projects, @project
    assert @endpoint
    assert @dataset
  end

  test 'index gives index view' do
    login_as(@user)
    get :index, openbis_endpoint_id: @endpoint.id

    assert_response :success
  end

  test 'index renders parents details' do
    login_as(@user)
    get :index, openbis_endpoint_id: @endpoint.id

    assert_response :success
    assert_select 'div label', 'Project:'
    assert_select 'div.form-group', /#{@endpoint.project.title}/
    assert_select 'div label', 'Endpoint:'
    assert_select 'div.form-group', /#{@endpoint.title}/
    assert_select '#openbis-dataset-cards div.openbis-card', count: 3
  end

  test 'index filters by dataset types' do
    login_as(@user)
    get :index, openbis_endpoint_id: @endpoint.id, entity_type: 'TZ_FAIR_TEST'

    assert_response :success
    assert_equal 2, assigns(:entities).size

    get :index, openbis_endpoint_id: @endpoint.id, entity_type: 'ALL DATASETS'

    assert_response :success
    assert_equal 3, assigns(:entities).size
  end

  test 'edit renders edit view' do
    login_as(@user)
    get :edit, openbis_endpoint_id: @endpoint.id, id: @dataset.perm_id

    assert_response :success
    assert assigns(:entity)
    assert assigns(:asset)
    assert assigns(:datafile)
  end

  test 'refresh updates content with fetched version and redirects' do
    login_as(@user)

    fake = Seek::Openbis::Dataset.new(@endpoint, '20160215111736723-31')
    assert_not_equal fake.perm_id, @dataset.perm_id

    old = DateTime.now - 1.days
    asset = OpenbisExternalAsset.build(@dataset)
    asset.content = fake
    asset.synchronized_at = old
    df = Factory :data_file
    asset.seek_entity = df
    assert asset.save

    # just a paranoid check, in case future implementation will mess up with setting stamps and content
    asset = OpenbisExternalAsset.find(asset.id)
    assert_equal fake.perm_id, asset.content.perm_id
    assert_equal old.to_date, asset.synchronized_at.to_date

    get :refresh, openbis_endpoint_id: @endpoint.id, id: @dataset.perm_id

    assert_response :redirect
    assert_redirected_to df

    asset = OpenbisExternalAsset.find(asset.id)
    assert_equal @dataset.perm_id, asset.content.perm_id
    assert_equal DateTime.now.to_date, asset.synchronized_at.to_date
  end

  ## Register ##

  test 'register registers new DataFile' do
    login_as(@user)

    post :register, openbis_endpoint_id: @endpoint.id, id: @dataset.perm_id

    datafile = assigns(:datafile)
    assert_not_nil datafile
    assert_redirected_to data_file_path(datafile)

    assert datafile.persisted?
    assert_equal "OpenBIS #{@dataset.perm_id}", datafile.title

    assert datafile.external_asset.persisted?

    datafile.reload
    assert_equal @dataset, datafile.external_asset.content

    assert_nil flash[:error]
    assert_equal "Registered OpenBIS dataset: #{@dataset.perm_id}", flash[:notice]
  end

  test 'register registers new DataFile under Assay if passed' do
    login_as(@user)

    assay = Factory :assay

    post :register, openbis_endpoint_id: @endpoint.id, id: @dataset.perm_id,
                    data_file: { assay_ids: assay.id }

    datafile = assigns(:datafile)
    assert_not_nil datafile
    assert_redirected_to data_file_path(datafile)

    assert datafile.persisted?

    datafile.reload
    assay.reload

    assert_equal datafile, assay.data_files.first
  end

  test 'register does not create datafile if dataset already registered but redirects to it' do
    login_as(@user)
    existing = Factory :data_file

    external = OpenbisExternalAsset.build(@dataset)
    assert external.save
    existing.external_asset = external
    assert existing.save

    post :register, openbis_endpoint_id: @endpoint.id, id: @dataset.perm_id.to_s

    assert_redirected_to data_file_path(existing)

    assert_equal 'Already registered as OpenBIS entity', flash[:error]
  end

  ## Update ###
  test 'update updates content and redirects' do
    login_as(@user)

    exdatafile = Factory :data_file
    asset = OpenbisExternalAsset.build(@dataset)
    asset.synchronized_at = DateTime.now - 2.days
    exdatafile.external_asset = asset
    assert asset.save
    assert exdatafile.save

    assert_not_equal DateTime.now.to_date, asset.synchronized_at.to_date

    post :update, openbis_endpoint_id: @endpoint.id, id: @dataset.perm_id

    datafile = assigns(:datafile)
    assert_not_nil datafile
    assert_equal exdatafile, datafile
    assert_redirected_to data_file_path(datafile)

    last_mod = asset.updated_at
    asset.reload
    assert_not_equal last_mod, asset.updated_at

    # testing content update just by synchronized stamp
    assert_equal DateTime.now.to_date, asset.synchronized_at.to_date

    last_mod = exdatafile.updated_at
    datafile.reload
    # for same reason eql, so comparing ind fields does not work even if no update operations are visible in db
    assert_equal last_mod.to_a, datafile.updated_at.to_a

    assert_nil flash[:error]
    assert_equal "Updated sync of OpenBIS datafile: #{@dataset.perm_id}", flash[:notice]
  end

  ## Batch register ##

  test 'batch register multiple DataSets' do
    login_as(@user)
    assay = Factory :assay

    sync_options = {}
    batch_ids = ['20160210130454955-23', '20160215111736723-31']

    assert_difference('DataFile.count', 2) do
      assert_difference('ExternalAsset.count', 2) do
        post :batch_register, openbis_endpoint_id: @endpoint.id,
                              seek_parent: assay.id, sync_options: sync_options, batch_ids: batch_ids
      end
    end

    assert_response :success
    puts flash[:error]
    refute flash[:error]
    assert_equal "Registered all #{batch_ids.size} datafiles", flash[:notice]

    assay.reload
    assert_equal batch_ids.size, assay.data_files.size
  end

  # there was a bug and all were named same, lets have test for it
  test 'batch register independently names them' do
    login_as(@user)
    assay = Factory :assay

    sync_options = {}
    batch_ids = ['20160210130454955-23', '20160215111736723-31']

    post :batch_register, openbis_endpoint_id: @endpoint.id,
                          seek_parent: assay.id, sync_options: sync_options, batch_ids: batch_ids

    assert_response :success

    assay.reload
    assert_equal batch_ids.size, assay.data_files.size
    titles = assay.data_files.map(&:title).uniq
    assert_equal batch_ids.size, titles.size
  end

  ## Batch register

  ## permissions ##
  test 'only project members can call actions' do
    logout
    get :index, openbis_endpoint_id: @endpoint.id
    assert_response :redirect

    get :edit, openbis_endpoint_id: @endpoint.id, id: @dataset.perm_id
    assert_response :redirect

    assay = Factory :assay
    sync_options = {}
    batch_ids = ['20160210130454955-23', '20160215111736723-31']

    post :register, openbis_endpoint_id: @endpoint.id, id: @dataset.perm_id

    assert_response :redirect
    assert_redirected_to :root

    post :batch_register, openbis_endpoint_id: @endpoint.id,
                          seek_parent: assay.id, sync_options: sync_options, batch_ids: batch_ids

    assert_response :redirect
    assert_redirected_to :root

    login_as(@user)

    get :index, openbis_endpoint_id: @endpoint.id
    assert_response :success

    get :edit, openbis_endpoint_id: @endpoint.id, id: @dataset.perm_id
    assert_response :success

    post :register, openbis_endpoint_id: @endpoint.id, id: @dataset.perm_id
    assert_response :redirect
    seek = assigns(:datafile)
    assert_not_nil seek
    assert_redirected_to seek

    post :batch_register, openbis_endpoint_id: @endpoint.id,
                          seek_parent: assay.id, sync_options: sync_options, batch_ids: batch_ids
    assert_response :success
  end

  test 'show dataset files' do
    login_as(@user)
    get :show_dataset_files, openbis_endpoint_id: @endpoint.id, id: @dataset.perm_id

    assert_response :success
    assert_select 'td.filename', text: 'original/autumn.jpg', count: 1

    logout

    another_person = Factory(:person)
    login_as(another_person)
    get :show_dataset_files, openbis_endpoint_id: @endpoint.id, id: @dataset.perm_id
    assert_response :redirect
    assert_select 'td.filename', text: 'original/autumn.jpg', count: 0
  end

  # Original stuart test with access tests
  #   test 'show dataset files' do
  #
  #     # without a datafile, only project member can view
  #     person = Factory(:person)
  #     another_person = Factory(:person)
  #
  #     login_as(person)
  #
  #     project = person.projects.first
  #     endpoint = Factory(:openbis_endpoint, project: project)
  #     get :show_dataset_files, id: endpoint.id, project_id: project.id, perm_id: '20160210130454955-23'
  #     assert_response :success
  #     assert_select 'td.filename', text: 'original/autumn.jpg', count: 1
  #
  #     logout
  #     login_as(another_person)
  #     get :show_dataset_files, id: endpoint.id, project_id: project.id, perm_id: '20160210130454955-23'
  #     assert_response :redirect
  #     assert_select 'td.filename', text: 'original/autumn.jpg', count: 0
  #
  #     logout
  #     login_as(person)
  #
  #     # now with a datafile, accessible to all
  #     df = openbis_linked_data_file(User.current_user, endpoint)
  #     disable_authorization_checks do
  #       df.policy = Factory(:public_policy)
  #       df.save!
  #     end
  #     assert df.can_download?
  #     get :show_dataset_files, id: endpoint.id, project_id: project.id, data_file_id: df.id
  #     assert_response :success
  #     assert_select 'td.filename', text: 'original/autumn.jpg', count: 1
  #
  #     logout
  #     login_as(another_person)
  #     assert df.can_download?
  #     get :show_dataset_files, id: endpoint.id, project_id: project.id, data_file_id: df.id
  #     assert_response :success
  #     assert_select 'td.filename', text: 'original/autumn.jpg', count: 1
  #
  #     logout
  #     assert df.can_download?
  #     get :show_dataset_files, id: endpoint.id, project_id: project.id, data_file_id: df.id
  #     assert_response :success
  #     assert_select 'td.filename', text: 'original/autumn.jpg', count: 1
  #
  #     # not accessible if df is not downloadable
  #     disable_authorization_checks do
  #       df.policy = Factory(:private_policy)
  #       df.save!
  #     end
  #
  #     refute df.can_download?
  #     get :show_dataset_files, id: endpoint.id, project_id: project.id, data_file_id: df.id
  #     assert_response :redirect
  #     assert_select 'td.filename', text: 'original/autumn.jpg', count: 0
  #
  #     logout
  #     login_as(another_person)
  #     get :show_dataset_files, id: endpoint.id, project_id: project.id, data_file_id: df.id
  #     assert_response :redirect
  #     assert_select 'td.filename', text: 'original/autumn.jpg', count: 0
  #
  #     logout
  #     login_as(person)
  #     assert df.can_download?
  #     get :show_dataset_files, id: endpoint.id, project_id: project.id, data_file_id: df.id
  #     assert_response :success
  #     assert_select 'td.filename', text: 'original/autumn.jpg', count: 1
  #   end

  # unit like tests
end
