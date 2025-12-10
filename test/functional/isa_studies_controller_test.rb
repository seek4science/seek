require 'test_helper'

class ISAStudiesControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include ISATagsTestHelper

  def setup
    login_as FactoryBot.create(:admin).user
    create_all_isa_tags
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
                                             source_sample_type: source_attributes(projects),
                                             sample_collection_sample_type: sample_collection_attributes(projects) } }
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
                             source_sample_type: source_attributes([project]),
                             sample_collection_sample_type: sample_collection_attributes([project]) }

    assert_difference('Study.count', 1) do
      assert_difference 'ExtendedMetadata.count', 1 do
        post :create,
             params: { isa_study: isa_study_attributes }
      end
    end
  end

  test 'Should create the same policies for the sample types' do
    person = FactoryBot.create(:person_not_in_project)
    second_person = FactoryBot.create(:person_not_in_project)
    institution = FactoryBot.create(:institution)
    project = FactoryBot.create(:project)
    [person, second_person].each do |p|
      p.add_to_project_and_institution(project, institution)
      p.reload
    end
    investigation = FactoryBot.create(:investigation, projects: [project], contributor: person)

    study_policy_attributes = { access_type: Policy::NO_ACCESS, permissions_attributes: {"1": { contributor_type: 'Person', contributor_id: person.id, access_type: Policy::MANAGING }, "2": { contributor_type: 'Person', contributor_id: second_person.id, access_type: Policy::VISIBLE }} }

    study = FactoryBot.build(:study, investigation: investigation, contributor: person)
    study_attributes = study.as_json

    login_as person.user
    post :create, params: { isa_study: { study: study_attributes, source_sample_type: source_attributes, sample_collection_sample_type: sample_collection_attributes }, policy_attributes: study_policy_attributes }
    @isa_study = assigns(:isa_study)
    assert_redirected_to single_page_path(id: @isa_study.study.projects.first, item_type: 'study', item_id: @isa_study.study)

    # Check that the policies are the same
    @isa_study.study.sample_types.each do |st|
      assert_equal @isa_study.study.policy, st.policy
    end

    # person can manage the study and the sample types
    assert @isa_study.study.can_manage?
    assert @isa_study.source.can_manage?
    assert @isa_study.sample_collection.can_manage?

    # second_person can only view the study and the sample types
    login_as second_person.user
    assert @isa_study.study.can_view?(second_person.user)
    refute @isa_study.study.can_manage?(second_person.user)
    assert @isa_study.source.can_view?(second_person.user)
    refute @isa_study.source.can_manage?(second_person.user)
    assert @isa_study.sample_collection.can_view?(second_person.user)
    refute @isa_study.sample_collection.can_manage?(second_person.user)
  end

  test 'should update sample metadata when updating the isa study sample type' do
    person = FactoryBot.create(:person)
    project = person.projects.first

    investigation = FactoryBot.create(:investigation, projects: [project], contributor: person)
    source_type = FactoryBot.create(:isa_source_sample_type, contributor: person, projects: [project])
    sample_collection_type = FactoryBot.create(:isa_sample_collection_sample_type, contributor: person, projects: [project], linked_sample_type: source_type)

    FactoryBot.create(:sample, sample_type: source_type, contributor: person, project_ids: [project.id], data: { 'Source Name': 'source1', 'Source Characteristic 1': 'source 1 characteristic 1', 'Source Characteristic 2': 'Bramley' })
    FactoryBot.create(:sample, sample_type: source_type, contributor: person, project_ids: [project.id], data: { 'Source Name': 'source2', 'Source Characteristic 1': 'source 2 characteristic 1', 'Source Characteristic 2': 'Granny Smith' })

    FactoryBot.create(:sample, sample_type: sample_collection_type, contributor: person, project_ids: [project.id], data: { 'Sample Name': 'sample1', 'sample collection': 'collection method 1', Input: 'source1', 'sample characteristic 1': 'value sample 1', 'sample collection parameter value 1': 'value 1' })
    FactoryBot.create(:sample, sample_type: sample_collection_type, contributor: person, project_ids: [project.id], data: { 'Sample Name': 'sample2', 'sample collection': 'collection method 1', Input: 'source2', 'sample characteristic 1': 'value sample 2', 'sample collection parameter value 1': 'value 2' })

    study = FactoryBot.create(:study, investigation: investigation, contributor: person, sample_types: [source_type, sample_collection_type])

    title_attribute = study.sample_types.first.sample_attributes.detect(&:is_title)

    login_as person.user

    patch :update, params: { id: study, isa_study:
      { source_sample_type:
          { sample_attributes: [
            { id: title_attribute.id, title: 'New Source Name' }
          ] }
      }
    }

    assert_response :redirect
    assert_enqueued_with(job: UpdateSampleMetadataJob)
    study.sample_types.first.reload
    assert_equal study.sample_types.first.sample_attributes.detect(&:is_title).title, 'New Source Name'
    assert study.sample_types.first.locked?
  end

  test 'should auto-populate the sample type title and description' do
    projects = User.current_user.person.projects
    inv = FactoryBot.create(:investigation, projects:, contributor: User.current_user.person, is_isa_json_compliant: true)
    source_sample_type_no_title = source_attributes(projects)
    source_sample_type_no_title.delete(:title)
    sample_collection_sample_type_no_title = sample_collection_attributes(projects)
    sample_collection_sample_type_no_title.delete(:title)

    assert_difference('Study.count', 1) do
      assert_difference('SampleType.count', 2) do
        post :create, params: { isa_study: { study: { title: 'test', investigation_id: inv.id, sop_id: FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy)).id },
                                             source_sample_type: source_sample_type_no_title ,
                                             sample_collection_sample_type: sample_collection_sample_type_no_title } }
      end
    end

    assert_response :redirect
    isa_study = assigns(:isa_study)

    assert_equal isa_study.source.title, "#{isa_study.study.title} - Source Sample Type"
    assert_equal isa_study.sample_collection.title, "#{isa_study.study.title} - Sample Collection Sample Type"
  end

  private

  def sample_collection_attributes(projects=[])
    { title: 'sample collection', project_ids: projects.map(&:id),
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
      } }
  end

  def source_attributes(projects=[])
    { title: 'source', project_ids: projects.map(&:id),
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
      } }
  end
end
