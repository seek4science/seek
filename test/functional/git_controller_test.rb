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

    patch :move_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                              file: { path: 'diagram.png', new_path: 'cool-pic.png' } }

    assert_redirected_to workflow_path(@workflow, anchor: 'files')
    refute assigns(:git_version).file_exists?('diagram.png')
    assert assigns(:git_version).file_exists?('cool-pic.png')
  end

  test 'move file into directory' do
    assert @git_version.file_exists?('diagram.png')
    refute @git_version.file_exists?('mydir/cool-pic.png')

    patch :move_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                              file: { path: 'diagram.png', new_path: 'mydir/cool-pic.png' } }

    assert_redirected_to workflow_path(@workflow, anchor: 'files')
    refute assigns(:git_version).file_exists?('diagram.png')
    assert assigns(:git_version).file_exists?('mydir/cool-pic.png')
  end

  test 'error when moving non-existent path' do
    patch :move_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                              file: { path: 'doesnotexist.png', new_path: 'mydir/cool-pic.png' } }

    assert flash[:error].include?("Couldn't find path: doesnotexist.png")
    refute assigns(:git_version).file_exists?('mydir/cool-pic.png')
  end

  test 'cannot move file if no permissions' do
    logout
    assert @git_version.file_exists?('diagram.png')
    refute @git_version.file_exists?('cool-pic.png')

    patch :move_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                                file: { path: 'diagram.png', new_path: 'cool-pic.png' } }

    assert_redirected_to root_path
    assert flash[:error].include?('authorized')
    assert @git_version.reload.file_exists?('diagram.png')
    refute @git_version.reload.file_exists?('cool-pic.png')
  end

  test 'cannot move file if immutable' do
    @git_version.update_column(:mutable, false)
    assert @git_version.file_exists?('diagram.png')
    refute @git_version.file_exists?('cool-pic.png')

    patch :move_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                                file: { path: 'diagram.png', new_path: 'cool-pic.png' } }

    assert_redirected_to workflow_path(@workflow, anchor: 'files')
    assert flash[:error].include?('cannot make changes')
    assert assigns(:git_version).file_exists?('diagram.png')
    refute assigns(:git_version).file_exists?('cool-pic.png')
  end

  test 'remove file' do
    assert @git_version.file_exists?('diagram.png')

    patch :remove_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                                file: { path: 'diagram.png' } }

    assert_redirected_to workflow_path(@workflow, anchor: 'files')
    refute assigns(:git_version).file_exists?('diagram.png')
  end

  test 'error when removing non-existent path' do
    refute @git_version.file_exists?('doesnotexist.png')

    patch :remove_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                                file: { path: 'doesnotexist.png' } }

    assert flash[:error].include?("Couldn't find path: doesnotexist.png")
    refute assigns(:git_version).file_exists?('doesnotexist.png')
  end

  test 'cannot remove file if no permissions' do
    logout
    assert @git_version.file_exists?('diagram.png')

    patch :remove_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                                file: { path: 'diagram.png'} }

    assert_redirected_to root_path
    assert flash[:error].include?('authorized')
    assert @git_version.reload.file_exists?('diagram.png')
  end

  test 'cannot remove file if immutable' do
    @git_version.update_column(:mutable, false)
    assert @git_version.file_exists?('diagram.png')

    patch :remove_file, params: { workflow_id: @workflow.id, version: @git_version.version,
                                  file: { path: 'diagram.png'} }

    assert_redirected_to workflow_path(@workflow, anchor: 'files')
    assert flash[:error].include?('cannot make changes')
  end

  test 'get text file blob' do
    get :blob, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'concat_two_files.ga' }

    assert_response :success
    assert_select 'a.btn[href=?]', workflow_git_remove_file_path(@workflow, version: @git_version.version, file: { path: 'concat_two_files.ga' })
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
    assert_select 'a.btn[href=?]', workflow_git_remove_file_path(@workflow, version: @git_version.version, file: { path: 'diagram.png' })
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
    get :download, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'doesnotexist' }

    assert flash[:error].include?("Couldn't find path: doesnotexist")
  end

  test 'getting blob with no permissions throws error' do
    logout
    get :blob, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'diagram.png' }

    assert flash[:error].include?('authorized')
  end

  test 'getting raw with no permissions throws error' do
    logout
    get :raw, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'diagram.png' }

    assert flash[:error].include?('authorized')
  end

  test 'download with no permissions throws error' do
    logout
    get :download, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'diagram.png' }

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
    assert_select 'a.btn[href=?]', workflow_git_remove_file_path(@workflow, version: @git_version.version, file: { path: 'concat_two_files.ga' }), count: 0

    # DOWNLOAD
    login_as(downloader)

    get :blob, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'concat_two_files.ga' }

    assert_response :success
    assert_select 'a.btn[href=?]', workflow_git_raw_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga'), count: 1
    assert_select 'a.btn[href=?]', workflow_git_download_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga'), count: 1
    assert_select "a.btn[data-target='#git-move-modal']", count: 0
    assert_select 'a.btn[href=?]', workflow_git_remove_file_path(@workflow, version: @git_version.version, file: { path: 'concat_two_files.ga' }), count: 0

    # EDIT
    login_as(editor)

    get :blob, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'concat_two_files.ga' }

    assert_response :success
    assert_select 'a.btn[href=?]', workflow_git_raw_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga'), count: 1
    assert_select 'a.btn[href=?]', workflow_git_download_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga'), count: 1
    assert_select "a.btn[data-target='#git-move-modal']", count: 1
    assert_select 'a.btn[href=?]', workflow_git_remove_file_path(@workflow, version: @git_version.version, file: { path: 'concat_two_files.ga' }), count: 1

    # MANAGE
    login_as(manager)

    get :blob, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'concat_two_files.ga' }

    assert_response :success
    assert_select 'a.btn[href=?]', workflow_git_raw_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga'), count: 1
    assert_select 'a.btn[href=?]', workflow_git_download_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga'), count: 1
    assert_select "a.btn[data-target='#git-move-modal']", count: 1
    assert_select 'a.btn[href=?]', workflow_git_remove_file_path(@workflow, version: @git_version.version, file: { path: 'concat_two_files.ga' }), count: 1
  end

  test 'disables move and delete buttons if immutable' do
    @git_version.update_column(:mutable, false)

    get :blob, params: { workflow_id: @workflow.id, version: @git_version.version, path: 'concat_two_files.ga' }

    assert_response :success
    assert_select 'a.btn[href=?]', workflow_git_raw_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga'), count: 1
    assert_select 'a.btn[href=?]', workflow_git_download_path(@workflow, version: @git_version.version, path: 'concat_two_files.ga'), count: 1
    assert_select "a.btn[data-target='#git-move-modal']", count: 0
    assert_select 'a.btn[href=?]', workflow_git_remove_file_path(@workflow, version: @git_version.version, file: { path: 'concat_two_files.ga' }), count: 0
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
end
