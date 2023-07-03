require 'test_helper'

class GitControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  def setup
    @git_version = FactoryBot.create(:git_version).becomes(Workflow::Git::Version)
    @workflow = @git_version.resource
    @person = @workflow.contributor
    login_as @person
  end

  test 'add file' do
    refute @git_version.file_exists?('new-file.txt')

    post :add_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                              file: { path: 'new-file.txt',
                                      data: fixture_file_upload('little_file.txt') } }

    assert_redirected_to workflow_path(@workflow, tab: 'files')
    assert assigns(:git_version).file_exists?('new-file.txt')
    assert_equal 'little file', assigns(:git_version).file_contents('new-file.txt')
  end

  test 'add file via path param' do
    refute @git_version.file_exists?('new-file.txt')

    post :add_file, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'new-file.txt',
                              file: { data: fixture_file_upload('little_file.txt') } }

    assert_redirected_to workflow_path(@workflow, tab: 'files')
    assert assigns(:git_version).file_exists?('new-file.txt')
    assert_equal 'little file', assigns(:git_version).file_contents('new-file.txt')
  end

  test 'adding file with no paths defaults to filename' do
    refute @git_version.file_exists?('little_file.txt')

    post :add_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                              file: { path: '',
                                      data: fixture_file_upload('little_file.txt') } }

    assert_redirected_to workflow_path(@workflow, tab: 'files')
    assert assigns(:git_version).file_exists?('little_file.txt')
    assert_equal 'little file', assigns(:git_version).file_contents('little_file.txt')
  end

  test 'cannot add file if not authorized' do
    logout
    refute @git_version.file_exists?('new-file.txt')

    post :add_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                              file: { path: 'new-file.txt',
                                      data: fixture_file_upload('little_file.txt') } }

    assert_redirected_to root_path
    assert flash[:error].include?('authorized')
    refute @git_version.reload.file_exists?('new-file.txt')
  end

  test 'cannot add file if immutable' do
    @git_version.update_column(:mutable, false)
    refute @git_version.file_exists?('new-file.txt')

    post :add_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                              file: { path: 'new-file.txt',
                                      data: fixture_file_upload('little_file.txt') } }

    assert_redirected_to workflow_path(@workflow, tab: 'files')
    assert flash[:error].include?('cannot make changes')
    refute assigns(:git_version).file_exists?('new-file.txt')
  end

  test 'move file' do
    assert @git_version.file_exists?('diagram.png')
    refute @git_version.file_exists?('cool-pic.png')

    patch :move_file, format: :html, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'diagram.png',
                                      file: { new_path: 'cool-pic.png' } }

    assert_redirected_to workflow_path(@workflow, tab: 'files')
    refute assigns(:git_version).file_exists?('diagram.png')
    assert assigns(:git_version).file_exists?('cool-pic.png')
  end

  test 'move file into directory' do
    assert @git_version.file_exists?('diagram.png')
    refute @git_version.file_exists?('mydir/cool-pic.png')

    patch :move_file, format: :html, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'diagram.png',
                                      file: { new_path: 'mydir/cool-pic.png' } }

    assert_redirected_to workflow_path(@workflow, tab: 'files')
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

    assert_redirected_to workflow_path(@workflow, tab: 'files')
    assert flash[:error].include?('cannot make changes')
    assert assigns(:git_version).file_exists?('diagram.png')
    refute assigns(:git_version).file_exists?('cool-pic.png')
  end

  test 'remove file' do
    assert @git_version.file_exists?('diagram.png')

    delete :remove_file, format: :html, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'diagram.png' }

    assert_redirected_to workflow_path(@workflow, tab: 'files')
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

    assert_redirected_to workflow_path(@workflow, tab: 'files')
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
    workflow = FactoryBot.create(:local_git_workflow, policy: FactoryBot.create(:publicly_viewable_policy))
    get :blob, params: { workflow_id: workflow.id, version: 1, path: 'diagram.png' }, format: :html

    assert_redirected_to workflow
    assert flash[:error].include?('authorized')
  end

  test 'getting raw with no permissions throws error' do
    workflow = FactoryBot.create(:local_git_workflow, policy: FactoryBot.create(:publicly_viewable_policy))
    get :raw, params: { workflow_id: workflow.id, version: 1, path: 'diagram.png' }, format: :html

    assert_redirected_to workflow
    assert flash[:error].include?('authorized')
  end

  test 'download with no permissions throws error' do
    workflow = FactoryBot.create(:local_git_workflow, policy: FactoryBot.create(:publicly_viewable_policy))
    get :download, params: { workflow_id: workflow.id, version: 1, path: 'diagram.png' }, format: :html

    assert_redirected_to workflow
    assert flash[:error].include?('authorized')
  end

  test 'show appropriate buttons for permissions' do
    viewer = FactoryBot.create(:person)
    downloader = FactoryBot.create(:person)
    editor = FactoryBot.create(:person)
    manager = FactoryBot.create(:person)
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
    workflow = FactoryBot.create(:local_git_workflow, policy: FactoryBot.create(:publicly_viewable_policy))
    get :tree, params: { workflow_id: workflow.id, version: 1 }

    assert_redirected_to workflow
    assert flash[:error].include?('authorized')
  end

  test 'redirects to root if no permission to view' do
    workflow = FactoryBot.create(:local_git_workflow, policy: FactoryBot.create(:private_policy))
    get :tree, params: { workflow_id: workflow.id, version: 1 }

    assert_redirected_to root_path
    assert flash[:error].include?('authorized')
  end

  test 'adding file with invalid path throws exception' do
    refute @git_version.file_exists?('/////')
    commit = @git_version.commit

    post :add_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                              file: { path: '/////',
                                      data: fixture_file_upload('little_file.txt') } }

    assert_redirected_to workflow_path(@workflow, tab: 'files')
    refute assigns(:git_version).file_exists?('/////')
    assert_equal 'Invalid path: /////', flash[:error]
    assert_equal commit, assigns(:git_version).commit
  end

  test 'add remote file' do
    refute @git_version.file_exists?('new-file.txt')

    assert_no_enqueued_jobs(only: RemoteGitContentFetchingJob) do
      post :add_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                                file: { path: 'new-file.txt',
                                        url: 'https://example.com/files/new.txt' } }
    end

    assert_redirected_to workflow_path(@workflow, tab: 'files')
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

    assert_redirected_to workflow_path(@workflow, tab: 'files')
    assert_equal 'URL (😂) must be a valid, accessible remote URL', flash[:error]
    refute assigns(:git_version).file_exists?('new-file.txt')
  end

  test 'add and fetch remote file' do
    refute @git_version.file_exists?('new-file.txt')

    assert_enqueued_jobs(1, only: RemoteGitContentFetchingJob) do
      post :add_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                                file: { path: 'new-file.txt',
                                        url: 'https://example.com/files/new.txt',
                                        fetch: '1' } }
    end

    assert_redirected_to workflow_path(@workflow, tab: 'files')
    assert assigns(:git_version).file_exists?('new-file.txt')
    assert_equal '', assigns(:git_version).file_contents('new-file.txt')
  end

  test 'replace existing remote file' do
    refute @git_version.file_exists?('file.txt')

    assert_enqueued_jobs(1, only: RemoteGitContentFetchingJob) do
      assert_difference('Git::Annotation.count', 1) do
        post :add_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                                  file: { path: 'file.txt',
                                          url: 'https://example.com/files/old.txt',
                                          fetch: '1' } }
      end
    end

    assert_redirected_to workflow_path(@workflow, tab: 'files')
    assert assigns(:git_version).file_exists?('file.txt')
    assert_equal '', assigns(:git_version).file_contents('file.txt')
    assert_equal 'https://example.com/files/old.txt', assigns(:git_version).remote_sources['file.txt']

    assert_enqueued_jobs(1, only: RemoteGitContentFetchingJob) do
      assert_no_difference('Git::Annotation.count') do
        post :add_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                                  file: { path: 'file.txt',
                                          url: 'https://example.com/files/new.txt',
                                          fetch: '1' } }
      end
    end

    assert_redirected_to workflow_path(@workflow, tab: 'files')
    assert assigns(:git_version).file_exists?('file.txt')
    assert_equal '', assigns(:git_version).file_contents('file.txt')
    assert_equal 'https://example.com/files/new.txt', assigns(:git_version).remote_sources['file.txt']

    assert_equal 1, assigns(:git_version).git_annotations.count
  end

  test 'view a blob as json' do
    workflow = FactoryBot.create(:local_git_workflow, policy: FactoryBot.create(:public_policy))
    get :blob, params: { workflow_id: workflow, version: 1, path: 'concat_two_files.ga' }, format: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_equal 'concat_two_files.ga', data['path']
    assert_equal 4813, data['size']
    assert_equal false, data['binary']
  end

  test 'view a binary blob as json' do
    workflow = FactoryBot.create(:local_git_workflow, policy: FactoryBot.create(:public_policy))
    get :blob, params: { workflow_id: workflow, version: 1, path: 'diagram.png' }, format: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_equal 'diagram.png', data['path']
    assert_equal 32248, data['size']
    assert_equal true, data['binary']
  end

  test 'view missing blob as json' do
    workflow = FactoryBot.create(:local_git_workflow, policy: FactoryBot.create(:public_policy))
    get :blob, params: { workflow_id: workflow, version: 1, path: 'doesnotexist' }, format: :json

    assert_response :not_found
    data = JSON.parse(response.body)
    assert_equal "Couldn't find path: doesnotexist", data['error']
  end

  test 'cannot view a blob as json if no permission' do
    workflow = FactoryBot.create(:local_git_workflow)
    get :blob, params: { workflow_id: workflow, version: 1, path: 'concat_two_files.ga' }, format: :json

    assert_response :forbidden
    data = JSON.parse(response.body)
    assert_equal 'Not authorized', data['error']
  end

  test 'view root tree as json' do
    workflow = FactoryBot.create(:ro_crate_git_workflow, policy: FactoryBot.create(:public_policy))
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
    workflow = FactoryBot.create(:ro_crate_git_workflow, policy: FactoryBot.create(:public_policy))
    get :tree, params: { workflow_id: workflow, version: 1, path: 'test/test1' }, format: :json

    assert_response :success
    data = JSON.parse(response.body)
    assert_equal 'test/test1', data['path']
    assert_equal 3, data['tree'].length
    assert_includes data['tree'].map { |e| e['name'] }, 'input.bed'
  end

  test 'view missing tree as json' do
    workflow = FactoryBot.create(:ro_crate_git_workflow, policy: FactoryBot.create(:public_policy))
    get :tree, params: { workflow_id: workflow, version: 1, path: 'test/test47' }, format: :json

    assert_response :not_found
    data = JSON.parse(response.body)
    assert_equal "Couldn't find path: test/test47", data['error']
  end

  test 'cannot view a tree as json if no permission' do
    workflow = FactoryBot.create(:ro_crate_git_workflow)
    get :blob, params: { workflow_id: workflow, version: 1, path: 'test/test1' }, format: :json

    assert_response :forbidden
    data = JSON.parse(response.body)
    assert_equal 'Not authorized', data['error']
  end

  # post 'blob(/*path)' =>'git#add_file', as: :git_add_file
  # delete 'blob/*path' => 'git#remove_file', as: :git_remove_file
  # patch 'blob/*path' => 'git#move_file', as: :git_move_file

  test 'add a new file via API' do
    workflow = FactoryBot.create(:local_git_workflow, policy: FactoryBot.create(:public_policy))
    refute workflow.git_version.file_exists?('new_file.txt')

    post :add_file, params: { workflow_id: workflow, version: 1, path: 'new_file.txt', file: { content: Base64.encode64('file contents') } }, format: :json

    assert_response :created
    assert workflow.git_version.file_exists?('new_file.txt')
  end

  test 'add a new remote file via API' do
    workflow = FactoryBot.create(:local_git_workflow, policy: FactoryBot.create(:public_policy))
    refute workflow.git_version.file_exists?('new_remote_file.txt')

    assert_difference('Git::Annotation.count', 1) do
      post :add_file, params: { workflow_id: workflow, version: 1, path: 'new_remote_file.txt', file: { url: 'http://example.com' } }, format: :json
    end

    assert_response :created
    assert workflow.git_version.file_exists?('new_remote_file.txt')
    assert_equal 'http://example.com', workflow.git_version.remote_sources['new_remote_file.txt']
  end

  test 'cannot add a new file via API if not authorized' do
    workflow = FactoryBot.create(:local_git_workflow)
    refute workflow.git_version.file_exists?('new_file.txt')

    post :add_file, params: { workflow_id: workflow, version: 1, path: 'new_file.txt', file: { content: Base64.encode64('file contents') } }, format: :json

    assert_response :forbidden
    refute workflow.git_version.file_exists?('new_file.txt')
  end

  test 'update an existing file via API' do
    workflow = FactoryBot.create(:local_git_workflow, policy: FactoryBot.create(:public_policy))
    refute_equal 'file contents', workflow.git_version.file_contents('concat_two_files.ga')

    post :add_file, params: { workflow_id: workflow, version: 1, path: 'concat_two_files.ga', file: { content: Base64.encode64('file contents') } }, format: :json

    assert_response :created
    assert_equal 'file contents', workflow.git_version.file_contents('concat_two_files.ga')
  end

  test 'rename a file via API' do
    workflow = FactoryBot.create(:local_git_workflow, policy: FactoryBot.create(:public_policy))
    refute workflow.git_version.file_exists?('concat_2_files.ga')
    assert_equal 'concat_two_files.ga', workflow.git_version.main_workflow_path

    post :move_file, params: { workflow_id: workflow, version: 1, path: 'concat_two_files.ga', file: { new_path: 'concat_2_files.ga' } }, format: :json

    assert_response :success
    assert_equal 'concat_2_files.ga', workflow.git_version.main_workflow_path
    assert workflow.git_version.file_exists?('concat_2_files.ga')
  end

  test 'cannot rename a file via API if not authorized' do
    workflow = FactoryBot.create(:local_git_workflow)
    assert workflow.git_version.file_exists?('concat_two_files.ga')
    assert_equal 'concat_two_files.ga', workflow.git_version.main_workflow_path

    post :move_file, params: { workflow_id: workflow, version: 1, path: 'concat_two_files.ga', file: { new_path: 'concat_2_files.ga' } }, format: :json

    assert_response :forbidden
    assert workflow.git_version.file_exists?('concat_two_files.ga')
    assert_equal 'concat_two_files.ga', workflow.git_version.main_workflow_path
  end

  test 'trying to rename a file via API with invalid path throws error' do
    workflow = FactoryBot.create(:local_git_workflow, policy: FactoryBot.create(:public_policy))
    assert workflow.git_version.file_exists?('concat_two_files.ga')
    assert_equal 'concat_two_files.ga', workflow.git_version.main_workflow_path

    post :move_file, params: { workflow_id: workflow, version: 1, path: 'concat_two_files.ga', file: { new_path: '////////////' } }, format: :json

    assert_response :unprocessable_entity
    assert workflow.git_version.file_exists?('concat_two_files.ga')
    assert_equal 'concat_two_files.ga', workflow.git_version.main_workflow_path
  end

  test 'remove a file via API' do
    workflow = FactoryBot.create(:local_git_workflow, policy: FactoryBot.create(:public_policy))
    assert workflow.git_version.file_exists?('diagram.png')

    delete :remove_file, params: { workflow_id: workflow, version: 1, path: 'diagram.png' }, format: :json

    assert_response :success
    refute workflow.git_version.file_exists?('diagram.png')
  end

  test 'cannot remove a file via API if not authorized' do
    workflow = FactoryBot.create(:local_git_workflow)
    assert workflow.git_version.file_exists?('diagram.png')

    delete :remove_file, params: { workflow_id: workflow, version: 1, path: 'diagram.png' }, format: :json

    assert_response :forbidden
    assert workflow.git_version.file_exists?('diagram.png')
  end

  test 'trying to remove a file via API with wrong path throws error' do
    workflow = FactoryBot.create(:local_git_workflow, policy: FactoryBot.create(:public_policy))

    delete :remove_file, params: { workflow_id: workflow, version: 1, path: '../../../../home' }, format: :json

    assert_response :not_found
  end

  test 'should display blob as pdf' do
    @git_version.add_file('file.pdf', FactoryBot.create(:pdf_content_blob))
    disable_authorization_checks { @git_version.save! }

    get :raw, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'file.pdf', display: 'pdf' }

    assert_response :success
    assert @response.header['Content-Type'].start_with?('text/html')
    assert_nil @response.header['Content-Security-Policy']
    assert_select 'iframe', count: 0
    assert_select '#outerContainer'
  end

  test 'should display blob as markdown' do
    @git_version.add_file('file.md', FactoryBot.create(:markdown_content_blob))
    disable_authorization_checks { @git_version.save! }

    get :raw, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'file.md', display: 'markdown' }

    assert_response :success
    assert @response.header['Content-Type'].start_with?('text/html')
    assert_equal ApplicationController::USER_CONTENT_CSP, @response.header['Content-Security-Policy']
    assert_select 'iframe', count: 0
    assert_select '#navbar', count: 0
    assert_select '.markdown-body h1', text: 'FAIRDOM-SEEK'
  end

  test 'should display blob as markdown inline' do
    @git_version.add_file('file.md', FactoryBot.create(:markdown_content_blob))
    disable_authorization_checks { @git_version.save! }

    get :raw, xhr: true, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'file.md',
                                   display: 'markdown', disposition: 'inline' }

    assert_response :success
    assert @response.header['Content-Type'].start_with?('text/html')
    assert_equal ApplicationController::USER_CONTENT_CSP, @response.header['Content-Security-Policy']
    assert_select 'body', count: 0
    assert_select 'iframe'
  end

  test 'should display blob as jupyter' do
    @git_version.add_file('file.ipynb', FactoryBot.create(:jupyter_notebook_content_blob))
    disable_authorization_checks { @git_version.save! }

    get :raw, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'file.ipynb', display: 'notebook' }

    assert_response :success
    assert @response.header['Content-Type'].start_with?('text/html')
    assert_equal "default-src 'self'; img-src * data:; style-src 'unsafe-inline';", @response.header['Content-Security-Policy']
    assert_select 'iframe', count: 0
    assert_select '#navbar', count: 0
    assert_select 'body.jp-Notebook'
    assert_select 'div.jp-MarkdownOutput p', text: 'Import the libraries so that they can be used within the notebook'
  end

  test 'should display blob as text' do
    @git_version.add_file('file.txt', FactoryBot.create(:txt_content_blob))
    disable_authorization_checks { @git_version.save! }

    get :raw, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'file.txt', display: 'text' }

    assert_response :success
    assert @response.header['Content-Type'].start_with?('text/plain')
    assert_equal ApplicationController::USER_CONTENT_CSP, @response.header['Content-Security-Policy']
    assert_equal "This is a txt format\n", response.body
  end

  test 'should display blob as image' do
    @git_version.add_file('file.png', FactoryBot.create(:image_content_blob))
    disable_authorization_checks { @git_version.save! }

    get :raw, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'file.png', display: 'image' }

    assert_response :success
    assert @response.header['Content-Type'].start_with?('text/html')
    assert_equal ApplicationController::USER_CONTENT_CSP, @response.header['Content-Security-Policy']
    assert_select 'img.git-image-preview[src=?]', workflow_git_raw_path(@git_version.resource, version: @git_version.version, path: 'file.png')
  end

  test 'should throw 406 trying to display image as text' do
    @git_version.add_file('file.png', FactoryBot.create(:image_content_blob))
    disable_authorization_checks { @git_version.save! }

    assert_raises(ActionController::UnknownFormat) do
      get :raw, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'file.png', display: 'text' }
    end
  end

  test 'can edit version name and comment' do
    assert_not_equal 'modified', @git_version.name
    assert_not_equal 'modified', @git_version.name

    patch :update, params: { workflow_id: @workflow.id, version: @git_version.version,
                                   git_version: { name: 'modified', comment: 'modified' } }

    assert_redirected_to @workflow
    assert_equal 'modified', @git_version.reload.name
  end

  test 'can edit version visibility' do
    disable_authorization_checks { @workflow.save_as_new_git_version }

    assert_equal 2, @workflow.reload.version

    assert_not_equal :registered_users, @workflow.find_version(1).visibility
    refute @workflow.find_version(1).latest_git_version?

    patch :update, params: { workflow_id: @workflow.id, version: 1,
                                   git_version: { visibility: 'registered_users' } }

    assert_redirected_to @workflow
    assert_equal :registered_users, @workflow.find_version(1).reload.visibility
  end

  test 'cannot edit version visibility if doi minted' do
    disable_authorization_checks do
      @workflow.save_as_new_git_version
      @workflow.find_version(1).update_column(:doi, '10.5072/wtf')
    end

    assert_equal :public, @workflow.find_version(1).visibility

    patch :update, params: { workflow_id: @workflow.id, version: 1,
                                   git_version: { visibility: 'registered_users' } }

    assert_redirected_to @workflow
    assert_equal :public, @workflow.find_version(1).reload.visibility, 'Should not have changed visibility - DOI present'
  end

  test 'cannot edit version visibility if latest version' do
    assert @git_version.latest_git_version?
    assert_equal :public, @workflow.find_version(1).visibility

    patch :update, params: { workflow_id: @workflow.id, version: 1,
                                   git_version: { visibility: 'private' } }

    assert_redirected_to @workflow
    assert_equal :public, @workflow.find_version(1).reload.visibility,'Should not have changed visibility - latest version'
  end

  test 'actions are logged' do
    @git_version.add_file('file.md', FactoryBot.create(:markdown_content_blob))
    disable_authorization_checks { @git_version.save! }

    assert_difference('@workflow.download_count') do
      get :raw, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'concat_two_files.ga' }
    end

    assert_response :success
    log = @workflow.activity_logs.last
    assert_equal 'download', log.action
    assert_equal 'concat_two_files.ga', log.data[:path]

    assert_no_difference('@workflow.download_count') do
      assert_difference('@workflow.reload.activity_logs.count') do
        get :raw, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'file.md', display: 'markdown' }
      end
    end

    assert_response :success
    log = @workflow.activity_logs.last
    assert_equal 'inline_view', log.action
    assert_equal 'file.md', log.data[:path]
    assert_equal 'markdown', log.data[:display]
  end

  test 'should display CFF blob as citation' do
    @git_version.add_file('CITATION.cff', open_fixture_file('CITATION.cff'))
    disable_authorization_checks { @git_version.save! }

    get :raw, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'CITATION.cff',
                        display: 'citation' }

    assert_response :success
    assert @response.header['Content-Type'].start_with?('text/html')
    assert_equal ApplicationController::USER_CONTENT_CSP, @response.header['Content-Security-Policy']
    assert_select 'body'
    assert_select '#navbar', count: 0
    assert_select 'div[data-citation-style=?]', 'apa', text: /van der Real Person, O\. T\./
  end

  test 'should display CFF blob as citation with selected style' do
    @git_version.add_file('CITATION.cff', open_fixture_file('CITATION.cff'))
    disable_authorization_checks { @git_version.save! }

    get :raw, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'CITATION.cff',
                        display: 'citation', style: 'bibtex' }

    assert_response :success
    assert @response.header['Content-Type'].start_with?('text/html')
    assert_equal ApplicationController::USER_CONTENT_CSP, @response.header['Content-Security-Policy']
    assert_select 'body'
    assert_select '#navbar', count: 0
    assert_select 'div[data-citation-style=?]', 'bibtex', text: /author=\{Real Person, One Truly van der, IV and/
  end

  test 'should display CFF blob as citation inline' do
    @git_version.add_file('CITATION.cff', open_fixture_file('CITATION.cff'))
    disable_authorization_checks { @git_version.save! }

    get :raw, xhr: true, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'CITATION.cff',
                                   display: 'citation', disposition: 'inline', style: 'the-lancet' }

    assert_response :success
    assert @response.header['Content-Type'].start_with?('text/html')
    assert_equal ApplicationController::USER_CONTENT_CSP, @response.header['Content-Security-Policy']
    assert_select 'body', count: 0
    assert_select 'div[data-citation-style=?]', 'the-lancet', text: /Real Person OT van der IV/
  end
end
