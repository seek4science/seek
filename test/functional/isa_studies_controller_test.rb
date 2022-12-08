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
    inv = Factory(:investigation, projects: projects, contributor: User.current_user.person)
    assert_difference('Study.count', 1) do
      assert_difference('SampleType.count', 2) do
        post :create, params: { isa_study: { study: { title: 'test', investigation_id: inv.id, sop_id: Factory(:sop, policy: Factory(:public_policy)).id },
                                             source_sample_type: { title: 'source', project_ids: [projects.first.id],
                                                                   sample_attributes_attributes: {
                                                                     '0' => {
                                                                       pos: '1', title: 'a string', required: '1', is_title: '1',
                                                                       sample_attribute_type_id: Factory(:string_sample_attribute_type).id, _destroy: '0'
                                                                     },
                                                                     '1' => {
                                                                       pos: '2', title: 'source', required: '1',
                                                                       sample_attribute_type_id: Factory(:string_sample_attribute_type).id,
                                                                       isa_tag_id: IsaTag.find_by_title(Seek::ISA::TagType::SOURCE).id, _destroy: '0'
                                                                     },
                                                                     '2' => {
                                                                       pos: '3', title: 'a sample', required: '1',
                                                                       sample_attribute_type_id: Factory(:string_sample_attribute_type).id, _destroy: '0'
                                                                     }
                                                                   } },
                                             sample_collection_sample_type: { title: 'collection', project_ids: [projects.first.id],
                                                                              sample_attributes_attributes: {
                                                                                '0' => {
                                                                                  pos: '1', title: 'a string', required: '1', is_title: '1',
                                                                                  sample_attribute_type_id: Factory(:string_sample_attribute_type).id, _destroy: '0'
                                                                                },
                                                                                '1' => {
                                                                                  pos: '2', title: 'sample', required: '1',
                                                                                  sample_attribute_type_id: Factory(:string_sample_attribute_type).id,
                                                                                  isa_tag_id: IsaTag.find_by_title(Seek::ISA::TagType::SAMPLE).id, _destroy: '0'
                                                                                },
                                                                                '2' => {
                                                                                  pos: '3', title: 'a sample', required: '1',
                                                                                  sample_attribute_type_id: Factory(:sample_multi_sample_attribute_type).id,
                                                                                  linked_sample_type_id: 'self', _destroy: '0'
                                                                                }
                                                                              } } } }
      end
    end
    i = assigns(:isa_study)
    assert_redirected_to controller: 'single_pages', action: 'show', id: i.study.projects.first.id,
                         params: { item_type: 'study', item_id: Study.last.id }

    sample_types = SampleType.last(2)
    title = sample_types[0].sample_attributes.detect(&:is_title).title
    sample_multi = sample_types[1].sample_attributes.detect(&:seek_sample_multi?)

    assert_equal "Input (#{title})", sample_multi.title
  end

  test 'should edit isa study' do
    person = User.current_user.person
    project = person.projects.first
    investigation = Factory(:investigation, projects: [project])

    source_type = Factory(:isa_source_sample_type, contributor: person, projects: [project])
    sample_collection_type = Factory(:isa_sample_collection_sample_type, contributor: person, projects: [project],
                                                                         linked_sample_type: source_type)

    study = Factory(:study, investigation: investigation,
                            sops: [Factory(:sop, policy: Factory(:public_policy))],
                            sample_types: [source_type, sample_collection_type])

    put :update, params: { id: study, isa_study: { study: { title: 'study title' },
                                                   source_sample_type: { title: 'source title' },
                                                   sample_collection_sample_type: { title: 'sample title' } } }

    assert_not_nil flash[:error]

    study.contributor = person
    study.save!
    put :update, params: { id: study, isa_study: { study: { title: 'study title' },
                                                   source_sample_type: { title: 'source title' },
                                                   sample_collection_sample_type: { title: 'sample title' } } }
    isa_study = assigns(:isa_study)
    assert_equal 'study title', isa_study.study.title
    assert_equal 'source title', isa_study.source.title
    assert_equal 'sample title', isa_study.sample_collection.title
    assert_redirected_to single_page_path(id: project, item_type: 'study', item_id: study.id)
  end
end
