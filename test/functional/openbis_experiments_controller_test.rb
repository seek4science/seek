require 'test_helper'
require 'openbis_test_helper'

class OpenbisExperimentsControllerTest < ActionController::TestCase
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
    @experiment = Seek::Openbis::Experiment.new(@endpoint, '20171121152132641-51')

    @controller = OpenbisExperimentsController.new
  end

  test 'test setup works' do
    assert @user
    assert @project_administrator
    assert @project
    assert_includes @user.projects, @project
    assert @endpoint
    assert @experiment
    assert @controller
  end

  test 'index gives index view' do
    login_as(@user)
    get :index, params: { openbis_endpoint_id: @endpoint.id }

    assert_response :success
  end

  test 'index sets assay_types and entities' do
    login_as(@user)
    get :index, params: { openbis_endpoint_id: @endpoint.id }

    assert_response :success
    assert assigns(:entity_types)
    assert assigns(:entity_types_codes)
    assert assigns(:entity_type_options)
    assert assigns(:entity_type)
    assert_equal 'ALL STUDIES', assigns(:entity_type)
    assert_includes assigns(:entity_type_options), 'ALL STUDIES'
    assert_includes assigns(:entity_type_options), 'ALL TYPES'
    assert assigns(:entities)
    assert_equal 1, assigns(:entities).size
  end

  test 'index filters by entity_type' do
    login_as(@user)

    get :index, params: { openbis_endpoint_id: @endpoint.id, entity_type: 'DEFAULT_EXPERIMENT' }

    assert_response :success
    assert_equal 1, assigns(:entities).size

    get :index, params: { openbis_endpoint_id: @endpoint.id, entity_type: 'ALL TYPES' }

    assert_response :success
    assert_equal 2, assigns(:entities).size
  end

  test 'index renders parents details' do
    login_as(@user)
    get :index, params: { openbis_endpoint_id: @endpoint.id, entity_type: 'ALL TYPES' }

    assert_response :success
    assert_select 'div label', 'Project:'
    assert_select 'div.form-group', /#{@endpoint.project.title}/
    assert_select 'div label', 'Endpoint:'
    assert_select 'div.form-group', /#{@endpoint.title}/
    # assert_select "div", "Endpoint: #{@endpoint.id}"
    # assert_select "div", "Samples: 2"
    assert_select '#openbis-experiments-cards div.openbis-card', count: 2
  end

  test 'edit gives edit view' do
    login_as(@user)
    get :edit, params: { openbis_endpoint_id: @endpoint.id, id: '20171121152132641-51' }

    assert_response :success
    assert assigns(:study)
    assert assigns(:seek_entity)
    assert assigns(:asset)
    assert assigns(:entity)
    assert assigns(:zamples_linked_to)
    assert assigns(:datasets_linked_to)
  end

  test 'refresh updates content with fetched version and redirects' do
    login_as(@user)

    fake = Seek::Openbis::Experiment.new(@endpoint, '20171121153715264-58')
    assert_not_equal fake.perm_id, @experiment.perm_id

    old = DateTime.now - 1.days
    asset = OpenbisExternalAsset.build(@experiment)
    asset.content = fake
    asset.synchronized_at = old
    st = FactoryBot.create :study
    asset.seek_entity = st
    assert asset.save

    # just a paranoid check, in case future implementation will mess up with setting stamps and content
    asset = OpenbisExternalAsset.find(asset.id)
    assert_equal fake.perm_id, asset.content.perm_id
    assert_equal old.to_date, asset.synchronized_at.to_date

    get :refresh, params: { openbis_endpoint_id: @endpoint.id, id: @experiment.perm_id }

    assert_response :redirect
    assert_redirected_to st

    asset = OpenbisExternalAsset.find(asset.id)
    assert_equal @experiment.perm_id, asset.content.perm_id
    assert_equal DateTime.now.to_date, asset.synchronized_at.to_date
  end

  ## Register ##

  test 'register registers new Study with linked Assays' do
    login_as(@user)
    investigation = FactoryBot.create :investigation, contributor: @user

    refute @experiment.sample_ids.empty?

    sync_options = { 'link_assays' => '1' }

    post :register, params: { openbis_endpoint_id: @endpoint.id, id: @experiment.perm_id, study: { investigation_id: investigation.id }, sync_options: sync_options }

    study = assigns(:seek_entity)
    assert_not_nil study
    assert_redirected_to study_path(study)

    assert study.persisted?
    assert_equal "#{@experiment.properties['NAME']} OpenBIS #{@experiment.code}", study.title

    assert study.external_asset.persisted?

    study.reload
    assert_equal @experiment.sample_ids.length, study.assays.length

    assert_nil flash[:error]
    assert_equal 'Registered OpenBIS Experiment 20171121152132641-51 as Study', flash[:notice]
  end

  test 'register registers new Study with selected Assays' do
    login_as(@user)
    investigation = FactoryBot.create :investigation, contributor: @user

    refute @experiment.sample_ids.size < 2
    to_link = [@experiment.sample_ids[0]]

    sync_options = { 'link_assays' => '0', 'linked_assays' => to_link }

    post :register, params: { openbis_endpoint_id: @endpoint.id, id: @experiment.perm_id, study: { investigation_id: investigation.id }, sync_options: sync_options }

    study = assigns(:seek_entity)
    assert_not_nil study
    assert_redirected_to study_path(study)

    assert study.persisted?
    assert_equal "#{@experiment.properties['NAME']} OpenBIS #{@experiment.code}", study.title

    assert study.external_asset.persisted?

    study.reload
    assert_equal to_link.length, study.assays.length

    assert_nil flash[:error]
    assert_equal 'Registered OpenBIS Experiment 20171121152132641-51 as Study', flash[:notice]
  end

  test 'register registers new Study with linked datasets in special assay' do
    login_as(@user)
    investigation = FactoryBot.create :investigation, contributor: @user

    refute @experiment.sample_ids.empty?

    sync_options = { 'link_datasets' => '1' }

    post :register, params: { openbis_endpoint_id: @endpoint.id, id: @experiment.perm_id, study: { investigation_id: investigation.id }, sync_options: sync_options }

    study = assigns(:seek_entity)
    assert_not_nil study
    assert_redirected_to study_path(study)

    assert study.persisted?

    study.reload

    files_assay = study.assays.where(title: 'OpenBIS FILES').first
    assert files_assay

    assert_equal @experiment.dataset_ids.length, files_assay.data_files.length

    assert_nil flash[:error]
    assert_equal 'Registered OpenBIS Experiment 20171121152132641-51 as Study', flash[:notice]
  end

  test 'register registers new Study with selected datasets in special assay' do
    login_as(@user)
    investigation = FactoryBot.create :investigation, contributor: @user

    refute @experiment.sample_ids.empty?

    to_link = ['20171002190934144-40']
    sync_options = { 'link_datasets' => '0', 'linked_datasets' => to_link }

    post :register, params: { openbis_endpoint_id: @endpoint.id, id: @experiment.perm_id, study: { investigation_id: investigation.id }, sync_options: sync_options }

    study = assigns(:seek_entity)
    assert_not_nil study
    assert_redirected_to study_path(study)

    assert study.persisted?

    study.reload

    files_assay = study.assays.where(title: 'OpenBIS FILES').first
    assert files_assay

    assert_equal to_link.length, files_assay.data_files.length
  end

  test 'register registers new Study with selected datasets in special assay and inside selected assay' do
    login_as(@user)
    investigation = FactoryBot.create :investigation, contributor: @user

    refute @experiment.sample_ids.empty?

    to_link_s = ['20171002172111346-37']
    to_link_d = ['20171002190934144-40']
    sync_options = { 'link_datasets' => '0', 'linked_datasets' => to_link_d, 'linked_assays' => to_link_s }

    post :register, params: { openbis_endpoint_id: @endpoint.id, id: @experiment.perm_id, study: { investigation_id: investigation.id }, sync_options: sync_options }

    study = assigns(:seek_entity)
    assert_not_nil study
    assert_redirected_to study_path(study)

    assert study.persisted?

    study.reload

    files_assay = study.assays.where(title: 'OpenBIS FILES').first
    assert files_assay

    assert_equal to_link_d.length, files_assay.data_files.length

    zample = Seek::Openbis::Zample.new(@endpoint).find_by_perm_ids(to_link_s)[0]
    assert zample

    assay = OpenbisExternalAsset.find_by_entity(zample).seek_entity
    assert assay

    assert_equal to_link_d.length, assay.data_files.length
  end

  test 'register creates new entries in Activity log for Study and dependent assays and files' do
    login_as(@user)
    investigation = FactoryBot.create :investigation, contributor: @user

    refute @experiment.sample_ids.empty?

    sync_options = { 'link_assays' => '1', 'link_datasets' => '1' }
    exp_logs = 1 + @experiment.sample_ids.count + @experiment.dataset_ids.count + 1 # extra assay for files

    assert_difference('ActivityLog.count', exp_logs) do
      post :register, params: { openbis_endpoint_id: @endpoint.id, id: @experiment.perm_id, study: { investigation_id: investigation.id }, sync_options: sync_options }

      study = assigns(:seek_entity)
      assert_not_nil study
      assert_redirected_to study_path(study)
    end
  end

  test 'register redirects to registration screen on errors' do
    login_as(@user)

    refute @experiment.sample_ids.empty?

    sync_options = { 'link_assays' => '1' }

    post :register, params: { openbis_endpoint_id: @endpoint.id, id: @experiment.perm_id, study: { xl: true }, sync_options: sync_options }

    assert_response :redirect
    assert_redirected_to action: :edit
    assert flash[:error]

    # study = assigns(:study)
    # assert_not_nil study
    # refute study.persisted?

    # assert assigns(:reasons)
    # assert assigns(:error_msg)
    # assert_select 'div.alert-danger', /Could not register OpenBIS study/
  end

  test 'register does not create study if experiment already registered but redirects to it' do
    login_as(@user)
    investigation = FactoryBot.create :investigation
    existing = FactoryBot.create :study

    external = OpenbisExternalAsset.build(@experiment)
    assert external.save
    existing.external_asset = external
    assert existing.save

    sync_options = { 'link_assays' => '0' }

    post :register, params: { openbis_endpoint_id: @endpoint.id, id: @experiment.perm_id, study: { investigation_id: investigation.id }, sync_options: sync_options }

    assert_redirected_to study_path(existing)

    assert_equal 'OpenBIS entity already registered in Seek', flash[:error]
  end

  ## Batch register ##

  test 'batch registers multiple Studies' do
    login_as(@user)
    investigation = FactoryBot.create :investigation, contributor: @user

    sync_options = { link_dependent: 'false' }
    batch_ids = ['20171121153715264-58', '20171121152132641-51']

    assert_difference('Study.count', 2) do
      assert_no_difference('Assay.count') do
        assert_no_difference('DataFile.count') do
          assert_difference('ExternalAsset.count', 2) do
            post :batch_register, params: { openbis_endpoint_id: @endpoint.id, seek_parent: investigation.id, sync_options: sync_options, batch_ids: batch_ids }
          end
        end
      end
    end

    assert_response :success
    refute flash[:error]
    assert_equal "Registered all #{batch_ids.size} OpenBIS entities", flash[:notice]

    investigation.reload
    assert_equal batch_ids.size, investigation.studies.size
  end

  # test for a bug
  test 'batch register makes independent descriptions' do
    login_as(@user)
    investigation = FactoryBot.create :investigation, contributor: @user

    sync_options = { link_dependent: 'false' }
    batch_ids = ['20171121153715264-58', '20171121152132641-51']

    post :batch_register, params: { openbis_endpoint_id: @endpoint.id, seek_parent: investigation.id, sync_options: sync_options, batch_ids: batch_ids }

    assert_response :success

    investigation.reload
    assert_equal batch_ids.size, investigation.studies.size
    titles = investigation.studies.map(&:title).uniq
    assert_equal batch_ids.size, titles.size
  end

  test 'batch registers multiple Studies and follows assays and datasets' do
    login_as(@user)
    investigation = FactoryBot.create :investigation, contributor: @user

    sync_options = { link_dependent: '1' }
    batch_ids = ['20171121153715264-58', '20171121152132641-51']

    # 20171121152132641-51 2 samples, 20171121153715264-58 no samples
    # plus 2 fake assays for files
    assays = 2 + batch_ids.size
    # 20171121152132641-51 3 sets, 20171121153715264-58 1 set
    datasets = 3 + 1
    # 2 studies, 2 assays, 4 files
    externals = batch_ids.size + (assays - batch_ids.size) + datasets

    assert_difference('Study.count', 2) do
      assert_difference('Assay.count', assays) do
        assert_difference('DataFile.count', datasets) do
          assert_difference('ExternalAsset.count', externals) do
            post :batch_register, params: { openbis_endpoint_id: @endpoint.id, seek_parent: investigation.id, sync_options: sync_options, batch_ids: batch_ids }
          end
        end
      end
    end

    assert_response :success
    refute flash[:error]
    assert_equal "Registered all #{batch_ids.size} OpenBIS entities", flash[:notice]

    investigation.reload
    assert_equal batch_ids.size, investigation.studies.size
  end

  test 'batch registers creates Activity log for all created seek objects' do
    login_as(@user)
    investigation = FactoryBot.create :investigation, contributor: @user

    sync_options = { link_dependent: '1' }
    batch_ids = ['20171121153715264-58', '20171121152132641-51']

    # 20171121152132641-51 2 samples, 20171121153715264-58 no samples
    # plus 2 fake assays for files
    assays = 2 + batch_ids.size
    # 20171121152132641-51 3 sets, 20171121153715264-58 1 set
    datasets = 3 + 1

    exp_logs = batch_ids.size + assays + datasets

    assert_difference('ActivityLog.count', exp_logs) do
      post :batch_register, params: { openbis_endpoint_id: @endpoint.id, seek_parent: investigation.id, sync_options: sync_options, batch_ids: batch_ids }
    end

    assert_response :success
    refute flash[:error]

    investigation.reload
    assert_equal batch_ids.size, investigation.studies.size
  end

  ## END --- Batch register ##

  ## Update ###
  test 'update updates sync options and follows dependencies' do
    login_as(@user)

    exstudy = FactoryBot.create :study, contributor: @user
    asset = OpenbisExternalAsset.build(@experiment)
    asset.synchronized_at = 2.days.ago
    asset.created_at = 2.days.ago
    asset.updated_at = 2.days.ago
    exstudy.external_asset = asset
    assert asset.save
    assert exstudy.save
    refute @experiment.sample_ids.empty?

    sync_options = { link_assays: '1' }
    assert_not_equal sync_options, asset.sync_options
    assert_not_equal DateTime.now.to_date, asset.synchronized_at.to_date

    post :update, params: { openbis_endpoint_id: @endpoint.id, id: @experiment.perm_id, sync_options: sync_options }

    study = assigns(:seek_entity)
    assert_not_nil study
    assert_equal exstudy, study
    assert_redirected_to study_path(study)

    last_mod = asset.updated_at
    asset.reload
    assert_equal sync_options, asset.sync_options
    assert_not_equal last_mod, asset.updated_at

    # testing content update just by synchronized stamp
    assert_equal DateTime.now.to_date, asset.synchronized_at.to_date

    last_mod = exstudy.updated_at
    study.reload
    assert_equal last_mod.to_a, study.updated_at.to_a
    assert_equal @experiment.sample_ids.length, study.assays.length

    assert_nil flash[:error]
    assert_equal "Updated registration of Experiment #{@experiment.perm_id}", flash[:notice]
  end

  test 'update updates sync options and adds selected datasets' do
    login_as(@user)

    exstudy = FactoryBot.create :study, contributor: @user
    asset = OpenbisExternalAsset.build(@experiment)
    exstudy.external_asset = asset
    assert asset.save
    assert exstudy.save

    assert @experiment.sample_ids.size > 1

    to_link = [@experiment.sample_ids[0]]
    sync_options = { link_assays: '0', linked_assays: to_link }
    assert_not_equal sync_options, asset.sync_options

    post :update, params: { openbis_endpoint_id: @endpoint.id, id: @experiment.perm_id, sync_options: sync_options }

    study = assigns(:seek_entity)
    assert_not_nil study
    assert_equal exstudy, study
    assert_redirected_to study_path(study)

    asset.reload
    assert_equal sync_options, asset.sync_options

    assert_equal to_link.length, study.assays.length

    assert_nil flash[:error]
  end

  ## permissions ##
  test 'only project members can call actions' do
    logout
    get :index, params: { openbis_endpoint_id: @endpoint.id }
    assert_response :redirect

    get :edit, params: { openbis_endpoint_id: @endpoint.id, id: '20171121152132641-51' }
    assert_response :redirect

    investigation = FactoryBot.create :investigation, contributor: @user
    sync_options = {}
    batch_ids = ['20171121153715264-58', '20171121152132641-51']

    post :register, params: { openbis_endpoint_id: @endpoint.id, id: @experiment.perm_id, study: { investigation_id: investigation.id }, sync_options: sync_options }
    assert_response :redirect
    assert_redirected_to :root

    post :batch_register, params: { openbis_endpoint_id: @endpoint.id, seek_parent: investigation.id, sync_options: sync_options, batch_ids: batch_ids }
    assert_response :redirect
    assert_redirected_to :root

    login_as(@user)

    get :index, params: { openbis_endpoint_id: @endpoint.id }
    assert_response :success

    get :edit, params: { openbis_endpoint_id: @endpoint.id, id: '20171121152132641-51' }
    assert_response :success

    post :register, params: { openbis_endpoint_id: @endpoint.id, id: @experiment.perm_id, study: { investigation_id: investigation.id }, sync_options: sync_options }
    assert_response :redirect
    seek = assigns(:seek_entity)
    assert_not_nil seek
    assert_redirected_to seek

    post :batch_register, params: { openbis_endpoint_id: @endpoint.id, seek_parent: investigation.id, sync_options: sync_options, batch_ids: batch_ids }
    assert_response :success
  end

  # unit like tests

  ## registration ##
  test 'do_entity_registration makes study from experiment and returns status info' do
    asset = OpenbisExternalAsset.find_or_create_by_entity(@experiment)
    login_as(@user)
    refute asset.seek_entity

    investigation = FactoryBot.create :investigation, contributor: @user
    study_params = { investigation_id: investigation.id }

    sync_options = {}

    reg_status = @controller.do_entity_registration(asset, study_params, sync_options, @user)
    assert reg_status

    study = reg_status.primary
    assert study
    assert_equal study, asset.seek_entity
    assert_equal investigation, study.investigation
    assert_equal [], reg_status.issues
  end

  test 'do_entity_registration sets issues on errors if not recovable' do
    ex = FactoryBot.create :study

    asset = OpenbisExternalAsset.build(@experiment)
    asset.seek_entity = ex
    assert asset.save

    investigation = FactoryBot.create :investigation
    study_params = { investigation_id: investigation.id }

    sync_options = {}

    reg_status = @controller.do_entity_registration(asset, study_params, sync_options, @user)
    assert reg_status

    study = reg_status.primary
    refute study

    issues = reg_status.issues
    assert issues
    assert_equal 1, issues.size
  end

  test 'do_entity_registration creates study links assays if sync_option says so' do
    asset = OpenbisExternalAsset.build(@experiment)

    login_as(@user)

    refute asset.seek_entity

    investigation = FactoryBot.create :investigation, contributor: @user
    study_params = { investigation_id: investigation.id }

    sync_options = { link_assays: '1' }

    reg_status = @controller.do_entity_registration(asset, study_params, sync_options, @user)
    assert reg_status

    study = reg_status.primary
    assert study
    assert_equal study, asset.seek_entity
    assert_equal investigation, study.investigation
    assert_equal [], reg_status.issues
    assert_equal 2, study.assays.size
  end

  test 'do_entity_registration creates study links selected assays' do
    asset = OpenbisExternalAsset.build(@experiment)
    login_as(@user)
    refute asset.seek_entity

    investigation = FactoryBot.create :investigation, contributor: @user
    study_params = { investigation_id: investigation.id }

    to_link = [@experiment.sample_ids[0]]
    sync_options = { link_assays: '0', linked_assays: to_link }

    reg_status = @controller.do_entity_registration(asset, study_params, sync_options, @user)
    assert reg_status

    study = reg_status.primary
    assert study
    assert_equal study, asset.seek_entity
    assert_equal investigation, study.investigation
    assert_equal [], reg_status.issues
    assert_equal 1, study.assays.size
  end

  ## registration end ##
end
