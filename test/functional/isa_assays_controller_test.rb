require 'test_helper'

class IsaAssaysControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include SharingFormTestHelper

  def setup
    login_as Factory :user
  end

  test 'should get new' do
    inv = Factory(:investigation, projects: projects, contributor:User.current_user.person)
    study = Factory(:study, investigation_id: inv.id, contributor:User.current_user.person)
    sample_type = Factory(:simple_sample_type)
    study.sample_types << sample_type

    get :new, params: { study_id: study }
    assert_response :success
    assert_not_nil assigns(:isa_assay)
  end

  test 'should create' do
    projects = User.current_user.person.projects
    inv = Factory(:investigation, projects: projects, contributor:User.current_user.person)
    study = Factory(:study, investigation_id: inv.id, contributor:User.current_user.person)

    source_sample_type = Factory(:simple_sample_type)

    sample_collection_sample_type = Factory(:multi_linked_sample_type, project_ids: [projects.first.id])
    sample_collection_sample_type.sample_attributes.last.linked_sample_type = source_sample_type

    study.sample_types = [source_sample_type, sample_collection_sample_type]

    policy_attributes = { access_type: Policy::ACCESSIBLE,
      permissions_attributes: project_permissions([projects.first], Policy::ACCESSIBLE) }

    assert_difference('Assay.count', 1) do
      assert_difference('SampleType.count', 1) do
       post :create, params: { isa_assay: { assay: { title: 'test', study_id: study.id, 
                                                    sop_ids: [Factory(:sop, policy: Factory(:public_policy)).id],
                                                    position: 0, assay_class_id: 1, policy_attributes: policy_attributes }, 
                                            input_sample_type_id: sample_collection_sample_type.id,
                                            sample_type: { title: 'source', project_ids: [projects.first.id], template_id: 1,
                                              sample_attributes_attributes: {
                                                '0' => {
                                                  pos: '1', title: 'a string', required: '1', is_title: '1',
                                                  sample_attribute_type_id: Factory(:string_sample_attribute_type).id, _destroy: '0'
                                                },
                                                '1' => {
                                                  pos: '2', title: 'protocol', required: '1', is_title: '0',
                                                  sample_attribute_type_id: Factory(:string_sample_attribute_type).id, isa_tag_id: IsaTag.find_by_title(Seek::ISA::TagType::PROTOCOL).id, _destroy: '0'
                                                },
                                                '2' => {
                                                  pos: '3', title: 'link', required: '1',
                                                  sample_attribute_type_id: Factory(:sample_multi_sample_attribute_type).id,
                                                  linked_sample_type_id: "self", _destroy: '0'
                                                }
                                            }} 
                              }
                            }
      end
    end
    i = assigns(:isa_assay)
    assert_redirected_to controller: "single_pages", action: "show", id: i.assay.projects.first.id, 
                         params: { notice: 'The ISA assay was created successfully!',
													item_type: 'assay', item_id: Assay.last.id }
  end

  test 'should show new on incomplete params' do
    projects = User.current_user.person.projects
    inv = Factory(:investigation, projects: projects, contributor:User.current_user.person)
    study = Factory(:study, investigation_id: inv.id, contributor:User.current_user.person)

    source_sample_type = Factory(:simple_sample_type)

    sample_collection_sample_type = Factory(:multi_linked_sample_type, project_ids: [projects.first.id])
    sample_collection_sample_type.sample_attributes.last.linked_sample_type = source_sample_type

    study.sample_types = [source_sample_type, sample_collection_sample_type]

    post :create, params: { isa_assay: { 
                              assay: { title: 'test', study_id: study.id, sop_ids: [Factory(:sop, policy: Factory(:public_policy)).id]}, 
                              sample_type: { 
                                title: 'source', project_ids: [projects.first.id], 
                                sample_attributes_attributes: {}
                              } 
                            }
                          }

    assert_template :new

  end

end