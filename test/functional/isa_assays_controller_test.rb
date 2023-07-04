require 'test_helper'

class IsaAssaysControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include SharingFormTestHelper

  def setup
    login_as FactoryBot.create :user
  end

  test 'should get new' do
    inv = FactoryBot.create(:investigation, projects: projects, contributor: User.current_user.person)
    study = FactoryBot.create(:study, investigation_id: inv.id, contributor: User.current_user.person)
    sample_type = FactoryBot.create(:simple_sample_type)
    study.sample_types << sample_type

    get :new, params: { study_id: study }
    assert_response :success
    assert_not_nil assigns(:isa_assay)
  end

  test 'should create' do
    projects = User.current_user.person.projects
    inv = FactoryBot.create(:investigation, projects: projects, contributor: User.current_user.person)
    study = FactoryBot.create(:study, investigation_id: inv.id, contributor: User.current_user.person)
    other_creator = FactoryBot.create(:person)
    this_person = User.current_user.person

    source_sample_type = FactoryBot.create(:simple_sample_type, title: 'source sample_type')

    sample_collection_sample_type = FactoryBot.create(:multi_linked_sample_type, project_ids: [projects.first.id],
                                                                       title: 'sample_collection sample_type')
    sample_collection_sample_type.sample_attributes.last.linked_sample_type = source_sample_type

    study.sample_types = [source_sample_type, sample_collection_sample_type]

    policy_attributes = { access_type: Policy::ACCESSIBLE,
                          permissions_attributes: project_permissions([projects.first], Policy::ACCESSIBLE) }

    assert_difference('Assay.count', 1) do
      assert_difference('SampleType.count', 1) do
        post :create, params: { isa_assay: { assay: { title: 'test', study_id: study.id,
                                                      sop_ids: [FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy)).id],
                                                      creator_ids: [this_person.id, other_creator.id],
                                                      other_creators: 'other collaborators',
                                                      position: 0, assay_class_id: 1, policy_attributes: policy_attributes },
                                             input_sample_type_id: sample_collection_sample_type.id,
                                             sample_type: { title: 'assay sample_type', project_ids: [projects.first.id], template_id: 1,
                                                            sample_attributes_attributes: {
                                                              '0' => {
                                                                pos: '1', title: 'a string', required: '1', is_title: '1',
                                                                sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id, _destroy: '0'
                                                              },
                                                              '1' => {
                                                                pos: '2', title: 'protocol', required: '1', is_title: '0',
                                                                sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id, isa_tag_id: IsaTag.find_by_title(Seek::ISA::TagType::PROTOCOL).id, _destroy: '0'
                                                              },
                                                              '2' => {
                                                                pos: '3', title: 'link', required: '1',
                                                                sample_attribute_type_id: FactoryBot.create(:sample_multi_sample_attribute_type).id,
                                                                linked_sample_type_id: 'self', _destroy: '0'
                                                              }
                                                            } } } }
      end
    end
    isa_assay = assigns(:isa_assay)
    assert_redirected_to controller: 'single_pages', action: 'show', id: isa_assay.assay.projects.first.id,
                         params: { notice: 'The ISA assay was created successfully!',
                                   item_type: 'assay', item_id: Assay.last.id }

    sample_types = SampleType.last(2)
    title = sample_types[0].sample_attributes.detect(&:is_title).title
    sample_multi = sample_types[1].sample_attributes.detect(&:seek_sample_multi?)

    assert_equal "Input (#{title})", sample_multi.title

    assert_equal [this_person, other_creator], isa_assay.assay.creators
    assert_equal 'other collaborators', isa_assay.assay.other_creators
  end

  test 'author form partial uses correct nested param attributes' do
    get :new, params: { study_id: FactoryBot.create(:study, contributor: User.current_user.person) }
    assert_response :success
    assert_select '#author-list[data-field-name=?]','isa_assay[assay][assets_creators_attributes]'
    assert_select '#isa_assay_assay_other_creators'
  end

  test 'should show new when parameters are incomplete' do
    projects = User.current_user.person.projects
    inv = FactoryBot.create(:investigation, projects: projects, contributor: User.current_user.person)
    study = FactoryBot.create(:study, investigation_id: inv.id, contributor: User.current_user.person)

    source_sample_type = FactoryBot.create(:simple_sample_type)

    sample_collection_sample_type = FactoryBot.create(:multi_linked_sample_type, project_ids: [projects.first.id])
    sample_collection_sample_type.sample_attributes.last.linked_sample_type = source_sample_type

    study.sample_types = [source_sample_type, sample_collection_sample_type]

    post :create, params: { isa_assay: {
      assay: { title: 'test', study_id: study.id,
               sop_ids: [FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy)).id] },
      sample_type: {
        title: 'source', project_ids: [projects.first.id],
        sample_attributes_attributes: {}
      }
    } }

    assert_template :new
  end

  test 'should update isa assay' do
    person = User.current_user.person
    project = person.projects.first
    investigation = FactoryBot.create(:investigation, projects: [project])
    other_creator = FactoryBot.create(:person)


    source_type = FactoryBot.create(:isa_source_sample_type, contributor: person, projects: [project])
    sample_collection_type = FactoryBot.create(:isa_sample_collection_sample_type, contributor: person, projects: [project],
                                                                         linked_sample_type: source_type)
    assay_type = FactoryBot.create(:isa_assay_sample_type, contributor: person, projects: [project],
                                                 linked_sample_type: sample_collection_type)

    study = FactoryBot.create(:study, investigation: investigation, contributor: person,
                            sops: [FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy))],
                            sample_types: [source_type, sample_collection_type])

    assay = FactoryBot.create(:assay, study: study, contributor: person)
    put :update, params: { id: assay, isa_assay: { assay: { title: 'assay title' } } }
    assert_redirected_to single_page_path(id: project, item_type: 'assay', item_id: assay.id)
    assert flash[:error].include?('Resource not found.')

    assay = FactoryBot.create(:assay, study: study, sample_type: assay_type, contributor: person)

    put :update, params: { id: assay, isa_assay: { assay: { title: 'assay title',  sop_ids: [FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy)).id],
                                                            creator_ids: [person.id, other_creator.id], other_creators: 'other collaborators' },
                                                   sample_type: { title: 'sample type title' } } }

    isa_assay = assigns(:isa_assay)
    assert_equal 'assay title', isa_assay.assay.title
    assert_equal 'sample type title', isa_assay.sample_type.title
    assert_redirected_to single_page_path(id: project, item_type: 'assay', item_id: assay.id)

    assert_equal [person, other_creator], isa_assay.assay.creators
    assert_equal 'other collaborators', isa_assay.assay.other_creators
  end
end
