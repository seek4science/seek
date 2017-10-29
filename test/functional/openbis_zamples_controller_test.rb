require 'test_helper'
require 'openbis_test_helper'

include SharingFormTestHelper

class OpenbisZamplesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  def setup
    mock_openbis_calls
    @project_administrator = Factory(:project_administrator)
    @project = @project_administrator.projects.first
    @user = Factory(:person)
    @user.add_to_project_and_institution(@project, @user.institutions.first)
    assert @user.save
    @endpoint = Factory(:openbis_endpoint, project: Factory(:project))
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
    get :index, project_id: @project.id, openbis_endpoint_id: @endpoint.id

    assert_response :success
  end

  test 'index renders parents details' do
    login_as(@user)
    get :index, project_id: @project.id, openbis_endpoint_id: @endpoint.id

    assert_response :success
    assert_select "div label", "Project:"
    assert_select "div.form-group", /#{@project.title}/
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

    puts "------------Before post"
    post :register, project_id: @project.id, openbis_endpoint_id: @endpoint.id, id: @zample.perm_id, assay: { study_id: study.id }, sync_options: sync_options
    puts "------------After post"


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

  ## Update ###
  test 'update updates sync options and follows dependencies' do
    login_as(@user)

    exassay = Factory :assay
    asset = OpenbisExternalAsset.build(@zample)
    exassay.external_asset = asset
    assert asset.save
    assert exassay.save
    refute @zample.dataset_ids.empty?


    sync_options = { 'link_datasets' => '1' }
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

    # TODO how to test for content update (or lack of it depends on decided simantics)


    last_mod = exassay.updated_at
    assay.reload
    # this test fails??? so asset is save probably due to relations updates
    # for same reason eql, so comparing ind fields does not work even if no update operations are visible in db
    assert_equal last_mod.to_a, assay.updated_at.to_a
    assert_equal @zample.dataset_ids.length, assay.data_files.length

    assert_nil flash[:error]
    assert_equal "Updated sync of OpenBIS assay: #{@zample.perm_id}", flash[:notice]
  end


  # unit like tests

  test 'associate_data_sets links datasets with assay creating new datafiles if necessary' do

    util = Seek::Openbis::SeekUtil.new
    controller = OpenbisZamplesController.new
    # controller.get_seek_util

    assay = Factory :assay

    df0 = Factory :data_file
    assay.associate(df0)
    assert df0.persisted?
    assert_equal 1, assay.data_files.length


    datasets = Seek::Openbis::Dataset.new(@endpoint).find_by_perm_ids(["20171002172401546-38", "20171002190934144-40", "20171004182824553-41"])
    assert_equal 3, datasets.length

    df1 = util.createObisDataFile(OpenbisExternalAsset.build(datasets[0]))
    assert df1.save

    assert_difference('AssayAsset.count', 3) do
      assert_difference('DataFile.count', 2) do
        assert_difference('ExternalAsset.count', 2) do

          assert_nil controller.associate_data_sets(assay, datasets)
        end
      end
    end

    assay.reload
    assert_equal 4, assay.data_files.length

  end

  test 'extract_requested_sets gives all sets from zample if linked is selected' do

    controller = OpenbisZamplesController.new

    assert_equal 3, @zample.dataset_ids.length
    params = ActionController::Parameters.new({})

    assert_equal [], controller.extract_requested_sets(@zample, params)
    params = ActionController::Parameters.new({ sync_options: { link_datasets: '1' } })
    assert_same @zample.dataset_ids, controller.extract_requested_sets(@zample, params)
    params = ActionController::Parameters.new({ sync_options: { link_datasets: '1', linked_datasets: ['123'] } })
    assert_same @zample.dataset_ids, controller.extract_requested_sets(@zample, params)

  end

  test 'extract_requested_sets gives only selected sets that belongs to zample' do

    controller = OpenbisZamplesController.new

    assert_equal 3, @zample.dataset_ids.length
    params = ActionController::Parameters.new({})
    assert_equal [], controller.extract_requested_sets(@zample, params)
    params = ActionController::Parameters.new({ linked_datasets: [] })
    assert_equal [], controller.extract_requested_sets(@zample, params)
    params = ActionController::Parameters.new({ linked_datasets: ['123'] })
    assert_equal [], controller.extract_requested_sets(@zample, params)
    params = ActionController::Parameters.new({ linked_datasets: ['123', @zample.dataset_ids[0]] })
    assert_equal [@zample.dataset_ids[0]], controller.extract_requested_sets(@zample, params)
    params = ActionController::Parameters.new({ linked_datasets: @zample.dataset_ids })
    assert_equal @zample.dataset_ids, controller.extract_requested_sets(@zample, params)

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
