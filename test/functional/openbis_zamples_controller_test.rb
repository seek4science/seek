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
    assay = assigns(:assay)
    assay = assigns(:zample)
    assay = assigns(:linked_to_assay)

  end

  test 'register registers new Assay' do
    login_as(@user)
    study = Factory :study

    post :register, project_id: @project.id, openbis_endpoint_id: @endpoint.id, id: '20171002172111346-37', assay: {study_id: study.id }

    assay = assigns(:assay)
    assert_not_nil assay
    assert_redirected_to assay_path(assay)

    assert assay.persisted?
    assert_equal 'OpenBIS 20171002172111346-37', assay.title

    assert assay.external_asset.persisted?

    assert_equal 'Registered OpenBIS assay: 20171002172111346-37', flash[:notice]
  end

  test 'register remains on registration screen on errors' do
    login_as(@user)
    study = Factory :study

    post :register, project_id: @project.id, openbis_endpoint_id: @endpoint.id, id: '20171002172111346-37', assay: {xl:true }

    assert_response :success

    assay = assigns(:assay)
    assert_not_nil assay
    refute assay.persisted?

    assert assigns(:reasons)
    assert assigns(:error_msg)
    assert_select "div.alert-danger", /Could not register OpenBIS assay/

  end

  test 'register does not create if assay if zample already registered but redirects to it' do
    login_as(@user)
    study = Factory :study
    existing = Factory :assay

    external = OpenbisExternalAsset.build(@zample)
    assert external.save
    existing.external_asset = external
    assert existing.save

    post :register, project_id: @project.id, openbis_endpoint_id: @endpoint.id, id: "#{@zample.perm_id}", assay: {study_id: study.id }

    assert_redirected_to assay_path(existing)

    assert_equal 'Already registered as OpenBIS entity', flash[:error]

  end


  # unit like tests
  test 'extract_requested_sets gives all sets from zample if linked is selected' do

    controller = OpenbisZamplesController.new

    assert_equal 3, @zample.dataset_ids.length
    params = {}

    assert_equal [], controller.extract_requested_sets(@zample, params)
    params = { link_datasets: '1' }
    assert_same @zample.dataset_ids, controller.extract_requested_sets(@zample, params)
    params = { link_datasets: '1', linked_datasets: ['123'] }
    assert_same @zample.dataset_ids, controller.extract_requested_sets(@zample, params)

  end

  test 'extract_requested_sets gives only selected sets that belongs to zample' do

    controller = OpenbisZamplesController.new

    assert_equal 3, @zample.dataset_ids.length
    params = {}
    assert_equal [], controller.extract_requested_sets(@zample, params)
    params = { linked_datasets: [] }
    assert_equal [], controller.extract_requested_sets(@zample, params)
    params = { linked_datasets: ['123'] }
    assert_equal [], controller.extract_requested_sets(@zample, params)
    params = { linked_datasets: ['123', @zample.dataset_ids[0]] }
    assert_equal [@zample.dataset_ids[0]], controller.extract_requested_sets(@zample, params)
    params = { linked_datasets: @zample.dataset_ids }
    assert_equal @zample.dataset_ids, controller.extract_requested_sets(@zample, params)

  end

  test 'find_or_register_seek_files fetches existing or creates new datafiles with openbis content' do

    login_as(@project_administrator)
    controller = OpenbisZamplesController.new

    datasets = Seek::Openbis::Dataset.new(@endpoint).find_by_perm_ids(["20171002172401546-38", "20171002190934144-40","20171004182824553-41"])
    assert_equal 3, datasets.length

    datafile1 = DataFile.build_from_openbis_dataset(datasets[1])
    datafile1.save!

    assert_difference('DataFile.count', 2) do

        datafiles = controller.find_or_register_seek_files(datasets)
        assert_equal datasets.length, datafiles.length
        assert_equal datafile1, datafiles[1];
    end

  end

  test 'get_linked_to gets ids of openbis data sets' do
    controller = OpenbisZamplesController.new

    assert_equal [], controller.get_linked_to(nil)

    datasets = Seek::Openbis::Dataset.new(@endpoint).find_by_perm_ids(["20171002172401546-38", "20171002190934144-40","20171004182824553-41"])
    datafiles = datasets.map { |ds| DataFile.build_from_openbis_dataset(ds)}
    assert_equal 3, datafiles.length

    disable_authorization_checks do
      datafiles.each { |df| df.save!}
    end

    normaldf = Factory :data_file

    assay = Factory :assay

    assay.data_files << normaldf
    assay.data_files << datafiles[0]
    assay.data_files << datafiles[1]
    assay.save!

    linked = controller.get_linked_to assay
    assert_equal 2, linked.length
    assert_equal ['20171004182824553-41','20171002190934144-40'], linked

  end
end
