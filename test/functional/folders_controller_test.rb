require 'test_helper'

class FoldersControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  def setup
    @member = FactoryBot.create :user
    @project = @member.person.projects.first
    login_as @member
  end

  test 'routes' do
    assert_generates '/projects/1/folders', controller: 'folders', action: 'index', project_id: '1'
    assert_generates '/projects/1/folders/7', controller: 'folders', action: 'show', project_id: '1', id: '7'
  end

  test 'access as member' do
    get :index, params: { project_id: @project.id }
    assert_response :success
  end

  test 'delete' do
    sop = FactoryBot.create :sop, project_ids: [@project.id], policy: FactoryBot.create(:public_policy)
    folder = FactoryBot.create :project_folder, project_id: @project.id
    folder.add_assets(sop)
    child = folder.add_child('fred')
    child.save!
    unsorted_folder = FactoryBot.create :project_folder, project_id: @project.id, incoming: true

    assert_difference('ProjectFolder.count', -2) do
      delete :destroy, params: { id: folder.id, project_id: @project.id }
    end

    assert_redirected_to  Seek::Config.project_single_page_enabled ? single_page_path(@project) : :project_folders
    unsorted_folder.reload
    @project.reload
    assert_equal [unsorted_folder], ProjectFolder.where(project_id: @project.id).to_a
    assert_equal [sop], unsorted_folder.assets
  end

  test 'cannot delete if not deletable' do
    sop = FactoryBot.create :sop, project_ids: [@project.id], policy: FactoryBot.create(:public_policy)
    folder = FactoryBot.create :project_folder, project_id: @project.id, deletable: false
    folder.add_assets(sop)
    child = folder.add_child('fred')
    child.save!
    unsorted_folder = FactoryBot.create :project_folder, project_id: @project.id, incoming: true

    assert_no_difference('ProjectFolder.count') do
      delete :destroy, params: { id: folder.id, project_id: @project.id }
    end

    assert_redirected_to  Seek::Config.project_single_page_enabled ? single_page_path(@project) : :project_folders
    assert_not_nil flash[:error]
    unsorted_folder.reload
    folder.reload
    @project.reload
    assert_equal [folder, child, unsorted_folder], ProjectFolder.where(project_id: @project.id).to_a.sort_by(&:id)
    assert_equal [], unsorted_folder.assets
    assert_equal [sop], folder.assets
  end

  test 'cannot delete other project' do
    project = FactoryBot.create :project
    sop = FactoryBot.create :sop, project_ids: [project.id], policy: FactoryBot.create(:public_policy)
    folder = FactoryBot.create :project_folder, project_id: project.id
    folder.add_assets(sop)
    child = folder.add_child('fred')
    child.save!
    unsorted_folder = FactoryBot.create :project_folder, project_id: project.id, incoming: true

    assert_no_difference('ProjectFolder.count') do
      delete :destroy, params: { id: folder, project_id: project.id }
    end

    assert_redirected_to :root
    unsorted_folder.reload
    project.reload
    assert_equal [folder, child, unsorted_folder], ProjectFolder.where(project_id: project.id).to_a.sort_by(&:id)
    assert_equal [], unsorted_folder.assets
    assert_equal [sop], folder.assets
  end

  test 'defaults created and old items assigned' do
    sop = FactoryBot.create :sop, project_ids: [@project.id], policy: FactoryBot.create(:public_policy)
    private_sop = FactoryBot.create :sop, project_ids: [@project.id], policy: FactoryBot.create(:private_policy)
    sop2 = FactoryBot.create :sop, project_ids: [FactoryBot.create(:project).id], policy: FactoryBot.create(:public_policy)
    assert ProjectFolder.root_folders(@project).empty?

    assert_difference('ProjectFolderAsset.count', 2) do
      get :index, params: { project_id: @project.id }
    end
    assert_response :success
    @project.reload
    refute ProjectFolder.root_folders(@project).empty?
    assert_equal 2, ProjectFolder.new_items_folder(@project).assets.count
    assert ProjectFolder.new_items_folder(@project).assets.include?(sop)
    assert ProjectFolder.new_items_folder(@project).assets.include?(private_sop)
    refute ProjectFolder.new_items_folder(@project).assets.include?(sop2)
  end

  test 'defaults not created if exist' do
    folder = FactoryBot.create :project_folder, project: @project
    assert_equal 1, ProjectFolder.root_folders(@project).count
    assert_no_difference('ProjectFolder.count') do
      get :index, params: { project_id: @project.id }
    end
    assert_response :success
    assert_equal [folder], ProjectFolder.root_folders(@project)
  end

  test 'blocked access as non member' do
    login_as(FactoryBot.create(:user))
    get :index, params: { project_id: @project.id }
    assert_redirected_to root_path
    assert_not_nil flash[:error]
  end

  test 'should not show when logged out' do
    logout
    get :index, params: { project_id: @project.id }
    assert_redirected_to login_path
  end

  test 'ajax request for folder contents' do
    sop = FactoryBot.create :sop, project_ids: [@project.id], policy: FactoryBot.create(:public_policy), description: 'Ryz9z3Z9h70wzJ243we6k8RO5xI5f3UF'
    folder = FactoryBot.create :project_folder, project_id: @project.id
    folder.add_assets(sop)
    folder.save!

    get :display_contents, xhr: true, params: { id: folder.id, project_id: folder.project.id }

    assert_response :success

    assert @response.body.match(/Description.*Ryz9z3Z9h70wzJ243we6k8RO5xI5f3UF/)
  end

  test 'ajax request for assay folder contents' do
    assay = FactoryBot.create :experimental_assay, contributor: @member.person, policy: FactoryBot.create(:public_policy), title: 'Yp50U6BjlacF0r7HY5WXHEOP8E2UqXcv', description: '5Kx0432X6IbuzBi25BIi0OdY1xo4FRG3'
    assay.study.investigation.projects = [@project]
    assay.study.investigation.save!
    assert assay.can_view?
    get :display_contents, xhr: true, params: { id: "Assay_#{assay.id}", project_id: @project.id }
    assert_response :success
    assert @response.body.match(/Yp50U6BjlacF0r7HY5WXHEOP8E2UqXcv/)
    assert @response.body.match(/5Kx0432X6IbuzBi25BIi0OdY1xo4FRG3/)
  end

  test 'ajax request for hidden assay folder contents fails' do
    person = FactoryBot.create(:person)
    inv = FactoryBot.create(:investigation, contributor: person)
    study = FactoryBot.create(:study, investigation: inv, contributor: person)
    assay = FactoryBot.create(:experimental_assay, policy: FactoryBot.create(:private_policy),
                                         title: 'Yp50U6BjlacF0r7HY5WXHEOP8E2UqXcv', description: '5Kx0432X6IbuzBi25BIi0OdY1xo4FRG3',
                                         study: study, contributor: person)

    refute assay.can_view?
    get :display_contents, xhr: true, params: { id: "Assay_#{assay.id}", project_id: @project.id }
    assert_redirected_to root_path
    refute @response.body.match(/Yp50U6BjlacF0r7HY5WXHEOP8E2UqXcv/)
    refute @response.body.match(/5Kx0432X6IbuzBi25BIi0OdY1xo4FRG3/)
  end

  test 'ajax request for folder contents rejected from non project member' do
    login_as FactoryBot.create(:user)
    sop = FactoryBot.create :sop, project_ids: [@project.id], policy: FactoryBot.create(:public_policy), description: 'Ryz9z3Z9h70wzJ243we6k8RO5xI5f3UF'
    folder = FactoryBot.create :project_folder, project_id: @project.id
    folder.add_assets(sop)
    folder.save!

    get :display_contents, xhr: true, params: { id: folder.id, project_id: folder.project.id }
    assert_redirected_to root_path
    assert @response.body.match(/Description.*Ryz9z3Z9h70wzJ243we6k8RO5xI5f3UF/).nil?
  end

  test 'move between folders' do
    sop = FactoryBot.create :sop, project_ids: [@project.id], policy: FactoryBot.create(:public_policy), description: 'Ryz9z3Z9h70wzJ243we6k8RO5xI5f3UF'
    folder = FactoryBot.create :project_folder, project_id: @project.id
    other_folder = FactoryBot.create :project_folder, project_id: @project.id
    folder.add_assets(sop)
    folder.save!
    post :move_asset_to, xhr: true, params: { asset_id: sop.id, asset_type: 'Sop', id: folder.id, dest_folder_id: other_folder.id, project_id: folder.project.id }
    assert_response :success
    sop.reload
    other_folder.reload
    folder.reload
    assert_equal [other_folder], sop.folders
    assert_equal [], folder.assets
    assert_equal [sop], other_folder.assets
  end

  test 'move asset to assay' do
    assay = FactoryBot.create :experimental_assay, contributor: @member.person, policy: FactoryBot.create(:public_policy)
    assay.study.investigation.projects = [@project]
    assay.study.investigation.save!
    sop = FactoryBot.create :sop, project_ids: [@project.id], policy: FactoryBot.create(:public_policy)
    folder = FactoryBot.create :project_folder, project_id: @project.id
    folder.add_assets(sop)
    folder.save!

    assert_difference('AssayAsset.count') do
      post :move_asset_to, xhr: true, params: { asset_id: sop.id,
                                                asset_type: 'Sop',
                                                id: folder.id,
                                                dest_folder_id: "Assay_#{assay.id}",
                                                project_id: folder.project.id,
                                                orig_folder_element_id: 'sdfhsdk',
                                                dest_folder_element_id: 'oosdo' }
    end
    assert_response :success
    assay.reload
    assert_equal [sop], assay.assets
    assert_equal [sop], folder.assets
  end

  test 'remove asset from assay' do
    assay = FactoryBot.create :experimental_assay, contributor: @member.person, policy: FactoryBot.create(:public_policy)
    assay.study.investigation.projects = [@project]
    assay.study.investigation.save!
    sop = FactoryBot.create :sop, project_ids: [@project.id], policy: FactoryBot.create(:public_policy)
    assay.associate(sop)
    folder = Seek::AssayFolder.new assay, @project
    assert_difference('AssayAsset.count', -1) do
      post :remove_asset, xhr: true, params: { asset_id: sop.id, asset_type: 'Sop', id: folder.id, project_id: folder.project.id, orig_folder_element_id: 'sdfhsdk' }
    end

    assay.reload
    assert_equal [], assay.assets
    assert_equal [], folder.assets
  end

  test 'cannot move to other project folder' do
    sop = FactoryBot.create :sop, project_ids: [@project.id], policy: FactoryBot.create(:public_policy), description: 'Ryz9z3Z9h70wzJ243we6k8RO5xI5f3UF'
    folder = FactoryBot.create :project_folder, project_id: @project.id
    other_folder = FactoryBot.create :project_folder, project_id: FactoryBot.create(:project).id
    folder.add_assets(sop)
    folder.save!
    post :move_asset_to, xhr: true, params: { asset_id: sop.id, asset_type: 'Sop', id: folder.id, dest_folder_id: other_folder.id, project_id: folder.project.id }
    assert_response :success
    sop.reload
    other_folder.reload
    folder.reload
    assert_equal [folder], sop.folders
    assert_equal [], other_folder.assets
    assert_equal [sop], folder.assets
  end

  test 'create a new child folder' do
    folder = FactoryBot.create :project_folder, project: @project
    assert_difference('ProjectFolder.count') do
      post :create_folder, xhr: true, params: { project_id: @project.id, id: folder.id, title: 'fred' }
    end
    assert_response :success
  end

  test 'authorization on assets' do
    sop = FactoryBot.create :sop, project_ids: [@project.id], policy: FactoryBot.create(:public_policy), description: 'Ryz9z3Z9h70wzJ243we6k8RO5xI5f3UF'
    hidden_sop = FactoryBot.create :sop, project_ids: [@project.id], policy: FactoryBot.create(:private_policy), description: 'viu2q6ng3iZ0ppS5X679pPo11LfF62pS'
    folder = FactoryBot.create :project_folder, project_id: @project.id

    disable_authorization_checks do
      folder.add_assets([sop, hidden_sop])
      folder.save!
    end

    get :display_contents, xhr: true, params: { id: folder.id, project_id: folder.project.id }

    assert_response :success
    assert @response.body.match(/Ryz9z3Z9h70wzJ243we6k8RO5xI5f3UF/)
    assert @response.body.match(/viu2q6ng3iZ0ppS5X679pPo11LfF62pS/).nil?
  end

  test 'display with assays' do
    assay = FactoryBot.create :experimental_assay, contributor: @member.person, policy: FactoryBot.create(:public_policy)
    assay.study.investigation.projects = [@project]
    assay.study.investigation.save!
    get :index, params: { project_id: @project.id }
    assert_response :success
  end
end
