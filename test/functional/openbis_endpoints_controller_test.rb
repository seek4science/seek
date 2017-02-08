require 'test_helper'
require 'openbis_test_helper'

class OpenbisEndpointsControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  def setup
    Factory(:person)
    mock_openbis_calls
  end

  test 'destroy' do
    pa = Factory(:project_administrator)
    project=pa.projects.first
    ep = Factory(:openbis_endpoint,project:project)
    login_as(pa)
    assert ep.can_delete?

    assert_difference('OpenbisEndpoint.count',-1) do
      delete :destroy, id: ep.id,project_id:project.id
      assert_redirected_to project_openbis_endpoints_path(project)
    end

    person = Factory(:person)
    project=person.projects.first
    ep = Factory(:openbis_endpoint,project:project)
    login_as(person)
    refute ep.can_delete?

    assert_no_difference('OpenbisEndpoint.count') do
      delete :destroy, id: ep.id,project_id:project.id
      assert_redirected_to :root
      refute_nil flash[:error]
    end

    #other scenerios are covered in the unit tests for can_delete?
  end

  test 'add dataset' do
    person = Factory(:project_administrator)
    project=person.projects.first
    disable_authorization_checks do
      project.update_attributes(default_license:'wibble')
    end
    endpoint = Factory(:openbis_endpoint,project:project)
    perm_id='20160210130454955-23'
    login_as(person)
    assert_difference("DataFile.count") do
      post :add_dataset,id:endpoint.id,project_id:project.id,dataset_perm_id:perm_id
      assert_nil flash[:error]
    end
    data_file=assigns(:data_file)
    assert_redirected_to data_file
    assert_equal '20160210130454955-23',data_file.content_blobs.first.openbis_dataset.perm_id
    assert_equal 'wibble',data_file.license
  end

end
