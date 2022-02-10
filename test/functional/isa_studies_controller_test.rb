require 'test_helper'

class IsaStudiesControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as Factory(:admin).user
  end

  test 'should get new' do
    get :new
    assert_response :success
    assert_not_nil assigns(:isa_study)
  end

  test 'should create' do
    projects = User.current_user.person.projects
    inv = Factory(:investigation, projects: projects, contributor:User.current_user.person)
    assert_difference('Study.count', 1) do
      assert_difference('SampleType.count', 2) do
        post :create, params: {isa_study: { study: { title: 'test', investigation_id: inv.id, sop_id: Factory(:sop, policy: Factory(:public_policy)).id },
                    source_sample_type: { title: 'source', project_ids: [projects.first.id], 
                      sample_attributes_attributes: {
                        '0' => {
                          pos: '1', title: 'a string', required: '1', is_title: '1',
                          sample_attribute_type_id: Factory(:string_sample_attribute_type).id, _destroy: '0'
                        },
                        '1' => {
                          pos: '2', title: 'a sample', required: '1',
                          sample_attribute_type_id: Factory(:string_sample_attribute_type).id, _destroy: '0'
                        }
                      }}, 
                    sample_collection_sample_type: { title: 'collection', project_ids: [projects.first.id], 
                      sample_attributes_attributes: {
                        '0' => {
                          pos: '1', title: 'a string', required: '1', is_title: '1',
                          sample_attribute_type_id: Factory(:string_sample_attribute_type).id, _destroy: '0'
                        },
                        '1' => {
                          pos: '2', title: 'a sample', required: '1',
                          sample_attribute_type_id: Factory(:sample_multi_sample_attribute_type).id,
                          linked_sample_type_id: "self", _destroy: '0'
                        }
                      }} }}
      end
    end
    i = assigns(:isa_study)
    assert_redirected_to controller: "single_pages", action: "show", id: i.study.projects.first.id, 
                         params: { notice: 'The ISA study was created successfully!' }
  end

end
