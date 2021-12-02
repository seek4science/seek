require 'test_helper'

class GitControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  def setup
    @git_version = Factory(:git_version)
    @workflow = @git_version.resource
    @person = @workflow.contributor
    login_as @person
  end

  test 'add file' do
    refute @git_version.file_exists?('new-file.txt')

    post :add_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                              file: { path: 'new-file.txt',
                                      data: fixture_file_upload('files/little_file.txt') } }

    assert_redirected_to workflow_path(@workflow, anchor: 'files')
    assert assigns(:git_version).file_exists?('new-file.txt')
    assert_equal 'little file', assigns(:git_version).file_contents('new-file.txt')
  end

  test 'add file via path param' do
    refute @git_version.file_exists?('new-file.txt')

    post :add_file, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'new-file.txt',
                              file: { data: fixture_file_upload('files/little_file.txt') } }

    assert_redirected_to workflow_path(@workflow, anchor: 'files')
    assert assigns(:git_version).file_exists?('new-file.txt')
    assert_equal 'little file', assigns(:git_version).file_contents('new-file.txt')
  end

  test 'adding file with no paths defaults to filename' do
    refute @git_version.file_exists?('little_file.txt')

    post :add_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                              file: { path: '',
                                      data: fixture_file_upload('files/little_file.txt') } }

    assert_redirected_to workflow_path(@workflow, anchor: 'files')
    assert assigns(:git_version).file_exists?('little_file.txt')
    assert_equal 'little file', assigns(:git_version).file_contents('little_file.txt')
  end

  test 'cannot add file if not authorized' do
    logout
    refute @git_version.file_exists?('new-file.txt')

    post :add_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                              file: { path: 'new-file.txt',
                                      data: fixture_file_upload('files/little_file.txt') } }

    assert_redirected_to root_path
    assert flash[:error].include?('authorized')
    refute @git_version.reload.file_exists?('new-file.txt')
  end

  test 'cannot add file if immutable' do
    @git_version.update_column(:mutable, false)
    refute @git_version.file_exists?('new-file.txt')

    post :add_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                              file: { path: 'new-file.txt',
                                      data: fixture_file_upload('files/little_file.txt') } }

    assert_redirected_to workflow_path(@workflow, anchor: 'files')
    assert flash[:error].include?('cannot make changes')
    refute assigns(:git_version).file_exists?('new-file.txt')
  end

  test 'move file' do
    assert @git_version.file_exists?('diagram.png')
    refute @git_version.file_exists?('cool-pic.png')

    patch :move_file, format: :html, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'diagram.png',
                                      file: { new_path: 'cool-pic.png' } }

    assert_redirected_to workflow_path(@workflow, anchor: 'files')
    refute assigns(:git_version).file_exists?('diagram.png')
    assert assigns(:git_version).file_exists?('cool-pic.png')
  end

  test 'move file into directory' do
    assert @git_version.file_exists?('diagram.png')
    refute @git_version.file_exists?('mydir/cool-pic.png')

    patch :move_file, format: :html, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'diagram.png',
                                      file: { new_path: 'mydir/cool-pic.png' } }

    assert_redirected_to workflow_path(@workflow, anchor: 'files')
    refute assigns(:git_version).file_exists?('diagram.png')
    assert assigns(:git_version).file_exists?('mydir/cool-pic.png')
  end

  test 'error when moving non-existent path' do
    patch :move_file, format: :html, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'doesnotexist.png',
                                      file: { new_path: 'mydir/cool-pic.png' } }

    assert flash[:error].include?("Couldn't find path: doesnotexist.png")
    refute assigns(:git_version).file_exists?('mydir/cool-pic.png')
  end

  test 'cannot move file if no permissions' do
    logout
    assert @git_version.file_exists?('diagram.png')
    refute @git_version.file_exists?('cool-pic.png')

    patch :move_file, format: :html, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'diagram.png',
                                      file: {  new_path: 'cool-pic.png' } }

    assert_redirected_to root_path
    assert flash[:error].include?('authorized')
    assert @git_version.reload.file_exists?('diagram.png')
    refute @git_version.reload.file_exists?('cool-pic.png')
  end

  test 'cannot move file if immutable' do
    @git_version.update_column(:mutable, false)
    assert @git_version.file_exists?('diagram.png')
    refute @git_version.file_exists?('cool-pic.png')

    patch :move_file, format: :html, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'diagram.png',
                                      file: { new_path: 'cool-pic.png' } }

    assert_redirected_to workflow_path(@workflow, anchor: 'files')
    assert flash[:error].include?('cannot make changes')
    assert assigns(:git_version).file_exists?('diagram.png')
    refute assigns(:git_version).file_exists?('cool-pic.png')
  end

  test 'remove file' do
    assert @git_version.file_exists?('diagram.png')

    delete :remove_file, format: :html, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'diagram.png' }

    assert_redirected_to workflow_path(@workflow, anchor: 'files')
    refute assigns(:git_version).file_exists?('diagram.png')
  end

  test 'error when removing non-existent path' do
    refute @git_version.file_exists?('doesnotexist.png')

    delete :remove_file, format: :html, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'doesnotexist.png' }

    assert flash[:error].include?("Couldn't find path: doesnotexist.png")
    refute assigns(:git_version).file_exists?('doesnotexist.png')
  end

  test 'cannot remove file if no permissions' do
    logout
    assert @git_version.file_exists?('diagram.png')

    delete :remove_file, format: :html, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'diagram.png' }

    assert_redirected_to root_path
    assert flash[:error].include?('authorized')
    assert @git_version.reload.file_exists?('diagram.png')
  end

  test 'cannot remove file if immutable' do
    @git_version.update_column(:mutable, false)
    assert @git_version.file_exists?('diagram.png')

    delete :remove_file, format: :html, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'diagram.png' }

    assert_redirected_to workflow_path(@workflow, anchor: 'files')
    assert flash[:error].include?('cannot make changes')
  end

  test 'get text file blob' do
    get :blob, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'concat_two_files.ga' }

    assert_response :success
    assert_select 'a.btn[href=?]', workflow_git_remove_file_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga')
  end

  test 'get raw text file' do
    get :raw, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'concat_two_files.ga' }

    assert_response :success
    assert @response.body.include?('galaxy_workflow')
    assert response.headers['Content-Type'].include?('text/plain')
  end

  test 'download text file' do
    get :download, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'concat_two_files.ga' }

    assert_response :success
    assert @response.header['Content-Disposition'].include?('attachment')
  end

  test 'get binary file blob' do
    get :blob, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'diagram.png', format: 'html' } # Not sure why this is needed

    assert_response :success
    assert_select 'a.btn[href=?]', workflow_git_remove_file_path(@workflow, version: @git_version.version, path: 'diagram.png')
    assert_select 'img.git-image-preview[src=?]', workflow_git_raw_path(@workflow, version: @git_version.version, path: 'diagram.png')
  end

  test 'get raw binary file' do
    get :raw, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'diagram.png' }

    assert_response :success
    assert response.headers['Content-Type'].include?('image/png')
  end

  test 'download binary file' do
    get :download, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'diagram.png' }

    assert_response :success
    assert @response.header['Content-Disposition'].include?('attachment')
  end

  test 'getting non-existent blob throws error' do
    get :blob, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'doesnotexist' }

    assert flash[:error].include?("Couldn't find path: doesnotexist")
  end

  test 'getting non-existent raw throws error' do
    get :raw, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'doesnotexist' }

    assert flash[:error].include?("Couldn't find path: doesnotexist")
  end

  test 'non-existent download throws error' do
    get :download, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'doesnotexist' }, format: :html

    assert flash[:error].include?("Couldn't find path: doesnotexist")
  end

  test 'getting blob with no permissions throws error' do
    logout
    get :blob, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'diagram.png' }, format: :html

    assert flash[:error].include?('authorized')
  end

  test 'getting raw with no permissions throws error' do
    logout
    get :raw, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'diagram.png' }, format: :html

    assert flash[:error].include?('authorized')
  end

  test 'download with no permissions throws error' do
    logout
    get :download, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'diagram.png' }, format: :html

    assert flash[:error].include?('authorized')
  end

  test 'show appropriate buttons for permissions' do
    viewer = Factory(:person)
    downloader = Factory(:person)
    editor = Factory(:person)
    manager = Factory(:person)
    @workflow.policy.permissions.create!(contributor: viewer, access_type: Policy::VISIBLE)
    @workflow.policy.permissions.create!(contributor: downloader, access_type: Policy::ACCESSIBLE)
    @workflow.policy.permissions.create!(contributor: editor, access_type: Policy::EDITING)
    @workflow.policy.permissions.create!(contributor: manager, access_type: Policy::MANAGING)

    # VIEW
    login_as(viewer)

    get :blob, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'concat_two_files.ga' }

    assert flash[:error].include?('authorized')
    assert_select 'a.btn[href=?]', workflow_git_raw_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga'), count: 0
    assert_select 'a.btn[href=?]', workflow_git_download_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga'), count: 0
    assert_select "a.btn[data-target='#git-move-modal']", count: 0
    assert_select 'a.btn[href=?]', workflow_git_remove_file_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga'), count: 0

    # DOWNLOAD
    login_as(downloader)

    get :blob, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'concat_two_files.ga' }

    assert_response :success
    assert_select 'a.btn[href=?]', workflow_git_raw_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga'), count: 1
    assert_select 'a.btn[href=?]', workflow_git_download_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga'), count: 1
    assert_select "a.btn[data-target='#git-move-modal']", count: 0
    assert_select 'a.btn[href=?]', workflow_git_remove_file_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga'), count: 0

    # EDIT
    login_as(editor)

    get :blob, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'concat_two_files.ga' }

    assert_response :success
    assert_select 'a.btn[href=?]', workflow_git_raw_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga'), count: 1
    assert_select 'a.btn[href=?]', workflow_git_download_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga'), count: 1
    assert_select "a.btn[data-target='#git-move-modal']", count: 1
    assert_select 'a.btn[href=?]', workflow_git_remove_file_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga'), count: 1

    # MANAGE
    login_as(manager)

    get :blob, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'concat_two_files.ga' }

    assert_response :success
    assert_select 'a.btn[href=?]', workflow_git_raw_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga'), count: 1
    assert_select 'a.btn[href=?]', workflow_git_download_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga'), count: 1
    assert_select "a.btn[data-target='#git-move-modal']", count: 1
    assert_select 'a.btn[href=?]', workflow_git_remove_file_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga'), count: 1
  end

  test 'disables move and delete buttons if immutable' do
    @git_version.update_column(:mutable, false)

    get :blob, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'concat_two_files.ga' }

    assert_response :success
    assert_select 'a.btn[href=?]', workflow_git_raw_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga'), count: 1
    assert_select 'a.btn[href=?]', workflow_git_download_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga'), count: 1
    assert_select "a.btn[data-target='#git-move-modal']", count: 0
    assert_select 'a.btn[href=?]', workflow_git_remove_file_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga'), count: 0
    assert_select "a.btn.disabled", text: 'Move/rename', count: 1
    assert_select "a.btn.disabled", text: 'Delete', count: 1
  end

  test 'browse tree' do
    get :tree, params: { workflow_id: @workflow.id, version: @git_version.version }

    assert_response :success
    assert_select 'ul.pending-files li', count: @git_version.blobs.count
  end

  test 'cannot browse tree with no permissions' do
    logout
    get :tree, params: { workflow_id: @workflow.id, version: @git_version.version }

    assert flash[:error].include?('authorized')
  end

  test 'adding file with invalid path throws exception' do
    refute @git_version.file_exists?('/////')
    commit = @git_version.commit

    post :add_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                              file: { path: '/////',
                                      data: fixture_file_upload('files/little_file.txt') } }

    assert_redirected_to workflow_path(@workflow, anchor: 'files')
    refute assigns(:git_version).file_exists?('/////')
    assert_equal 'Invalid path: /////', flash[:error]
    assert_equal commit, assigns(:git_version).commit
  end

  test 'add remote file' do
    refute @git_version.file_exists?('new-file.txt')

    assert_no_enqueued_jobs(only: RemoteGitContentFetchingJob) do
      post :add_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                                file: { path: 'new-file.txt',
                                        url: 'https://internets.com/files/new.txt' } }
    end

    assert_redirected_to workflow_path(@workflow, anchor: 'files')
    assert assigns(:git_version).file_exists?('new-file.txt')
    assert_equal '', assigns(:git_version).file_contents('new-file.txt')
  end

  test 'do not add remote file with bad URL' do
    refute @git_version.file_exists?('new-file.txt')

    assert_no_enqueued_jobs(only: RemoteGitContentFetchingJob) do
      post :add_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                                file: { path: 'new-file.txt',
                                        url: '😂' } }
    end

    assert_redirected_to workflow_path(@workflow, anchor: 'files')
    assert_equal 'URL (😂) must be a valid, accessible remote URL', flash[:error]
    refute assigns(:git_version).file_exists?('new-file.txt')
  end

  test 'add and fetch remote file' do
    refute @git_version.file_exists?('new-file.txt')

    assert_enqueued_jobs(1, only: RemoteGitContentFetchingJob) do
      post :add_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                                file: { path: 'new-file.txt',
                                        url: 'https://internets.com/files/new.txt',
                                        fetch: '1' } }
    end

    assert_redirected_to workflow_path(@workflow, anchor: 'files')
    assert assigns(:git_version).file_exists?('new-file.txt')
    assert_equal '', assigns(:git_version).file_contents('new-file.txt')
  end

  test 'view a blob as json' do
    workflow = Factory(:local_git_workflow, policy: Factory(:public_policy))
    get :blob, params: { workflow_id: workflow, version: 1, path: 'concat_two_files.ga' }, format: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_equal 'concat_two_files.ga', data['path']
    assert_equal 4813, data['size']
    assert_equal false, data['binary']
  end

  test 'view a binary blob as json' do
    workflow = Factory(:local_git_workflow, policy: Factory(:public_policy))
    get :blob, params: { workflow_id: workflow, version: 1, path: 'diagram.png' }, format: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_equal 'diagram.png', data['path']
    assert_equal 32248, data['size']
    assert_equal true, data['binary']
  end

  test 'view missing blob as json' do
    workflow = Factory(:local_git_workflow, policy: Factory(:public_policy))
    get :blob, params: { workflow_id: workflow, version: 1, path: 'doesnotexist' }, format: :json

    assert_response :not_found
    data = JSON.parse(response.body)
    assert_equal "Couldn't find path: doesnotexist", data['error']
  end

  test 'cannot view a blob as json if no permission' do
    workflow = Factory(:local_git_workflow)
    get :blob, params: { workflow_id: workflow, version: 1, path: 'concat_two_files.ga' }, format: :json

    assert_response :forbidden
    data = JSON.parse(response.body)
    assert_equal 'Not authorized', data['error']
  end

  test 'view root tree as json' do
    workflow = Factory(:ro_crate_git_workflow, policy: Factory(:public_policy))
    get :tree, params: { workflow_id: workflow, version: 1 }, format: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_equal '/', data['path']
    assert_equal 5, data['tree'].length
    assert_includes data['tree'].map { |e| e['name'] }, 'README.md'
    assert_equal 'blob', data['tree'].detect { |n| n['name'] == 'README.md' }['type']
    assert_equal 'tree', data['tree'].detect { |n| n['name'] == 'test' }['type']
  end

  test 'view a subtree as json' do
    workflow = Factory(:ro_crate_git_workflow, policy: Factory(:public_policy))
    get :tree, params: { workflow_id: workflow, version: 1, path: 'test/test1' }, format: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_equal 'test/test1', data['path']
    assert_equal 3, data['tree'].length
    assert_includes data['tree'].map { |e| e['name'] }, 'input.bed'
  end

  test 'view missing tree as json' do
    workflow = Factory(:ro_crate_git_workflow, policy: Factory(:public_policy))
    get :tree, params: { workflow_id: workflow, version: 1, path: 'test/test47' }, format: :json

    assert_response :not_found
    data = JSON.parse(response.body)
    assert_equal "Couldn't find path: test/test47", data['error']
  end

  test 'cannot view a tree as json if no permission' do
    workflow = Factory(:ro_crate_git_workflow)
    get :blob, params: { workflow_id: workflow, version: 1, path: 'test/test1' }, format: :json

    assert_response :forbidden
    data = JSON.parse(response.body)
    assert_equal 'Not authorized', data['error']
  end

  # post 'blob(/*path)' =>'git#add_file', as: :git_add_file
  # delete 'blob/*path' => 'git#remove_file', as: :git_remove_file
  # patch 'blob/*path' => 'git#move_file', as: :git_move_file

  test 'add a new file via API' do
    workflow = Factory(:local_git_workflow, policy: Factory(:public_policy))
    refute workflow.git_version.file_exists?('new_file.txt')

    post :add_file, params: { workflow_id: workflow, version: 1, path: 'new_file.txt', file: { content: Base64.encode64('file contents') } }, format: :json

    assert_response :created
    assert workflow.git_version.file_exists?('new_file.txt')
  end

  test 'add a new remote file via API' do
    workflow = Factory(:local_git_workflow, policy: Factory(:public_policy))
    refute workflow.git_version.file_exists?('new_remote_file.txt')

    assert_difference('Git::Annotation.count', 1) do
      post :add_file, params: { workflow_id: workflow, version: 1, path: 'new_remote_file.txt', file: { url: 'http://example.com' } }, format: :json
    end

    assert_response :created
    assert workflow.git_version.file_exists?('new_remote_file.txt')
    assert_equal 'http://example.com', workflow.git_version.remote_sources['new_remote_file.txt']
  end

  test 'cannot add a new file via API if not authorized' do
    workflow = Factory(:local_git_workflow)
    refute workflow.git_version.file_exists?('new_file.txt')

    post :add_file, params: { workflow_id: workflow, version: 1, path: 'new_file.txt', file: { content: Base64.encode64('file contents') } }, format: :json

    assert_response :forbidden
    refute workflow.git_version.file_exists?('new_file.txt')
  end

  test 'update an existing file via API' do
    workflow = Factory(:local_git_workflow, policy: Factory(:public_policy))
    refute_equal 'file contents', workflow.git_version.file_contents('concat_two_files.ga')

    post :add_file, params: { workflow_id: workflow, version: 1, path: 'concat_two_files.ga', file: { content: Base64.encode64('file contents') } }, format: :json

    assert_response :created
    assert_equal 'file contents', workflow.git_version.file_contents('concat_two_files.ga')
  end

  test 'rename a file via API' do
    workflow = Factory(:local_git_workflow, policy: Factory(:public_policy))
    refute workflow.git_version.file_exists?('concat_2_files.ga')
    assert_equal 'concat_two_files.ga', workflow.git_version.main_workflow_path

    post :move_file, params: { workflow_id: workflow, version: 1, path: 'concat_two_files.ga', file: { new_path: 'concat_2_files.ga' } }, format: :json

    assert_response :success
    assert_equal 'concat_2_files.ga', workflow.git_version.main_workflow_path
    assert workflow.git_version.file_exists?('concat_2_files.ga')
  end

  test 'cannot rename a file via API if not authorized' do
    workflow = Factory(:local_git_workflow)
    assert workflow.git_version.file_exists?('concat_two_files.ga')
    assert_equal 'concat_two_files.ga', workflow.git_version.main_workflow_path

    post :move_file, params: { workflow_id: workflow, version: 1, path: 'concat_two_files.ga', file: { new_path: 'concat_2_files.ga' } }, format: :json

    assert_response :forbidden
    assert workflow.git_version.file_exists?('concat_two_files.ga')
    assert_equal 'concat_two_files.ga', workflow.git_version.main_workflow_path
  end

  test 'trying to rename a file via API with invalid path throws error' do
    workflow = Factory(:local_git_workflow, policy: Factory(:public_policy))
    assert workflow.git_version.file_exists?('concat_two_files.ga')
    assert_equal 'concat_two_files.ga', workflow.git_version.main_workflow_path

    post :move_file, params: { workflow_id: workflow, version: 1, path: 'concat_two_files.ga', file: { new_path: '////////////' } }, format: :json

    assert_response :unprocessable_entity
    assert workflow.git_version.file_exists?('concat_two_files.ga')
    assert_equal 'concat_two_files.ga', workflow.git_version.main_workflow_path
  end

  test 'remove a file via API' do
    workflow = Factory(:local_git_workflow, policy: Factory(:public_policy))
    assert workflow.git_version.file_exists?('diagram.png')

    delete :remove_file, params: { workflow_id: workflow, version: 1, path: 'diagram.png' }, format: :json

    assert_response :success
    refute workflow.git_version.file_exists?('diagram.png')
  end

  test 'cannot remove a file via API if not authorized' do
    workflow = Factory(:local_git_workflow)
    assert workflow.git_version.file_exists?('diagram.png')

    delete :remove_file, params: { workflow_id: workflow, version: 1, path: 'diagram.png' }, format: :json

    assert_response :forbidden
    assert workflow.git_version.file_exists?('diagram.png')
  end

  test 'trying to remove a file via API with wrong path throws error' do
    workflow = Factory(:local_git_workflow, policy: Factory(:public_policy))

    delete :remove_file, params: { workflow_id: workflow, version: 1, path: '../../../../home' }, format: :json

    assert_response :not_found
  end
end
