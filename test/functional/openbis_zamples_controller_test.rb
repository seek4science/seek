require 'test_helper'
require 'openbis_test_helper'

#include SharingFormTestHelper

class OpenbisZamplesControllerTest < ActionController::TestCase
  #fixtures :all
  include AuthenticatedTestHelper

  def setup
    FactoryBot.create :experimental_assay_class
    mock_openbis_calls
    @project_administrator = FactoryBot.create(:project_administrator)
    @project = @project_administrator.projects.first
    @user = FactoryBot.create(:person)
    @user.add_to_project_and_institution(@project, @user.institutions.first)
    assert @user.save
    @endpoint = FactoryBot.create(:openbis_endpoint, project: @project)
    @endpoint.assay_types = %w[TZ_FAIR_ASSAY EXPERIMENTAL_STEP]
    @endpoint.save!
    @zample = Seek::Openbis::Zample.new(@endpoint, '20171002172111346-37')
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
    get :index, params: { openbis_endpoint_id: @endpoint.id, seek: :assay }

    assert_response :success
  end

  test 'index sets assay_types and entities' do
    login_as(@user)
    get :index, params: { openbis_endpoint_id: @endpoint.id, seek: :assay }

    assert_response :success
    assert assigns(:entity_types)
    assert assigns(:entity_types_codes)
    assert assigns(:entity_type_options)
    assert assigns(:entity_types)
    assert_equal 'ALL ASSAYS', assigns(:entity_type)
    assert_includes assigns(:entity_type_options), 'ALL ASSAYS'
    assert_includes assigns(:entity_type_options), 'ALL TYPES'
    assert assigns(:entities)
    assert_equal 2, assigns(:entities).size
  end

  test 'index filters by entity_type' do
    login_as(@user)
    get :index, params: { openbis_endpoint_id: @endpoint.id, seek: :assay, entity_type: 'TZ_TEST' }

    assert_response :success
    assert_equal 1, assigns(:entities).size

    get :index, params: { openbis_endpoint_id: @endpoint.id, seek: :assay, entity_type: 'ALL ASSAYS' }

    assert_response :success
    assert_equal 2, assigns(:entities).size

    get :index, params: { openbis_endpoint_id: @endpoint.id, seek: :assay, entity_type: 'ALL TYPES' }

    assert_response :success
    assert_equal 8, assigns(:entities).size
  end

  test 'index renders parents details' do
    login_as(@user)
    get :index, params: { openbis_endpoint_id: @endpoint.id, seek: :assay }

    assert_response :success
    assert_select 'div label', 'Project:'
    assert_select 'div.form-group', /#{@endpoint.project.title}/
    assert_select 'div label', 'Endpoint:'
    assert_select 'div.form-group', /#{@endpoint.title}/
    # assert_select "div", "Endpoint: #{@endpoint.id}"
    # assert_select "div", "Samples: 2"
    assert_select '#openbis-zamples-cards div.openbis-card', count: 2
  end

  test 'edit gives edit view' do
    login_as(@user)
    get :edit, params: { openbis_endpoint_id: @endpoint.id, id: '20171002172111346-37' }

    assert_response :success
    assert assigns(:assay)
    assert assigns(:seek_entity)
    assert assigns(:asset)
    assert assigns(:entity)
    assert assigns(:datasets_linked_to)
  end

  test 'refresh updates content with fetched version and redirects' do
    login_as(@user)

    fake = Seek::Openbis::Zample.new(@endpoint, '20171002172639055-39')
    assert_not_equal fake.perm_id, @zample.perm_id

    old = DateTime.now - 1.days
    asset = OpenbisExternalAsset.build(@zample)
    asset.content = fake
    asset.synchronized_at = old
    as = FactoryBot.create :assay
    asset.seek_entity = as
    assert asset.save

    # just a paranoid check, in case future implementation will mess up with setting stamps and content
    asset = OpenbisExternalAsset.find(asset.id)
    assert_equal fake.perm_id, asset.content.perm_id
    assert_equal old.to_date, asset.synchronized_at.to_date

    get :refresh, params: { openbis_endpoint_id: @endpoint.id, id: @zample.perm_id }

    assert_response :redirect
    assert_redirected_to as

    asset = OpenbisExternalAsset.find(asset.id)
    assert_equal @zample.perm_id, asset.content.perm_id
    assert_equal DateTime.now.to_date, asset.synchronized_at.to_date
  end

  ## Register ##

  test 'register registers new Assay with linked datasets' do
    login_as(@user)
    study = FactoryBot.create :study, contributor: @user
    refute @zample.dataset_ids.empty?

    sync_options = { 'link_datasets' => '1' }

    post :register, params: { openbis_endpoint_id: @endpoint.id, id: @zample.perm_id, assay: { study_id: study.id }, sync_options: sync_options }

    assay = assigns(:seek_entity)
    assert_not_nil assay
    assert_redirected_to assay_path(assay)

    assert assay.persisted?
    assert_equal 'Tomek First OpenBIS TZ3', assay.title

    assert assay.external_asset.persisted?

    assay.reload
    assert_equal @zample.dataset_ids.length, assay.data_files.length

    assert_nil flash[:error]
    assert_equal 'Registered OpenBIS Sample 20171002172111346-37 as Assay', flash[:notice]
  end

  test 'register registers new Assay with selected datasets' do
    login_as(@user)
    study = FactoryBot.create :study, contributor: @user
    assert @zample.dataset_ids.size > 2

    to_link = @zample.dataset_ids[0..1]
    sync_options = { 'link_datasets' => '0', 'linked_datasets' => to_link }

    post :register, params: { openbis_endpoint_id: @endpoint.id, id: @zample.perm_id, assay: { study_id: study.id }, sync_options: sync_options }

    assay = assigns(:seek_entity)
    assert_not_nil assay
    assert_redirected_to assay_path(assay)

    assert assay.persisted?
    assert_equal "#{@zample.properties['NAME']} OpenBIS #{@zample.code}", assay.title

    assert assay.external_asset.persisted?

    assay.reload
    assert_equal to_link.size, assay.data_files.size
  end

  test 'register remains redirect to edit screen on errors' do
    login_as(@user)

    post :register, params: { openbis_endpoint_id: @endpoint.id, id: '20171002172111346-37', assay: { xl: true } }

    assert_redirected_to action: :edit
    assert flash[:error]

    # assert_response :success
    #
    # assay = assigns(:seek_entity)
    # assert_not_nil assay
    # refute assay.persisted?
    #
    # assert assigns(:reasons)
    # assert assigns(:error_msg)
    # assert_select 'div.alert-danger', /Could not register OpenBIS assay/
  end

  test 'register does not create assay if zample already registered but redirects to it' do
    login_as(@user)
    study = FactoryBot.create :study
    existing = FactoryBot.create :assay

    external = OpenbisExternalAsset.build(@zample)
    assert external.save
    existing.external_asset = external
    assert existing.save

    post :register, params: { openbis_endpoint_id: @endpoint.id, id: @zample.perm_id, assay: { study_id: study.id } }

    assert_redirected_to assay_path(existing)

    assert_equal 'OpenBIS entity already registered in Seek', flash[:error]
  end

  ## Batch register ##

  test 'batch registers multiple Assays' do
    login_as(@user)
    study = FactoryBot.create :study, contributor: @user

    sync_options = { link_dependent: 'false' }
    batch_ids = ['20171002172111346-37', '20171002172639055-39']

    assert_difference('Assay.count', 2) do
      assert_no_difference('DataFile.count') do
        assert_difference('ExternalAsset.count', 2) do
          post :batch_register, params: { openbis_endpoint_id: @endpoint.id, seek: :assay, seek_parent: study.id, sync_options: sync_options, batch_ids: batch_ids }
        end
      end
    end

    assert_response :success
    refute flash[:error]
    assert_equal "Registered all #{batch_ids.size} OpenBIS entities", flash[:notice]

    study.reload
    assert_equal batch_ids.size, study.assays.size
  end

  test 'batch registers multiple Assays and follows datasets' do
    login_as(@user)
    study = FactoryBot.create :study, contributor: @user

    sync_options = { link_dependent: '1' }
    batch_ids = ['20171002172111346-37', '20171002172639055-39']

    assert_difference('Assay.count', 2) do
      assert_difference('DataFile.count', 3) do
        assert_difference('ExternalAsset.count', 5) do
          post :batch_register, params: { openbis_endpoint_id: @endpoint.id, seek: :assay, seek_parent: study.id, sync_options: sync_options, batch_ids: batch_ids }
        end
      end
    end

    assert_response :success
    refute flash[:error]
    assert_equal "Registered all #{batch_ids.size} OpenBIS entities", flash[:notice]

    study.reload
    assert_equal batch_ids.size, study.assays.size
  end

  test 'batch register independently names them' do
    login_as(@user)
    study = FactoryBot.create :study, contributor: @user

    sync_options = { link_dependent: 'false' }
    batch_ids = ['20171002172111346-37', '20171002172639055-39']

    post :batch_register, params: { openbis_endpoint_id: @endpoint.id, seek: :assay, seek_parent: study.id, sync_options: sync_options, batch_ids: batch_ids }

    assert_response :success

    study.reload
    assert_equal batch_ids.size, study.assays.size
    titles = study.assays.map(&:title).uniq
    assert_equal batch_ids.size, titles.size
  end

  ## END --- Batch register  ##

  ## Update ###
  test 'update updates sync options and follows dependencies' do
    login_as(@user)

    exassay = FactoryBot.create :assay, contributor: @user
    asset = OpenbisExternalAsset.build(@zample)
    asset.synchronized_at = 2.days.ago
    asset.created_at = 2.days.ago
    asset.updated_at = 2.days.ago
    exassay.external_asset = asset
    assert asset.save
    assert exassay.save
    refute @zample.dataset_ids.empty?

    sync_options = { link_datasets: '1' }
    assert_not_equal sync_options, asset.sync_options
    assert_not_equal DateTime.now.to_date, asset.synchronized_at.to_date

    post :update, params: { openbis_endpoint_id: @endpoint.id, id: @zample.perm_id, sync_options: sync_options }

    assay = assigns(:seek_entity)
    assert_not_nil assay
    assert_equal exassay, assay
    assert_redirected_to assay_path(assay)

    last_mod = asset.updated_at
    asset.reload
    assert_equal sync_options, asset.sync_options
    assert_not_equal last_mod, asset.updated_at

    # testing content update just by synchronized stamp
    assert_equal DateTime.now.to_date, asset.synchronized_at.to_date

    last_mod = exassay.reload.updated_at
    assay.reload
    # this test fails??? so asset is save probably due to relations updates
    # for same reason eql, so comparing ind fields does not work even if no update operations are visible in db
    assert_equal last_mod.to_a, assay.updated_at.to_a
    assert_equal @zample.dataset_ids.length, assay.data_files.length

    assert_nil flash[:error]
    assert_equal "Updated registration of Sample #{@zample.perm_id}", flash[:notice]
  end

  test 'update updates sync options and adds selected datasets' do
    login_as(@user)

    exassay = FactoryBot.create :assay, contributor: @user
    asset = OpenbisExternalAsset.build(@zample)
    exassay.external_asset = asset
    assert asset.save
    assert exassay.save

    assert @zample.dataset_ids.size > 2

    to_link = @zample.dataset_ids[0..1]
    sync_options = { link_datasets: '0', linked_datasets: to_link }
    assert_not_equal sync_options, asset.sync_options

    post :update, params: { openbis_endpoint_id: @endpoint.id, id: @zample.perm_id, sync_options: sync_options }

    assay = assigns(:seek_entity)
    assert_not_nil assay
    assert_equal exassay, assay
    assert_redirected_to assay_path(assay)

    asset.reload
    assert_equal sync_options, asset.sync_options

    assay.reload
    assert_equal to_link.size, assay.data_files.size

    assert_nil flash[:error]
    assert_equal "Updated registration of Sample #{@zample.perm_id}", flash[:notice]
  end

  ## permissions ##
  test 'only project members can call actions' do
    logout
    get :index, params: { openbis_endpoint_id: @endpoint.id }
    assert_response :redirect

    get :edit, params: { openbis_endpoint_id: @endpoint.id, id: '20171002172111346-37' }
    assert_response :redirect

    study = FactoryBot.create :study, contributor: @user
    sync_options = {}
    batch_ids = ['20171002172111346-37', '20171002172639055-39']

    post :register, params: { openbis_endpoint_id: @endpoint.id, id: @zample.perm_id, assay: { study_id: study.id }, sync_options: sync_options }

    assert_response :redirect
    assert_redirected_to :root

    post :batch_register, params: { openbis_endpoint_id: @endpoint.id, seek: :assay, seek_parent: study.id, sync_options: sync_options, batch_ids: batch_ids }

    assert_response :redirect
    assert_redirected_to :root

    login_as(@user)

    get :index, params: { openbis_endpoint_id: @endpoint.id }
    assert_response :success

    get :edit, params: { openbis_endpoint_id: @endpoint.id, id: '20171002172111346-37' }
    assert_response :success

    post :register, params: { openbis_endpoint_id: @endpoint.id, id: @zample.perm_id, assay: { study_id: study.id }, sync_options: sync_options }
    assert_response :redirect
    seek = assigns(:seek_entity)
    assert_not_nil seek
    assert_redirected_to seek

    post :batch_register, params: { openbis_endpoint_id: @endpoint.id, seek: :assay, seek_parent: study.id, sync_options: sync_options, batch_ids: batch_ids }
    assert_response :success
  end

  # unit like tests

  ## registration ##
  test 'do_entity_registration creates assay from sample and returns status info' do
    controller = OpenbisZamplesController.new
    login_as(@user)

    asset = OpenbisExternalAsset.find_or_create_by_entity(@zample)
    refute asset.seek_entity

    study = FactoryBot.create :study, contributor: @user
    assay_params = { study_id: study.id }

    sync_options = {}
    reg_status = controller.do_entity_registration(asset, assay_params, sync_options, @user)
    assert reg_status

    assay = reg_status.primary
    assert assay
    assert_equal assay, asset.seek_entity
    assert_equal study, assay.study
    assert_equal [], reg_status.issues
  end

  test 'do_entity_registration sets issues on errors if not recovable' do
    controller = OpenbisZamplesController.new

    exassay = FactoryBot.create :assay

    asset = OpenbisExternalAsset.build(@zample)
    asset.seek_entity = exassay
    assert asset.save

    study = FactoryBot.create :study
    assay_params = { study_id: study.id }

    sync_options = {}

    reg_status = controller.do_entity_registration(asset, assay_params, sync_options, @user)
    assert reg_status

    assay = reg_status.primary
    refute assay

    issues = reg_status.issues
    assert issues
    assert_equal 1, issues.size
  end

  test 'do_entity_registration creates assay links datasets if sync_option says so' do
    controller = OpenbisZamplesController.new
    login_as(@user)

    asset = OpenbisExternalAsset.find_or_create_by_entity(@zample)
    refute asset.seek_entity

    study = FactoryBot.create :study, contributor: @user
    assay_params = { study_id: study.id }

    sync_options = { link_datasets: '1' }

    reg_status = controller.do_entity_registration(asset, assay_params, sync_options, @user)
    assert reg_status

    assay = reg_status.primary
    assert assay
    assert_equal assay, asset.seek_entity
    assert_equal study, assay.study
    assert_equal [], reg_status.issues
    assert_equal 3, assay.data_files.size
  end

  test 'do_entity_registration creates assay links selected datasets' do
    controller = OpenbisZamplesController.new
    login_as(@user)

    asset = OpenbisExternalAsset.find_or_create_by_entity(@zample)
    refute asset.seek_entity

    study = FactoryBot.create :study, contributor: @user
    assay_params = { study_id: study.id }

    sync_options = { link_datasets: '0', linked_datasets: @zample.dataset_ids[0..1] }

    reg_status = controller.do_entity_registration(asset, assay_params, sync_options, @user)
    assert reg_status

    assay = reg_status.primary
    assert assay
    assert_equal assay, asset.seek_entity
    assert_equal study, assay.study
    assert_equal [], reg_status.issues
    assert_equal 2, assay.data_files.size
  end

  ## registration end ##
end
