require 'test_helper'

class IsaStudiesControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as FactoryBot.create(:admin).user
  end

  test 'should get new' do
    get :new
    assert_response :success
    assert_not_nil assigns(:isa_study)
  end

  test 'should create' do
    projects = User.current_user.person.projects
    inv = FactoryBot.create(:investigation, projects:, contributor: User.current_user.person)
    assert_difference('Study.count', 1) do
      assert_difference('SampleType.count', 2) do
        post :create, params: { isa_study: { study: { title: 'test', investigation_id: inv.id, sop_id: FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy)).id },
                                             source_sample_type: { title: 'source', project_ids: [projects.first.id],
                                                                   sample_attributes_attributes: {
                                                                     '1': {
                                                                       pos: '1', title: 'Source Name', required: '1', is_title: '1',
                                                                       sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id,
                                                                       isa_tag_id: FactoryBot.create(:source_isa_tag).id, _destroy: '0'
                                                                     },
                                                                     '2': {
                                                                       pos: '2', title: 'Source Characteristic 1', required: '1', is_title: '0',
                                                                       sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id,
                                                                       isa_tag_id: FactoryBot.create(:source_characteristic_isa_tag).id, _destroy: '0'
                                                                     }
                                                                   } },
                                             sample_collection_sample_type: { title: 'sample collection', project_ids: [projects.first.id],
                                                                              sample_attributes_attributes: {
                                                                                '1': {
                                                                                  pos: '1', title: 'Input', required: '1', is_title: '0',
                                                                                  sample_attribute_type_id: FactoryBot.create(:sample_multi_sample_attribute_type).id,
                                                                                  linked_sample_type_id: 'self',
                                                                                  _destroy: '0'
                                                                                },
                                                                                '2': {
                                                                                  pos: '2', title: 'sample collection', required: '1', is_title: '0',
                                                                                  sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id,
                                                                                  isa_tag_id: FactoryBot.create(:parameter_value_isa_tag).id,
                                                                                  _destroy: '0'
                                                                                },
                                                                                '3': {
                                                                                  pos: '3', title: 'sampling site', required: '0', is_title: '0',
                                                                                  sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id,
                                                                                  isa_tag_id: FactoryBot.create(:protocol_isa_tag).id,
                                                                                  _destroy: '0'
                                                                                },
                                                                                '4': {
                                                                                  pos: '4', title: 'Sample Name', required: '1', is_title: '1',
                                                                                  sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id,
                                                                                  isa_tag_id: FactoryBot.create(:sample_isa_tag).id,
                                                                                  _destroy: '0'
                                                                                },
                                                                                '5': {
                                                                                  pos: '5', title: 'material type', required: '1', is_title: '0',
                                                                                  sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id,
                                                                                  isa_tag_id: FactoryBot.create(:sample_characteristic_isa_tag).id,
                                                                                  _destroy: '0'
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
    investigation = FactoryBot.create(:investigation, projects: [project])

    source_type = FactoryBot.create(:isa_source_sample_type, contributor: person, projects: [project])
    sample_collection_type = FactoryBot.create(:isa_sample_collection_sample_type, contributor: person, projects: [project],
                                                                                   linked_sample_type: source_type)

    study = FactoryBot.create(:study, investigation:,
                                      sops: [FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy))],
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

  test 'should create an isa study with extended metadata' do
    person = User.current_user.person
    project = person.projects.first
    investigation = FactoryBot.create(:investigation, projects: [project], contributor: person)

    emt = FactoryBot.create(:simple_study_extended_metadata_type)

    study_attributes = { title: 'test', investigation_id: investigation.id,
                         sop_id: FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy)).id }

    em_attributes = { extended_metadata_attributes: {
      extended_metadata_type_id: emt.id,
      data: {
        "age": 35,
        "name": 'John Doe',
        "date": '14-11-1988'
      }
    } }

    isa_study_attributes = { study: study_attributes.merge(em_attributes),
                             source_sample_type: { title: 'source', project_ids: [project.id],
                                                   sample_attributes_attributes: {
                                                     '1': {
                                                       pos: '1', title: 'Source Name', required: '1', is_title: '1',
                                                       sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id,
                                                       isa_tag_id: FactoryBot.create(:source_isa_tag).id, _destroy: '0'
                                                     },
                                                     '2': {
                                                       pos: '2', title: 'Source Characteristic 1', required: '1', is_title: '0',
                                                       sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id,
                                                       isa_tag_id: FactoryBot.create(:source_characteristic_isa_tag).id, _destroy: '0'
                                                     }
                                                   } },
                             sample_collection_sample_type: { title: 'sample collection', project_ids: [project.id],
                                                              sample_attributes_attributes: {
                                                                '1': {
                                                                  pos: '1', title: 'Input', required: '1', is_title: '0',
                                                                  sample_attribute_type_id: FactoryBot.create(:sample_multi_sample_attribute_type).id,
                                                                  linked_sample_type_id: 'self',
                                                                  _destroy: '0'
                                                                },
                                                                '2': {
                                                                  pos: '2', title: 'sample collection', required: '1', is_title: '0',
                                                                  sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id,
                                                                  isa_tag_id: FactoryBot.create(:parameter_value_isa_tag).id,
                                                                  _destroy: '0'
                                                                },
                                                                '3': {
                                                                  pos: '3', title: 'sampling site', required: '0', is_title: '0',
                                                                  sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id,
                                                                  isa_tag_id: FactoryBot.create(:protocol_isa_tag).id,
                                                                  _destroy: '0'
                                                                },
                                                                '4': {
                                                                  pos: '4', title: 'Sample Name', required: '1', is_title: '1',
                                                                  sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id,
                                                                  isa_tag_id: FactoryBot.create(:sample_isa_tag).id,
                                                                  _destroy: '0'
                                                                },
                                                                '5': {
                                                                  pos: '5', title: 'material type', required: '1', is_title: '0',
                                                                  sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id,
                                                                  isa_tag_id: FactoryBot.create(:sample_characteristic_isa_tag).id,
                                                                  _destroy: '0'
                                                                }
                                                              } } }

    assert_difference('Study.count', 1) do
      assert_difference 'ExtendedMetadata.count', 1 do
        post :create,
             params: { isa_study: isa_study_attributes }
      end
    end
  end
end
