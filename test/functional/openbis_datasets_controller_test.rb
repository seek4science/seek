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
    @endpoint = Factory(:openbis_endpoint, project: Factory(:project))
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
    assert_select '#openbis-dataset-cards div.openbis-card', count: 8
  end

  test 'edit renders edit view' do
    login_as(@user)
    get :edit, project_id: @project.id, openbis_endpoint_id: @endpoint.id, id: @dataset.perm_id

    assert_response :success
    assert assigns(:entity)
    assert assigns(:asset)
    assert assigns(:datafile)

  end

  ## Register ##

  test 'register registers new DataFile' do
    login_as(@user)

    puts "----------- BEFORE REG"
    post :register, project_id: @project.id, openbis_endpoint_id: @endpoint.id, id: @dataset.perm_id
    puts "----------- AFTER REG"

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


  test 'register does not create datafile if dataset already registered but redirects to it' do
    login_as(@user)
    existing = Factory :data_file

    external = OpenbisExternalAsset.build(@dataset)
    assert external.save
    existing.external_asset = external
    assert existing.save

    post :register, project_id: @project.id, openbis_endpoint_id: @endpoint.id, id: "#{@dataset.perm_id}"

    assert_redirected_to data_file_path(existing)

    assert_equal 'Already registered as OpenBIS entity', flash[:error]

  end

  ## Update ###
  test 'update updates content and redirects' do
    login_as(@user)

    exdatafile = Factory :data_file
    asset = OpenbisExternalAsset.build(@dataset)
    exdatafile.external_asset = asset
    assert asset.save
    assert exdatafile.save

    post :update, project_id: @project.id, openbis_endpoint_id: @endpoint.id, id: @dataset.perm_id


    datafile = assigns(:datafile)
    assert_not_nil datafile
    assert_equal exdatafile, datafile
    assert_redirected_to data_file_path(datafile)

    last_mod = asset.updated_at
    asset.reload
    assert_not_equal last_mod, asset.updated_at

    # TODO how to test for content update (or lack of it depends on decided simantics)


    last_mod = exdatafile.updated_at
    datafile.reload
    # for same reason eql, so comparing ind fields does not work even if no update operations are visible in db
    assert_equal last_mod.to_a, datafile.updated_at.to_a

    assert_nil flash[:error]
    assert_equal "Updated sync of OpenBIS datafile: #{@dataset.perm_id}", flash[:notice]
  end


  # unit like tests

end
