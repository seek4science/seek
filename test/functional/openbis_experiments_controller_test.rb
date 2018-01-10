require 'test_helper'
require 'openbis_test_helper'

include SharingFormTestHelper

class OpenbisExperimentsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  def setup
    mock_openbis_calls
    @project_administrator = Factory(:project_administrator)
    @project = @project_administrator.projects.first
    @user = Factory(:person)
    @user.add_to_project_and_institution(@project, @user.institutions.first)
    assert @user.save
    @endpoint = Factory(:openbis_endpoint, project: Factory(:project))
    @experiment = Seek::Openbis::Experiment.new(@endpoint, '20171121152132641-51')
  end

  test 'test setup works' do
    assert @user
    assert @project_administrator
    assert @project
    assert_includes @user.projects, @project
    assert @endpoint
    assert @zample
  end

  test 'index gives index view' do
    login_as(@user)
    get :index, openbis_endpoint_id: @endpoint.id, seek: :assay

    assert_response :success
  end

  test 'index sets assay_types and entities' do
    login_as(@user)
    get :index, openbis_endpoint_id: @endpoint.id, seek: :assay

    assert_response :success
    assert assigns(:zample_types)
    assert assigns(:zample_types_codes)
    assert assigns(:zample_type_options)
    assert assigns(:zample_type)
    assert_equal 'ALL ASSAYS', assigns(:zample_type)
    assert_includes assigns(:zample_type_options), 'ALL ASSAYS'
    assert_includes assigns(:zample_type_options), 'ALL TYPES'
    assert assigns(:entities)
    assert_equal 2, assigns(:entities).size
  end

  test 'index filters by zample_type' do
    login_as(@user)
    get :index, openbis_endpoint_id: @endpoint.id, seek: :assay, zample_type: 'TZ_TEST'

    assert_response :success
    assert_equal 1, assigns(:entities).size

    get :index, openbis_endpoint_id: @endpoint.id, seek: :assay, zample_type: 'ALL ASSAYS'

    assert_response :success
    assert_equal 2, assigns(:entities).size

    get :index, openbis_endpoint_id: @endpoint.id, seek: :assay, zample_type: 'ALL TYPES'

    assert_response :success
    assert_equal 8, assigns(:entities).size
  end


  test 'index renders parents details' do
    login_as(@user)
    get :index, openbis_endpoint_id: @endpoint.id, seek: :assay

    assert_response :success
    assert_select "div label", "Project:"
    assert_select "div.form-group", /#{@endpoint.project.title}/
    assert_select "div label", "Endpoint:"
    assert_select "div.form-group", /#{@endpoint.title}/
    # assert_select "div", "Endpoint: #{@endpoint.id}"
    # assert_select "div", "Samples: 2"
    assert_select '#openbis-zamples-cards div.openbis-card', count: 2
  end

  test 'edit gives edit view' do
    login_as(@user)
    get :edit, project_id: @project.id, openbis_endpoint_id: @endpoint.id, id: '20171002172111346-37'

    assert_response :success
    assert assigns(:assay)
    assert assigns(:asset)
    assert assigns(:entity)
    assert assigns(:linked_to_assay)

  end

  ## Register ##

  test 'register registers new Assay with linked datasets' do
    login_as(@user)
    study = Factory :study
    refute @zample.dataset_ids.empty?

    sync_options = { 'link_datasets' => '1' }

    post :register, project_id: @project.id, openbis_endpoint_id: @endpoint.id, id: @zample.perm_id, assay: { study_id: study.id }, sync_options: sync_options


    assay = assigns(:assay)
    assert_not_nil assay
    assert_redirected_to assay_path(assay)

    assert assay.persisted?
    assert_equal 'OpenBIS 20171002172111346-37', assay.title

    assert assay.external_asset.persisted?

    assay.reload
    assert_equal @zample.dataset_ids.length, assay.data_files.length

    assert_nil flash[:error]
    assert_equal 'Registered OpenBIS assay: 20171002172111346-37', flash[:notice]
  end

  test 'register registers new Assay with selected datasets' do
    login_as(@user)
    study = Factory :study
    assert @zample.dataset_ids.size > 2

    sync_options = { 'link_datasets' => '0' }
    to_link = @zample.dataset_ids[0..1]

    post :register, project_id: @project.id, openbis_endpoint_id: @endpoint.id, id: @zample.perm_id,
         assay: { study_id: study.id }, sync_options: sync_options, linked_datasets: to_link


    assay = assigns(:assay)
    assert_not_nil assay
    assert_redirected_to assay_path(assay)

    assert assay.persisted?
    assert_equal 'OpenBIS 20171002172111346-37', assay.title

    assert assay.external_asset.persisted?

    assay.reload
    assert_equal to_link.size, assay.data_files.size

  end

  test 'register remains on registration screen on errors' do
    login_as(@user)
    study = Factory :study

    post :register, project_id: @project.id, openbis_endpoint_id: @endpoint.id, id: '20171002172111346-37', assay: { xl: true }

    assert_response :success

    assay = assigns(:assay)
    assert_not_nil assay
    refute assay.persisted?

    assert assigns(:reasons)
    assert assigns(:error_msg)
    assert_select "div.alert-danger", /Could not register OpenBIS assay/

  end

  test 'register does not create assay if zample already registered but redirects to it' do
    login_as(@user)
    study = Factory :study
    existing = Factory :assay

    external = OpenbisExternalAsset.build(@zample)
    assert external.save
    existing.external_asset = external
    assert existing.save

    post :register, project_id: @project.id, openbis_endpoint_id: @endpoint.id, id: "#{@zample.perm_id}", assay: { study_id: study.id }

    assert_redirected_to assay_path(existing)

    assert_equal 'Already registered as OpenBIS entity', flash[:error]

  end

  ## Batch register assay ##

  test 'batch registers multiple Assays' do

    login_as(@user)
    study = Factory :study

    sync_options = {link_dependent: 'false'}
    batch_ids = ['20171002172111346-37', '20171002172639055-39']

    assert_difference('Assay.count', 2) do
      assert_no_difference('DataFile.count') do
        assert_difference('ExternalAsset.count', 2) do

          post :batch_register, openbis_endpoint_id: @endpoint.id,
               seek: :assay, seek_parent: study.id, sync_options: sync_options, batch_ids: batch_ids
        end
      end
    end

    assert_response :success
    puts flash[:error]
    refute flash[:error]
    assert_equal "Registered all #{batch_ids.size} assays", flash[:notice]

    study.reload
    assert_equal batch_ids.size, study.assays.size

  end

  test 'batch registers multiple Assays and follows datasets' do

    login_as(@user)
    study = Factory :study

    sync_options = {link_dependent: '1'}
    batch_ids = ['20171002172111346-37', '20171002172639055-39']

    assert_difference('Assay.count', 2) do
      assert_difference('DataFile.count', 3) do
        assert_difference('ExternalAsset.count', 5) do

        post :batch_register, openbis_endpoint_id: @endpoint.id,
             seek: :assay, seek_parent: study.id, sync_options: sync_options, batch_ids: batch_ids
        end
      end
    end

    assert_response :success
    puts flash[:error]
    refute flash[:error]
    assert_equal "Registered all #{batch_ids.size} assays", flash[:notice]

    study.reload
    assert_equal batch_ids.size, study.assays.size

  end


  ## END --- Batch register assay ##

  ## Update ###
  test 'update updates sync options and follows dependencies' do
    login_as(@user)

    exassay = Factory :assay
    asset = OpenbisExternalAsset.build(@zample)
    exassay.external_asset = asset
    assert asset.save
    assert exassay.save
    refute @zample.dataset_ids.empty?


    sync_options = { link_datasets: '1' }
    assert_not_equal sync_options, asset.sync_options

    post :update, project_id: @project.id, openbis_endpoint_id: @endpoint.id, id: @zample.perm_id, sync_options: sync_options

    assay = assigns(:assay)
    assert_not_nil assay
    assert_equal exassay, assay
    assert_redirected_to assay_path(assay)

    last_mod = asset.updated_at
    asset.reload
    assert_equal sync_options, asset.sync_options
    assert_not_equal last_mod, asset.updated_at

    # TODO how to test for content update (or lack of it depends on decided semantics)


    last_mod = exassay.updated_at
    assay.reload
    # this test fails??? so asset is save probably due to relations updates
    # for same reason eql, so comparing ind fields does not work even if no update operations are visible in db
    assert_equal last_mod.to_a, assay.updated_at.to_a
    assert_equal @zample.dataset_ids.length, assay.data_files.length

    assert_nil flash[:error]
    assert_equal "Updated sync of OpenBIS assay: #{@zample.perm_id}", flash[:notice]
  end

  test 'update updates sync options and adds selected datasets' do
    login_as(@user)

    exassay = Factory :assay
    asset = OpenbisExternalAsset.build(@zample)
    exassay.external_asset = asset
    assert asset.save
    assert exassay.save

    assert @zample.dataset_ids.size > 2

    to_link = @zample.dataset_ids[0..1]
    sync_options = { link_datasets: '0' }
    assert_not_equal sync_options, asset.sync_options

    post :update, project_id: @project.id, openbis_endpoint_id: @endpoint.id, id: @zample.perm_id,
         sync_options: sync_options, linked_datasets: to_link

    assay = assigns(:assay)
    assert_not_nil assay
    assert_equal exassay, assay
    assert_redirected_to assay_path(assay)

    asset.reload
    assert_equal sync_options, asset.sync_options

    assay.reload
    assert_equal to_link.size, assay.data_files.size

    assert_nil flash[:error]
    assert_equal "Updated sync of OpenBIS assay: #{@zample.perm_id}", flash[:notice]
  end

  # unit like tests

  ## registration ##
  test 'do_assay_registration creates assay from sample and returns status info' do

    controller = OpenbisZamplesController.new

    asset = OpenbisExternalAsset.find_or_create_by_entity(@zample)
    refute asset.seek_entity

    study = Factory :study
    assay_params = { study_id: study.id }

    sync_options = {}
    params = {}
    reg_status = controller.do_assay_registration(asset, assay_params, sync_options, @user, params)
    assert reg_status

    assay = reg_status[:assay]
    assert assay
    assert_equal assay, asset.seek_entity
    assert_equal study, assay.study
    assert_equal [], reg_status[:issues]
  end

  test 'do_assay_registration sets issues on errors if not recovable' do

    controller = OpenbisZamplesController.new

    exassay = Factory :assay

    asset = OpenbisExternalAsset.build(@zample)
    asset.seek_entity = exassay
    assert asset.save

    study = Factory :study
    assay_params = { study_id: study.id }

    sync_options = {}
    params = {}

    reg_status = controller.do_assay_registration(asset, assay_params, sync_options, @user, params)
    assert reg_status

    assay = reg_status[:assay]
    refute assay

    issues = reg_status[:issues]
    assert issues
    assert_equal 1, issues.size
  end

  test 'do_assay_registration creates assay links datasets if sync_option says so' do

    controller = OpenbisZamplesController.new

    asset = OpenbisExternalAsset.find_or_create_by_entity(@zample)
    refute asset.seek_entity

    study = Factory :study
    assay_params = { study_id: study.id }

    sync_options = { link_datasets: '1' }
    params = {}

    reg_status = controller.do_assay_registration(asset, assay_params, sync_options, @user, params)
    assert reg_status

    assay = reg_status[:assay]
    assert assay
    assert_equal assay, asset.seek_entity
    assert_equal study, assay.study
    assert_equal [], reg_status[:issues]
    assert_equal 3, assay.data_files.size
  end

  test 'do_assay_registration creates assay links selected datasets' do

    controller = OpenbisZamplesController.new

    asset = OpenbisExternalAsset.find_or_create_by_entity(@zample)
    refute asset.seek_entity

    study = Factory :study
    assay_params = { study_id: study.id }

    sync_options = { link_datasets: '0' }
    params = {linked_datasets: @zample.dataset_ids[0..1]}

    reg_status = controller.do_assay_registration(asset, assay_params, sync_options, @user, params)
    assert reg_status

    assay = reg_status[:assay]
    assert assay
    assert_equal assay, asset.seek_entity
    assert_equal study, assay.study
    assert_equal [], reg_status[:issues]
    assert_equal 2, assay.data_files.size
  end

  ## registration end ##

  test 'extract_requested_zamples gives all zamples if linked is selected' do

    controller = OpenbisExperimentsController.new

    assert_equal 2, @experiment.sample_ids.length
    sync_options = {}
    params = {}

    assert_equal [], controller.extract_requested_zamples(@experiment, sync_options, params)

    sync_options = { link_assays: '1' }
    assert_same @experiment.sample_ids, controller.extract_requested_zamples(@experiment, sync_options, params)

    params = {linked_zamples: ['123'] }
    assert_same @experiment.sample_ids, controller.extract_requested_zamples(@experiment, sync_options, params)

  end

  test 'extract_requested_zamples gives only selected zamples that belongs to exp' do

    controller = OpenbisExperimentsController.new

    sync_options = {}
    params = {}

    assert_equal 2, @experiment.sample_ids.length

    assert_equal [], controller.extract_requested_zamples(@experiment, sync_options, params)

    params = { linked_zamples: [] }
    assert_equal [], controller.extract_requested_zamples(@experiment, sync_options, params)

    params = { linked_zamples: ['123'] }
    assert_equal [], controller.extract_requested_zamples(@experiment, sync_options, params)

    params = { linked_zamples: ['123', @experiment.sample_ids[0]] }
    assert_equal [@experiment.sample_ids[0]], controller.extract_requested_zamples(@experiment, sync_options, params)

    params = { linked_zamples: @experiment.sample_ids }
    assert_equal @experiment.sample_ids, controller.extract_requested_zamples(@experiment, sync_options, params)

  end

  test 'extract_requested_sets gives all sets from zample if linked is selected' do

    controller = OpenbisZamplesController.new

    assert_equal 3, @zample.dataset_ids.length
    sync_options = {}
    params = {}

    assert_equal [], controller.extract_requested_sets(@zample, sync_options, params)

    sync_options = { link_datasets: '1' }
    assert_same @zample.dataset_ids, controller.extract_requested_sets(@zample, sync_options, params)

    params = {linked_datasets: ['123'] }
    assert_same @zample.dataset_ids, controller.extract_requested_sets(@zample, sync_options, params)

  end

  test 'extract_requested_sets gives only selected sets that belongs to zample' do

    controller = OpenbisZamplesController.new

    sync_options = {}
    params = {}

    assert_equal 3, @zample.dataset_ids.length

    assert_equal [], controller.extract_requested_sets(@zample, sync_options, params)

    params = { linked_datasets: [] }
    assert_equal [], controller.extract_requested_sets(@zample, sync_options, params)

    params = { linked_datasets: ['123'] }
    assert_equal [], controller.extract_requested_sets(@zample, sync_options, params)

    params = { linked_datasets: ['123', @zample.dataset_ids[0]] }
    assert_equal [@zample.dataset_ids[0]], controller.extract_requested_sets(@zample, sync_options, params)

    params = { linked_datasets: @zample.dataset_ids }
    assert_equal @zample.dataset_ids, controller.extract_requested_sets(@zample, sync_options, params)

  end

  test 'get_linked_to gets ids of openbis data sets' do
    controller = OpenbisZamplesController.new
    util = Seek::Openbis::SeekUtil.new

    assert_equal [], controller.get_linked_to(nil)

    datasets = Seek::Openbis::Dataset.new(@endpoint).find_by_perm_ids(["20171002172401546-38", "20171002190934144-40", "20171004182824553-41"])
    datafiles = datasets.map { |ds| util.createObisDataFile(OpenbisExternalAsset.build(ds)) }
    assert_equal 3, datafiles.length

    disable_authorization_checks do
      datafiles.each { |df| df.save! }
    end

    normaldf = Factory :data_file

    assay = Factory :assay

    assay.data_files << normaldf
    assay.data_files << datafiles[0]
    assay.data_files << datafiles[1]
    assay.save!

    linked = controller.get_linked_to assay
    assert_equal 2, linked.length
    assert_equal ['20171004182824553-41', '20171002190934144-40'], linked

  end

end
