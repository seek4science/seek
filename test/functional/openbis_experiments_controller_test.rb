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
    get :index, openbis_endpoint_id: @endpoint.id

    assert_response :success
  end

  test 'index sets assay_types and entities' do
    login_as(@user)
    get :index, openbis_endpoint_id: @endpoint.id

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

    get :index, openbis_endpoint_id: @endpoint.id, entity_type: 'DEFAULT_EXPERIMENT'

    assert_response :success
    assert_equal 1, assigns(:entities).size

    get :index, openbis_endpoint_id: @endpoint.id, entity_type: 'ALL TYPES'

    assert_response :success
    assert_equal 2, assigns(:entities).size
  end


  test 'index renders parents details' do
    login_as(@user)
    get :index, openbis_endpoint_id: @endpoint.id, entity_type: 'ALL TYPES'

    assert_response :success
    assert_select "div label", "Project:"
    assert_select "div.form-group", /#{@endpoint.project.title}/
    assert_select "div label", "Endpoint:"
    assert_select "div.form-group", /#{@endpoint.title}/
    # assert_select "div", "Endpoint: #{@endpoint.id}"
    # assert_select "div", "Samples: 2"
    assert_select '#openbis-experiments-cards div.openbis-card', count: 2
  end

  test 'edit gives edit view' do
    login_as(@user)
    get :edit, openbis_endpoint_id: @endpoint.id, id: '20171121152132641-51'

    assert_response :success
    assert assigns(:study)
    assert assigns(:asset)
    assert assigns(:entity)
    assert assigns(:zamples_linked_to_study)
    assert assigns(:datasets_linked_to_study)

  end

  ## Register ##

  test 'register registers new Study with linked Assays' do
    login_as(@user)
    investigation = Factory :investigation

    refute @experiment.sample_ids.empty?

    sync_options = { 'link_assays' => '1' }

    post :register, openbis_endpoint_id: @endpoint.id, id: @experiment.perm_id,
         study: { investigation_id: investigation.id },
         sync_options: sync_options


    study = assigns(:study)
    assert_not_nil study
    assert_redirected_to study_path(study)

    assert study.persisted?
    assert_equal 'OpenBIS 20171121152132641-51', study.title

    assert study.external_asset.persisted?

    study.reload
    assert_equal @experiment.sample_ids.length, study.assays.length

    assert_nil flash[:error]
    assert_equal 'Registered OpenBIS Study: 20171121152132641-51', flash[:notice]
  end

  test 'register registers new Study with selected Assays' do
    login_as(@user)
    investigation = Factory :investigation

    refute @experiment.sample_ids.size < 2
    to_link = [@experiment.sample_ids[0]]

    sync_options = { 'link_assays' => '0', 'linked_assays' =>  to_link}

    post :register, openbis_endpoint_id: @endpoint.id, id: @experiment.perm_id,
         study: { investigation_id: investigation.id },
         sync_options: sync_options


    study = assigns(:study)
    assert_not_nil study
    assert_redirected_to study_path(study)

    assert study.persisted?
    assert_equal 'OpenBIS 20171121152132641-51', study.title

    assert study.external_asset.persisted?

    study.reload
    assert_equal to_link.length, study.assays.length

    assert_nil flash[:error]
    assert_equal 'Registered OpenBIS Study: 20171121152132641-51', flash[:notice]
  end

  test 'register registers new Study with linked datasets in special assay' do
    login_as(@user)
    investigation = Factory :investigation

    refute @experiment.sample_ids.empty?

    sync_options = { 'link_datasets' => '1' }

    post :register, openbis_endpoint_id: @endpoint.id, id: @experiment.perm_id,
         study: { investigation_id: investigation.id },
         sync_options: sync_options


    study = assigns(:study)
    assert_not_nil study
    assert_redirected_to study_path(study)

    assert study.persisted?

    study.reload

    files_assay = study.assays.where(title: 'OpenBIS FILES').first
    assert files_assay

    assert_equal @experiment.dataset_ids.length, files_assay.data_files.length

    assert_nil flash[:error]
    assert_equal 'Registered OpenBIS Study: 20171121152132641-51', flash[:notice]
  end

  test 'register registers new Study with selected datasets in special assay' do
    login_as(@user)
    investigation = Factory :investigation

    refute @experiment.sample_ids.empty?

    to_link = ['20171002190934144-40']
    sync_options = { 'link_datasets' => '0', 'linked_datasets' => to_link }

    post :register, openbis_endpoint_id: @endpoint.id, id: @experiment.perm_id,
         study: { investigation_id: investigation.id },
         sync_options: sync_options


    study = assigns(:study)
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
    investigation = Factory :investigation

    refute @experiment.sample_ids.empty?

    to_link_s = ['20171002172111346-37']
    to_link_d = ['20171002190934144-40']
    sync_options = { 'link_datasets' => '0', 'linked_datasets' => to_link_d, 'linked_assays' => to_link_s}

    post :register, openbis_endpoint_id: @endpoint.id, id: @experiment.perm_id,
         study: { investigation_id: investigation.id },
         sync_options: sync_options


    study = assigns(:study)
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



  test 'register remains on registration screen on errors' do
    login_as(@user)
    investigation = Factory :investigation

    refute @experiment.sample_ids.empty?

    sync_options = { 'link_assays' => '1' }

    post :register, openbis_endpoint_id: @endpoint.id, id: @experiment.perm_id,
         study: { xl: true },
         sync_options: sync_options


    assert_response :success

    study = assigns(:study)
    assert_not_nil study
    refute study.persisted?

    assert assigns(:reasons)
    assert assigns(:error_msg)
    assert_select "div.alert-danger", /Could not register OpenBIS study/

  end

  test 'register does not create study if experiment already registered but redirects to it' do
    login_as(@user)
    investigation = Factory :investigation
    existing = Factory :study

    external = OpenbisExternalAsset.build(@experiment)
    assert external.save
    existing.external_asset = external
    assert existing.save

    sync_options = { 'link_assays' => '0' }

    post :register, openbis_endpoint_id: @endpoint.id, id: @experiment.perm_id,
         study: { investigation_id: investigation.id },
         sync_options: sync_options

    assert_redirected_to study_path(existing)

    assert_equal 'Already registered as OpenBIS entity', flash[:error]

  end

  ## Batch register assay ##

  test 'batch registers multiple Studies' do

    login_as(@user)
    investigation = Factory :investigation

    sync_options = {link_dependent: 'false'}
    batch_ids = ["20171121153715264-58","20171121152132641-51"]

    assert_difference('Study.count', 2) do
      assert_no_difference('Assay.count') do
      assert_no_difference('DataFile.count') do
        assert_difference('ExternalAsset.count', 2) do

          post :batch_register, openbis_endpoint_id: @endpoint.id,
               seek_parent: investigation.id, sync_options: sync_options, batch_ids: batch_ids
        end
      end
      end
    end

    assert_response :success
    puts flash[:error]
    refute flash[:error]
    assert_equal "Registered all #{batch_ids.size} Studies", flash[:notice]

    investigation.reload
    assert_equal batch_ids.size, investigation.studies.size

  end

  test 'batch registers multiple Studies and follows assays and datasets' do

    login_as(@user)
    investigation = Factory :investigation

    sync_options = {link_dependent: '1'}
    batch_ids = ["20171121153715264-58","20171121152132641-51"]

    # 20171121152132641-51 2 samples, 20171121153715264-58 no samples
    # plus 2 fake assays for files
    assays = 2 + batch_ids.size
    # 20171121152132641-51 3 sets, 20171121153715264-58 1 set
    datasets = 3 + 1
    # 2 studies, 2 assays, 4 files
    externals = batch_ids.size + (assays-batch_ids.size) + datasets

    assert_difference('Study.count', 2) do
      assert_difference('Assay.count', assays) do
      assert_difference('DataFile.count', datasets) do
        assert_difference('ExternalAsset.count', externals) do

          post :batch_register, openbis_endpoint_id: @endpoint.id,
               seek_parent: investigation.id, sync_options: sync_options, batch_ids: batch_ids
        end
      end
      end
    end

    assert_response :success
    puts flash[:error]
    refute flash[:error]
    assert_equal "Registered all #{batch_ids.size} Studies", flash[:notice]

    investigation.reload
    assert_equal batch_ids.size, investigation.studies.size

  end


  ## END --- Batch register assay ##

  ## Update ###
  test 'update updates sync options and follows dependencies' do
    login_as(@user)

    exstudy = Factory :study
    asset = OpenbisExternalAsset.build(@experiment)
    exstudy.external_asset = asset
    assert asset.save
    assert exstudy.save
    refute @experiment.sample_ids.empty?


    sync_options = { link_assays: '1' }
    assert_not_equal sync_options, asset.sync_options

    post :update, openbis_endpoint_id: @endpoint.id, id: @experiment.perm_id, sync_options: sync_options

    study = assigns(:study)
    assert_not_nil study
    assert_equal exstudy, study
    assert_redirected_to study_path(study)

    last_mod = asset.updated_at
    asset.reload
    assert_equal sync_options, asset.sync_options
    assert_not_equal last_mod, asset.updated_at

    # TODO how to test for content update (or lack of it depends on decided semantics)


    last_mod = exstudy.updated_at
    study.reload
    # this test fails??? so asset is save probably due to relations updates
    # for same reason eql, so comparing ind fields does not work even if no update operations are visible in db
    assert_equal last_mod.to_a, study.updated_at.to_a
    assert_equal @experiment.sample_ids.length, study.assays.length

    assert_nil flash[:error]
    assert_equal "Updated sync of OpenBIS study: #{@experiment.perm_id}", flash[:notice]
  end

  test 'update updates sync options and adds selected datasets' do
    login_as(@user)

    exstudy = Factory :study
    asset = OpenbisExternalAsset.build(@experiment)
    exstudy.external_asset = asset
    assert asset.save
    assert exstudy.save

    assert @experiment.sample_ids.size > 1

    to_link = [@experiment.sample_ids[0]]
    sync_options = { link_assays: '0', linked_assays: to_link }
    assert_not_equal sync_options, asset.sync_options

    post :update, openbis_endpoint_id: @endpoint.id, id: @experiment.perm_id, sync_options: sync_options

    study = assigns(:study)
    assert_not_nil study
    assert_equal exstudy, study
    assert_redirected_to study_path(study)

    last_mod = asset.updated_at
    asset.reload
    assert_equal sync_options, asset.sync_options

    assert_equal to_link.length, study.assays.length

    assert_nil flash[:error]
    assert_equal "Updated sync of OpenBIS study: #{@experiment.perm_id}", flash[:notice]
  end

  # unit like tests

  ## registration ##
  test 'do_study_registration makes from experiment and returns status info' do


    asset = OpenbisExternalAsset.find_or_create_by_entity(@experiment)
    refute asset.seek_entity

    investigation = Factory :investigation
    study_params = { investigation_id: investigation.id }

    sync_options = {}

    reg_status = @controller.do_study_registration(asset, study_params, sync_options, @user)
    assert reg_status

    study = reg_status[:study]
    assert study
    assert_equal study, asset.seek_entity
    assert_equal investigation, study.investigation
    assert_equal [], reg_status[:issues]
  end

  test 'do_study_registration sets issues on errors if not recovable' do


    ex = Factory :study

    asset = OpenbisExternalAsset.build(@experiment)
    asset.seek_entity = ex
    assert asset.save

    investigation = Factory :investigation
    study_params = { investigation_id: investigation.id }

    sync_options = {}

    reg_status = @controller.do_study_registration(asset, study_params, sync_options, @user)
    assert reg_status

    study = reg_status[:study]
    refute study

    issues = reg_status[:issues]
    assert issues
    assert_equal 1, issues.size
  end

  test 'do_assay_registration creates study links assays if sync_option says so' do


    asset = asset = OpenbisExternalAsset.build(@experiment)
    refute asset.seek_entity

    investigation = Factory :investigation
    study_params = { investigation_id: investigation.id }

    sync_options = {link_assays: '1'}

    reg_status = @controller.do_study_registration(asset, study_params, sync_options, @user)
    assert reg_status

    study = reg_status[:study]
    assert study
    assert_equal study, asset.seek_entity
    assert_equal investigation, study.investigation
    assert_equal [], reg_status[:issues]
    assert_equal 2, study.assays.size
  end

  test 'do_assay_registration creates study links selected assays' do

    asset = asset = OpenbisExternalAsset.build(@experiment)
    refute asset.seek_entity

    investigation = Factory :investigation
    study_params = { investigation_id: investigation.id }

    to_link = [@experiment.sample_ids[0]]
    sync_options = { link_assays: '0', linked_assays: to_link }

    reg_status = @controller.do_study_registration(asset, study_params, sync_options, @user)
    assert reg_status

    study = reg_status[:study]
    assert study
    assert_equal study, asset.seek_entity
    assert_equal investigation, study.investigation
    assert_equal [], reg_status[:issues]
    assert_equal 1, study.assays.size
  end

  ## registration end ##



  test 'get_datasets_linked_to gets ids of openbis data sets' do

    util = Seek::Openbis::SeekUtil.new

    assert_equal [], @controller.get_datasets_linked_to(nil)

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

    study = assay.study
    assert study

    linked = @controller.get_datasets_linked_to study
    assert_equal 2, linked.length
    assert_equal ['20171004182824553-41', '20171002190934144-40'], linked

  end

  test 'get_zamples_linked_to gets ids of openbis zamples' do

    util = Seek::Openbis::SeekUtil.new

    assert_equal [], @controller.get_zamples_linked_to(nil)

    normalas = Factory :assay
    study = normalas.study

    zamples = Seek::Openbis::Zample.new(@endpoint).find_by_perm_ids(["20171002172111346-37", "20171002172639055-39"])

    assay_params = { study_id: study.id}
    assays = zamples.map { |ds| util.createObisAssay(assay_params, @user, OpenbisExternalAsset.build(ds)) }
    assert_equal 2, assays.length

    disable_authorization_checks do
      assays.each { |df| df.save! }
    end


    study.reload

    assert_equal 3, study.assays.size

    linked = @controller.get_zamples_linked_to study
    assert_equal 2, linked.length
    assert_equal ["20171002172111346-37", "20171002172639055-39"], linked

  end


end
