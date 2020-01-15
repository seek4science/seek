require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  fixtures :all
  include AuthenticatedTestHelper

  test 'upload file to project default folders' do
    assert_difference('OtherProjectFile.count', 1) do
      p = Factory(:project)
      post :upload_project_file, params: { id: p.id, description: 'test description', pid: p.id, folder: 'presentations', file: uploadable_file }
    end
  end

  test 'files count of project default folders' do
    p = Factory(:project)
    post :upload_project_file, params: { id: p.id, description: 'test description', pid: p.id, folder: 'presentations', file: uploadable_file }
    controller = TreeviewBuilder.new p
    assert_equal controller.send(:f_count, 'presentations').to_i, 1
  end

  test 'get file list of project default folders' do
    p = Factory(:project)
    post :upload_project_file, params: { id: p.id, description: 'test description', pid: p.id, folder: 'presentations', file: uploadable_file }
    post :get_file_list, params: { id: p.id, folder: 'presentations' }
    result = JSON.parse(response.body)
    assert_equal result.length, 1
    assert_equal result[0]['name'], 'TestUpload.txt'
    assert_equal result[0]['extension'], '.txt'
  end

  def uploadable_file
    fixture_file_upload('files/TestUpload.txt', 'text/plain')
  end
end
