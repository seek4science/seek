require 'test_helper'

class ISAAssaysControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include SharingFormTestHelper
  include ISATagsTestHelper

  def setup
    login_as FactoryBot.create :user
    create_all_isa_tags
  end

  test 'should get new' do
    inv = FactoryBot.create(:investigation, projects:, contributor: User.current_user.person)
    study = FactoryBot.create(:study, investigation_id: inv.id, contributor: User.current_user.person)
    sample_type = FactoryBot.create(:simple_sample_type)
    study.sample_types << sample_type

    get :new, params: { study_id: study }
    assert_response :success
    assert_not_nil assigns(:isa_assay)
  end

  test 'should create' do
    projects = User.current_user.person.projects
    inv = FactoryBot.create(:investigation, projects:, contributor: User.current_user.person)
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
                                                      assay_class_id: AssayClass.experimental.id,
                                                      position: 0, policy_attributes: },
                                             input_sample_type_id: sample_collection_sample_type.id,
                                             sample_type: create_material_assay_sample_type_attributes(projects.first, sample_collection_sample_type.id)
        } }
      end
    end
    isa_assay = assigns(:isa_assay)
    assert_redirected_to controller: 'single_pages', action: 'show', id: isa_assay.assay.projects.first.id,
                         params: { item_type: 'assay', item_id: Assay.last.id }

    sample_types = SampleType.last(2)
    title = sample_types[0].sample_attributes.detect(&:is_title).title
    sample_multi = sample_types[1].sample_attributes.detect(&:seek_sample_multi?)

    assert_equal "Input (#{title})", sample_multi.title

    assert_equal [this_person, other_creator], isa_assay.assay.creators
    assert_equal 'other collaborators', isa_assay.assay.other_creators
  end

  test 'should create an assay stream' do
    projects = User.current_user.person.projects
    inv = FactoryBot.create(:investigation, projects:, contributor: User.current_user.person)
    study = FactoryBot.create(:study, investigation_id: inv.id, contributor: User.current_user.person)


    policy_attributes = { access_type: Policy::ACCESSIBLE,
                          permissions_attributes: project_permissions([projects.first], Policy::ACCESSIBLE) }

    assert_difference('Assay.count', 1) do
      post :create, params: { isa_assay: { assay: { title: 'test stream', study_id: study.id,
                                                    sop_ids: [FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy)).id],
                                                    creator_ids: [User.current_user.person.id],
                                                    other_creators: 'other collaborators',
                                                    assay_class_id: AssayClass.assay_stream.id,
                                                    projects: projects.first,
                                                    policy_attributes: policy_attributes
      } } }

      assert_redirected_to single_page_path(id: projects.first.id, item_type: 'assay', item_id: Assay.last.id)
    end
  end

  test 'author form partial uses correct nested param attributes' do
    get :new, params: { study_id: FactoryBot.create(:study, contributor: User.current_user.person) }
    assert_response :success
    assert_select '#author-list[data-field-name=?]', 'isa_assay[assay][assets_creators_attributes]'
    assert_select '#isa_assay_assay_other_creators'
  end

  test 'should show new when parameters are incomplete' do
    projects = User.current_user.person.projects
    inv = FactoryBot.create(:investigation, projects:, contributor: User.current_user.person)
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
    assay_type = FactoryBot.create(:isa_assay_material_sample_type, contributor: person, projects: [project],
                                                           linked_sample_type: sample_collection_type)

    study = FactoryBot.create(:study, investigation:, contributor: person,
                                      sops: [FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy))],
                                      sample_types: [source_type, sample_collection_type])

    assay = FactoryBot.create(:assay, study:, contributor: person)
    put :update, params: { id: assay, isa_assay: { assay: { title: 'assay title' } } }
    assert_redirected_to single_page_path(id: project, item_type: 'assay', item_id: assay.id)
    assert flash[:error].include?('Sample type not found.')

    assay = FactoryBot.create(:assay, study:, sample_type: assay_type, contributor: person)

    put :update, params: { id: assay, isa_assay: { assay: { title: 'assay title', sop_ids: [FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy)).id],
                                                            creator_ids: [person.id, other_creator.id], other_creators: 'other collaborators' },
                                                   sample_type: { title: 'sample type title' } } }

    isa_assay = assigns(:isa_assay)
    assert_equal 'assay title', isa_assay.assay.title
    assert_equal 'sample type title', isa_assay.sample_type.title
    assert_redirected_to single_page_path(id: project, item_type: 'assay', item_id: assay.id)

    assert_equal [person, other_creator], isa_assay.assay.creators
    assert_equal 'other collaborators', isa_assay.assay.other_creators
  end

  test 'should create an isa assay with extended metadata' do
    projects = User.current_user.person.projects
    inv = FactoryBot.create(:investigation, projects:, contributor: User.current_user.person)
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

    emt = FactoryBot.create(:simple_assay_extended_metadata_type)

    emt_attributes = { extended_metadata_attributes: {
      extended_metadata_type_id: emt.id,
      data: {
        "age": 43,
        "name": 'Jane Doe',
        "date": '14-11-1980'
      }
    } }

    assay_attributes = { title: 'First assay with custom metadata', study_id: study.id,
                         sop_ids: [FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy)).id],
                         creator_ids: [this_person.id, other_creator.id],
                         other_creators: 'other collaborators',
                         position: 0, assay_class_id: AssayClass.experimental.id, policy_attributes: }

    isa_assay_attributes = { assay: assay_attributes.merge(emt_attributes),
                             input_sample_type_id: sample_collection_sample_type.id,
                             sample_type: create_material_assay_sample_type_attributes(projects.first, sample_collection_sample_type.id)
    }

    assert_difference 'Assay.count', 1 do
      assert_difference 'ExtendedMetadata.count', 1 do
        post :create,
             params: { isa_assay: isa_assay_attributes }
      end
    end
  end

  test 'hide sops, publications, documents, and discussion channels if assay stream' do
    person = FactoryBot.create(:person)
    investigation = FactoryBot.create(:investigation, contributor: person, is_isa_json_compliant: true)
    study = FactoryBot.create(:isa_json_compliant_study, contributor: person, investigation: )
    assay_stream = FactoryBot.create(:assay_stream, study: , contributor: person, position: 0)

    login_as(person)

    get :new, params: { study_id: study.id, is_assay_stream: true }
    assert_response :success

    assert_select 'div#add_sops_form', text: /SOPs/i, count: 0
    assert_select 'div#add_publications_form', text: /Publications/i, count: 0
    assert_select 'div#add_documents_form', text: /Documents/i, count: 0
    assert_select 'div.panel-heading', text: /Discussion Channels/i, count: 0
    assert_select 'div.panel-heading', text: /Define Sample type for Assay/i, count: 0

    get :edit, params: { id: assay_stream.id, study_id: study.id, source_assay_id: assay_stream.id, is_assay_stream: true }
    assert_response :success

    assert_select 'div#add_sops_form', text: /SOPs/i, count: 0
    assert_select 'div#add_publications_form', text: /Publications/i, count: 0
    assert_select 'div#add_documents_form', text: /Documents/i, count: 0
    assert_select 'div.panel-heading', text: /Discussion Channels/i, count: 0
    assert_select 'div.panel-heading', text: /Define Sample type for Assay/i, count: 0
  end

  test 'show sops, publications, documents, and discussion channels if experimental assay' do
    person = FactoryBot.create(:person)
    project = person.projects.first
    investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true, contributor: person, projects: [project])
    study = FactoryBot.create(:isa_json_compliant_study, contributor: person, investigation: )
    assay_stream = FactoryBot.create(:assay_stream, study: , contributor: person, position: 0)

    login_as(person)

    get :new, params: { study_id: study.id, assay_stream_id: assay_stream.id, source_assay_id: assay_stream.id }
    assert_response :success

    assert_select 'div#add_sops_form', text: /SOPs/i, count: 1
    assert_select 'div#add_publications_form', text: /Publications/i, count: 1
    assert_select 'div#add_documents_form', text: /Documents/i, count:1
    assert_select 'div.panel-heading', text: /Discussion Channels/i, count: 1
    assert_select 'div.panel-heading', text: /Define Sample type for Assay/i, count: 1

    first_assay_st = FactoryBot.create(:isa_assay_material_sample_type, contributor: person, projects: [project], linked_sample_type: study.sample_types.second)
    first_assay = FactoryBot.create(:assay, contributor: person, study: , assay_stream: , position: 1, sample_type: first_assay_st)
    assert_equal assay_stream, first_assay.assay_stream

    get :edit, params: { id: first_assay.id, assay_stream_id: assay_stream.id, source_assay_id: first_assay.id, study_id: study.id }
    assert_response :success

    assert_select 'div#add_sops_form', text: /SOPs/i, count: 1
    assert_select 'div#add_publications_form', text: /Publications/i, count: 1
    assert_select 'div#add_documents_form', text: /Documents/i, count: 1
    assert_select 'div.panel-heading', text: /Discussion Channels/i, count: 1
    assert_select 'div.panel-heading', text: /Define Sample type for Assay/i, count: 1
  end

  test 'insert assay between assay stream and experimental assay' do
    person = FactoryBot.create(:person)
    project = person.projects.first
    login_as(person)
    investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true, contributor: person)
    study = FactoryBot.create(:isa_json_compliant_study, investigation: , contributor: person )

    ## Create an assay stream
    assay_stream = FactoryBot.create(:assay_stream, contributor: person, study: )
    assert assay_stream.is_assay_stream?
    assert_equal assay_stream.previous_linked_sample_type, study.sample_types.second
    assert_nil assay_stream.next_linked_child_assay

    ## Create an assay at the end of the stream
    end_assay_sample_type = FactoryBot.create(:isa_assay_material_sample_type,
                                              linked_sample_type: study.sample_types.second,
                                              projects: [project],
                                              contributor: person)
    end_assay = FactoryBot.create(:assay, position: 0, contributor: person, study: , sample_type: end_assay_sample_type, assay_stream: )

    refute end_assay.is_assay_stream?
    assert_equal end_assay.previous_linked_sample_type, assay_stream.previous_linked_sample_type, study.sample_types.second
    assert_nil end_assay.next_linked_child_assay

    # Test assay linkage
    ## Post intermediate assay
    policy_attributes = { access_type: Policy::ACCESSIBLE,
                          permissions_attributes: project_permissions([projects.first], Policy::ACCESSIBLE) }

    intermediate_assay_attributes1 = { title: 'First intermediate assay',
                                      study_id: study.id,
                                      assay_class_id: AssayClass.experimental.id,
                                      creator_ids: [person.id],
                                      policy_attributes: ,
                                      assay_stream_id: assay_stream.id, position: 0 }


    intermediate_isa_assay_attributes1 = { assay: intermediate_assay_attributes1,
                                           input_sample_type_id: study.sample_types.second.id,
                                           sample_type: create_material_assay_sample_type_attributes(projects.first, study.sample_types.second.id) }

    assert_difference "Assay.count", 1 do
      assert_difference "SampleType.count", 1 do
        post :create, params: { isa_assay: intermediate_isa_assay_attributes1 }
      end
    end

    isa_assay = assigns(:isa_assay)
    assert_redirected_to single_page_path(id: project, item_type: 'assay', item_id: isa_assay.assay.id)

    assert_equal isa_assay.assay.sample_type.previous_linked_sample_type, study.sample_types.second
    assert_equal isa_assay.assay.next_linked_child_assay, end_assay

    # Test the assay positions after reorganising
    end_assay.reload
    refute_equal end_assay.position, 0
    assert_equal end_assay.position, 1

    isa_assay.assay.reload
    assert_equal isa_assay.assay.position, 0
  end

  test 'insert assay between two experimental assays' do
    person = FactoryBot.create(:person)
    project = person.projects.first
    login_as(person)
    investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true, contributor: person)
    study = FactoryBot.create(:isa_json_compliant_study, investigation: , contributor: person )

    ## Create an assay stream
    assay_stream = FactoryBot.create(:assay_stream, contributor: person, study: )
    assert assay_stream.is_assay_stream?
    assert_equal assay_stream.previous_linked_sample_type, study.sample_types.second
    assert_nil assay_stream.next_linked_child_assay

    ## Create an assay at the begin of the stream
    begin_assay_sample_type = FactoryBot.create(:isa_assay_material_sample_type,
                                                linked_sample_type: study.sample_types.second,
                                                projects: [project],
                                                contributor: person)
    begin_assay = FactoryBot.create(:assay, title: 'Begin Assay', position: 0, contributor: person, study: , sample_type: begin_assay_sample_type, assay_stream: )

    ## Create an assay at the end of the stream
    end_assay_sample_type = FactoryBot.create(:isa_assay_data_file_sample_type,
                                              linked_sample_type: begin_assay_sample_type,
                                              projects: [project],
                                              contributor: person)
    end_assay = FactoryBot.create(:assay, title: 'End Assay', position: 1, contributor: person, study: , sample_type: end_assay_sample_type, assay_stream: )

    refute end_assay.is_assay_stream?
    assert_equal begin_assay.previous_linked_sample_type, assay_stream.previous_linked_sample_type, study.sample_types.second
    assert_nil end_assay.next_linked_child_assay

    # Test assay linkage
    ## Post intermediate assay
    policy_attributes = { access_type: Policy::ACCESSIBLE,
                          permissions_attributes: project_permissions([projects.first], Policy::ACCESSIBLE) }

    intermediate_assay_attributes2 = { title: 'Second intermediate assay',
                                      study_id: study.id,
                                      assay_class_id: AssayClass.experimental.id,
                                      creator_ids: [person.id],
                                      policy_attributes: ,
                                      assay_stream_id: assay_stream.id }

    intermediate_assay_sample_type_attributes2 = { title: "Intermediate Assay Sample type 2",
                                                    project_ids: [project.id],
                                                    sample_attributes_attributes: {
                                                      '0': {
                                                        pos: '1', title: 'a string', required: '1', is_title: '1',
                                                        sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id, _destroy: '0',
                                                        isa_tag_id: FactoryBot.create(:other_material_isa_tag).id
                                                      },
                                                      '1': {
                                                        pos: '2', title: 'protocol', required: '1', is_title: '0',
                                                        sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id,
                                                        isa_tag_id: FactoryBot.create(:protocol_isa_tag).id, _destroy: '0'
                                                      },
                                                      '2': {
                                                        pos: '3', title: 'Input sample', required: '1',
                                                        sample_attribute_type_id: FactoryBot.create(:sample_multi_sample_attribute_type).id,
                                                        linked_sample_type_id: study.sample_types.second.id, _destroy: '0'
                                                      },
                                                      '3': {
                                                        pos: '4', title: 'Some material characteristic', required: '1',
                                                        sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id,
                                                        _destroy: '0',
                                                        isa_tag_id: FactoryBot.create(:other_material_characteristic_isa_tag).id
                                                      }
                                                    }
                                                  }

    intermediate_isa_assay_attributes2 = { assay: intermediate_assay_attributes2,
                                           input_sample_type_id: begin_assay_sample_type.id,
                                           sample_type: intermediate_assay_sample_type_attributes2 }


    assert_difference "Assay.count", 1 do
      assert_difference "SampleType.count", 1 do
        post :create, params: { isa_assay: intermediate_isa_assay_attributes2 }
      end
    end

    isa_assay = assigns(:isa_assay)
    assert_redirected_to single_page_path(id: project, item_type: 'assay', item_id: isa_assay.assay.id)

    assert_equal begin_assay.previous_linked_sample_type, study.sample_types.second
    assert_equal isa_assay.assay.sample_type.previous_linked_sample_type, begin_assay.sample_type
    assert_equal isa_assay.assay.next_linked_child_assay, end_assay

    # Test the assay positions after reorganising
    end_assay.reload
    refute_equal end_assay.position, 1
    assert_equal end_assay.position, 2

    isa_assay.assay.reload
    assert_equal isa_assay.assay.position, 1
  end

  test 'should not insert assay if next assay has samples' do
    person = FactoryBot.create(:person)
    project = person.projects.first
    login_as(person)
    investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true, contributor: person)
    study = FactoryBot.create(:isa_json_compliant_study, investigation: , contributor: person )

    ## Create an assay stream
    assay_stream = FactoryBot.create(:assay_stream, contributor: person, study: )
    assert assay_stream.is_assay_stream?
    assert_equal assay_stream.previous_linked_sample_type, study.sample_types.second
    assert_nil assay_stream.next_linked_child_assay

    ## Create an assay at the begin of the stream
    begin_assay_sample_type = FactoryBot.create(:isa_assay_material_sample_type,
                                                linked_sample_type: study.sample_types.second,
                                                projects: [project],
                                                contributor: person)
    begin_assay = FactoryBot.create(:assay, title: 'Begin Assay', contributor: person, study: , sample_type: begin_assay_sample_type, assay_stream: )

    ## Create an assay at the end of the stream
    end_assay_sample_type = FactoryBot.create(:isa_assay_data_file_sample_type,
                                              linked_sample_type: begin_assay_sample_type,
                                              projects: [project],
                                              contributor: person)
    end_assay = FactoryBot.create(:assay, title: 'End Assay', contributor: person, study: , sample_type: end_assay_sample_type, assay_stream: )

    refute end_assay.is_assay_stream?
    assert_equal begin_assay.previous_linked_sample_type, assay_stream.previous_linked_sample_type, study.sample_types.second
    assert_nil end_assay.next_linked_child_assay

    source_sample =
    FactoryBot.create :sample,
          title: 'source 1',
          sample_type: study.sample_types.first,
          project_ids: [project.id],
          data: {
            'Source Name': 'Source Name',
            'Source Characteristic 1': 'Source Characteristic 1',
            'Source Characteristic 2':
              study.sample_types.first
                .sample_attributes
                .find_by_title('Source Characteristic 2')
                .sample_controlled_vocab
                .sample_controlled_vocab_terms
                .first
                .label
          },
          contributor: person

    sample_sample =
      FactoryBot.create :sample,
          title: 'sample 1',
          sample_type: study.sample_types.second,
          project_ids: [project.id],
          data: {
            Input: [source_sample.id],
            'sample collection': 'sample collection',
            'sample collection parameter value 1': 'sample collection parameter value 1',
            'Sample Name': 'sample name',
            'sample characteristic 1': 'sample characteristic 1'
          },
          contributor: person

    FactoryBot.create :sample,
      title: 'Begin Material 1',
      sample_type: begin_assay_sample_type,
      project_ids: [project.id],
      data: {
        Input: [sample_sample.id],
        'Protocol Assay 1': 'Protocol Assay 1',
        'Assay 1 parameter value 1': 'Assay 1 parameter value 1',
        'Extract Name': 'Extract Name',
        'other material characteristic 1': 'other material characteristic 1'
    },
    contributor: person


    assert assay_stream.next_linked_child_assay.sample_type.samples.any?

    # Test assay linkage
    ## Post intermediate assay
    policy_attributes = { access_type: Policy::ACCESSIBLE,
                          permissions_attributes: project_permissions([projects.first], Policy::ACCESSIBLE) }

    intermediate_assay_attributes3 = { title: 'Third intermediate assay',
                                      study_id: study.id,
                                      assay_class_id: AssayClass.experimental.id,
                                      creator_ids: [person.id],
                                      policy_attributes: ,
                                      assay_stream_id: assay_stream.id }

    intermediate_assay_sample_type_attributes3 = { title: "Intermediate Assay Sample type 3",
                                                    project_ids: [project.id],
                                                    sample_attributes_attributes: {
                                                      '0': {
                                                        pos: '1', title: 'a string', required: '1', is_title: '1',
                                                        sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id, _destroy: '0',
                                                        isa_tag_id: FactoryBot.create(:other_material_isa_tag).id
                                                      },
                                                      '1': {
                                                        pos: '2', title: 'protocol', required: '1', is_title: '0',
                                                        sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id,
                                                        isa_tag_id: FactoryBot.create(:protocol_isa_tag).id, _destroy: '0'
                                                      },
                                                      '2': {
                                                        pos: '3', title: 'Input sample', required: '1',
                                                        sample_attribute_type_id: FactoryBot.create(:sample_multi_sample_attribute_type).id,
                                                        linked_sample_type_id: study.sample_types.second.id, _destroy: '0'
                                                      },
                                                      '3': {
                                                        pos: '4', title: 'Some material characteristic', required: '1',
                                                        sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id,
                                                        _destroy: '0',
                                                        isa_tag_id: FactoryBot.create(:other_material_characteristic_isa_tag).id
                                                      }
                                                    }
                                                  }

    intermediate_isa_assay_attributes3 = { assay: intermediate_assay_attributes3,
                                           input_sample_type_id: assay_stream.id,
                                           sample_type: intermediate_assay_sample_type_attributes3 }

    assert_no_difference "Assay.count" do
      assert_no_difference "SampleType.count" do
        post :create, params: { isa_assay: intermediate_isa_assay_attributes3 }
      end
    end
    assert_response :not_found
  end

  test 'position when creating assays' do
    person = FactoryBot.create(:person)
    investigation = FactoryBot.create(:investigation, contributor: person, is_isa_json_compliant: true)
    study = FactoryBot.create(:isa_json_compliant_study, contributor: person, investigation: )

    login_as(person)

    get :new, params: { study_id: study.id, is_assay_stream: true }
    assert_response :success
    # New assay stream should have position 0 and is of type 'number'
    assert_select 'input[type=number][value=0]#isa_assay_assay_position', count: 1

    assay_stream1 = FactoryBot.create(:assay_stream, study: , contributor: person, position: 0)
    get :new, params: { study_id: study.id, is_assay_stream: true }
    assert_response :success
    # New assay stream should have position 1 and is of type 'number'
    assert_select 'input[type=number][value=1]#isa_assay_assay_position', count: 1

    FactoryBot.create(:assay_stream, study: , contributor: person, position: 5)
    get :new, params: { study_id: study.id, is_assay_stream: true }
    assert_response :success
    # New assay stream should have position 6 and is of type 'number'
    assert_select 'input[type=number][value=6]#isa_assay_assay_position', count: 1

    get :new, params: { study_id: study.id, assay_stream_id: assay_stream1.id, source_assay_id: assay_stream1.id }
    # New assay should have position 0 and is of type 'hidden'
    assert_select 'input[type=hidden][value=0]#isa_assay_assay_position', count: 1

  end

  test 'Should create the same policies for the sample type' do
    person = FactoryBot.create(:person_not_in_project)
    second_person = FactoryBot.create(:person_not_in_project)
    institution = FactoryBot.create(:institution)
    project = FactoryBot.create(:project)
    [person, second_person].each do |p|
      p.add_to_project_and_institution(project, institution)
      p.reload
    end
    investigation = FactoryBot.create(:investigation, projects: [project], contributor: person)

    study = FactoryBot.create(:isa_json_compliant_study, contributor: person, investigation: )

    assay_policy_attributes = { access_type: Policy::NO_ACCESS, permissions_attributes: { "1": { contributor_type: 'Person', contributor_id: person.id, access_type: Policy::MANAGING }, "2": { contributor_type: 'Person', contributor_id: second_person.id, access_type: Policy::VISIBLE } } }

    assay_stream = FactoryBot.create(:assay_stream, study: , contributor: person, position: 0)
    assay = FactoryBot.build(:assay, study: , contributor: person, assay_class: AssayClass.experimental, assay_stream: assay_stream, assay_type_uri: nil)
    assay_attributes = assay.as_json.reject { |_, v| v.blank? }

    login_as person.user
    post :create, params: { isa_assay: { assay: assay_attributes, sample_type: create_material_assay_sample_type_attributes(project, study.sample_types.second.id), source_assay_id: assay_stream.id, input_sample_type_id: study.sample_types.second.id }, policy_attributes: assay_policy_attributes }
    @isa_assay = assigns(:isa_assay)
    assert_redirected_to single_page_path(id: @isa_assay.assay.projects.first, item_type: 'assay', item_id: @isa_assay.assay)

    # Check that the policies are the same
    assert_equal @isa_assay.assay.policy, @isa_assay.sample_type.policy

    # person can manage the study and the sample types
    assert @isa_assay.assay.can_manage?
    assert @isa_assay.sample_type.can_manage?

    # second_person can only view the study and the sample types
    login_as second_person.user
    assert @isa_assay.assay.can_view?(second_person.user)
    refute @isa_assay.assay.can_manage?(second_person.user)
    assert @isa_assay.sample_type.can_view?(second_person.user)
    refute @isa_assay.sample_type.can_manage?(second_person.user)
  end

  test 'should update sample metadata when updating the isa assay sample type' do
    person = FactoryBot.create(:person)
    project = person.projects.first

    investigation = FactoryBot.create(:investigation, projects: [project], contributor: person)
    source_type = FactoryBot.create(:isa_source_sample_type, contributor: person, projects: [project])
    sample_collection_type = FactoryBot.create(:isa_sample_collection_sample_type, contributor: person, projects: [project], linked_sample_type: source_type)
    assay_type = FactoryBot.create(:isa_assay_material_sample_type, contributor: person, projects: [project], linked_sample_type: sample_collection_type)

    FactoryBot.create(:sample, sample_type: source_type, contributor: person, project_ids: [project.id], data: { 'Source Name': 'source1', 'Source Characteristic 1': 'source 1 characteristic 1', 'Source Characteristic 2': 'Bramley' })
    FactoryBot.create(:sample, sample_type: source_type, contributor: person, project_ids: [project.id], data: { 'Source Name': 'source2', 'Source Characteristic 1': 'source 2 characteristic 1', 'Source Characteristic 2': 'Granny Smith' })

    FactoryBot.create(:sample, sample_type: sample_collection_type, contributor: person, project_ids: [project.id], data: { 'Sample Name': 'sample1', 'sample collection': 'collection method 1', Input: 'source1', 'sample characteristic 1': 'value sample 1', 'sample collection parameter value 1': 'value 1' })
    FactoryBot.create(:sample, sample_type: sample_collection_type, contributor: person, project_ids: [project.id], data: { 'Sample Name': 'sample2', 'sample collection': 'collection method 1', Input: 'source2', 'sample characteristic 1': 'value sample 2', 'sample collection parameter value 1': 'value 2' })

    FactoryBot.create(:sample, sample_type: assay_type, contributor: person, project_ids: [project.id], data: { 'Extract Name': 'Extract 1', 'Protocol Assay 1': 'method 1', Input: 'sample1', 'Assay 1 parameter value 1': 'value extract 1', 'other material characteristic 1': 'characteristics value extract 1' })
    FactoryBot.create(:sample, sample_type: assay_type, contributor: person, project_ids: [project.id], data: { 'Extract Name': 'Extract 2', 'Protocol Assay 1': 'method 1', Input: 'sample2', 'Assay 1 parameter value 1': 'value extract 2', 'other material characteristic 1': 'characteristics value extract 2' })

    study = FactoryBot.create(:study, investigation: investigation, contributor: person, sample_types: [source_type, sample_collection_type])

    assay_stream = FactoryBot.create(:assay_stream, study: study, contributor: person, position: 0)
    assay = FactoryBot.create(:assay, study: , contributor: person, assay_class: AssayClass.experimental, assay_stream: assay_stream, assay_type_uri: nil, sample_type: assay_type)
    title_attribute = assay.sample_type.sample_attributes.detect(&:is_title)

    login_as person.user
    patch :update, params: { id: assay, isa_assay:
      { sample_type:
          { sample_attributes: [
            { id: title_attribute.id, title: 'New Extract Name' }
          ] }
      }
    }
    assert_response :redirect
    assert_enqueued_with(job: UpdateSampleMetadataJob)
    assay.sample_type.reload
    assert_equal assay.sample_type.sample_attributes.detect(&:is_title).title, 'New Extract Name'
    assert assay.sample_type.locked?

  end

  test 'should not update sample type linkage if it is the first assay in the assay stream' do
    person = FactoryBot.create(:person)
    project = person.projects.first
    login_as(person)
    investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true, contributor: person)
    study = FactoryBot.create(:isa_json_compliant_study, investigation:, contributor: person)

    # Create the assay streams
    first_assay_stream = FactoryBot.create(:assay_stream, contributor: person, study:)
    second_assay_stream = FactoryBot.create(:assay_stream, contributor: person, study:)
    assert first_assay_stream.is_assay_stream?
    assert second_assay_stream.is_assay_stream?
    assert_equal first_assay_stream.previous_linked_sample_type, study.sample_types.second
    assert_equal second_assay_stream.previous_linked_sample_type, study.sample_types.second
    assert_nil first_assay_stream.next_linked_child_assay
    assert_nil second_assay_stream.next_linked_child_assay

    # Create an assay at the begin of the first stream
    first_assay_sample_type = FactoryBot.create(:isa_assay_material_sample_type,
                                                linked_sample_type: study.sample_types.second,
                                                projects: [project],
                                                contributor: person)
    first_assay = FactoryBot.create(:assay, title: 'First Assay in the second assay stream', contributor: person, study:, sample_type: first_assay_sample_type, assay_stream: second_assay_stream)

    # Create an assay at the end of the first stream
    second_assay_sample_type = FactoryBot.create(:isa_assay_data_file_sample_type,
                                                 linked_sample_type: first_assay_sample_type,
                                                 projects: [project],
                                                 contributor: person)
    second_assay = FactoryBot.create(:assay, title: 'Second Assay in the second assay stream', contributor: person, study:, sample_type: second_assay_sample_type, assay_stream: second_assay_stream)

    refute first_assay.is_assay_stream?
    refute second_assay.is_assay_stream?
    assert_equal first_assay.previous_linked_sample_type, second_assay_stream.previous_linked_sample_type, study.sample_types.second
    assert_nil second_assay.next_linked_child_assay

    # Post first assay in first assay stream, which is the third assay in total
    policy_attributes = { access_type: Policy::ACCESSIBLE,
                          permissions_attributes: project_permissions([projects.first], Policy::ACCESSIBLE) }

    third_assay_attributes = { title: 'First assay of the first assay stream',
                               study_id: study.id,
                               assay_class_id: AssayClass.experimental.id,
                               creator_ids: [person.id],
                               policy_attributes:,
                               assay_stream_id: first_assay_stream.id }

    third_assay_sample_type_attributes = { title: "Third Assay Sample type",
                                           project_ids: [project.id],
                                           sample_attributes_attributes: {
                                             '0': {
                                               pos: '1', title: 'a string', required: '1', is_title: '1',
                                               sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id, _destroy: '0',
                                               isa_tag_id: FactoryBot.create(:other_material_isa_tag).id
                                             },
                                             '1': {
                                               pos: '2', title: 'protocol', required: '1', is_title: '0',
                                               sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id,
                                               isa_tag_id: FactoryBot.create(:protocol_isa_tag).id, _destroy: '0'
                                             },
                                             '2': {
                                               pos: '3', title: 'Input sample', required: '1',
                                               sample_attribute_type_id: FactoryBot.create(:sample_multi_sample_attribute_type).id,
                                               linked_sample_type_id: study.sample_types.second.id, _destroy: '0'
                                             },
                                             '3': {
                                               pos: '4', title: 'Some material characteristic', required: '1',
                                               sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id,
                                               _destroy: '0',
                                               isa_tag_id: FactoryBot.create(:other_material_characteristic_isa_tag).id
                                             }
                                           }
    }

    third_isa_assay_attributes = { assay: third_assay_attributes,
                                   input_sample_type_id: study.sample_types.second.id,
                                   sample_type: third_assay_sample_type_attributes }

    # Test if resources are created
    assert_difference "Assay.count", 1 do
      assert_difference "SampleType.count", 1 do
        post :create, params: { isa_assay: third_isa_assay_attributes }
      end
    end

    isa_assay = assigns(:isa_assay)

    # The created assay sample type should be linked to the seconde study sample type
    assert_equal isa_assay.assay.previous_linked_sample_type, study.sample_types.second

    # The first assay sample type in the first assay stream should still be linked to the seconde study sample type
    first_assay_sample_type.reload
    assert_equal first_assay_sample_type.previous_linked_sample_type, study.sample_types.second
  end

  test 'should auto-populate the sample type title and description' do
    person = FactoryBot.create(:person)
    login_as(person)
    projects = person.projects
    investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true, contributor: person)
    study = FactoryBot.create(:isa_json_compliant_study, investigation:, contributor: person)
    assay_stream = FactoryBot.create(:assay_stream, contributor: person, study:)
    material_assay_template = FactoryBot.create(:isa_assay_material_template)
    data_file_assay_template = FactoryBot.create(:isa_assay_data_file_template)

    policy_attributes = { access_type: Policy::ACCESSIBLE,
                          permissions_attributes: project_permissions([projects.first], Policy::ACCESSIBLE) }

    # Create an assay with material outputs
    material_assay_sample_type_attributes = create_material_assay_sample_type_attributes(projects.first, study.sample_types.second.id, material_assay_template.id)
    material_assay_sample_type_attributes.delete(:title)

    material_assay_attributes = { title: 'Material Assay',
                                  study_id: study.id,
                                  assay_class_id: AssayClass.experimental.id,
                                  creator_ids: [person.id],
                                  policy_attributes:,
                                  assay_stream_id: assay_stream.id }

    material_isa_assay_attributes = { assay: material_assay_attributes,
                             input_sample_type_id: study.sample_types.second.id,
                             sample_type: material_assay_sample_type_attributes }

    assert_difference('Assay.count', 1) do
      assert_difference('SampleType.count', 1) do
        post :create, params: { isa_assay: material_isa_assay_attributes }
      end
    end

    assert_response :redirect
    material_isa_assay = assigns(:isa_assay)

    assert_equal material_isa_assay.sample_type.title, "#{material_isa_assay.assay.title} - 'Assay - Material' Sample Type"
    assert_equal material_isa_assay.sample_type.description, "'Assay - Material' Sample Type linked to Assay '#{material_isa_assay.assay.title}'."

    # Create an assay with data file outputs
    data_file_assay_sample_type_attributes = create_data_file_assay_sample_type_attributes(projects.first, material_isa_assay.sample_type.id, data_file_assay_template.id)
    data_file_assay_sample_type_attributes.delete(:title)

    data_file_assay_attributes = { title: 'Material Assay',
                                  study_id: study.id,
                                  assay_class_id: AssayClass.experimental.id,
                                  creator_ids: [person.id],
                                  policy_attributes:,
                                  assay_stream_id: assay_stream.id }

    data_file_isa_assay_attributes = { assay: data_file_assay_attributes,
                             input_sample_type_id: study.sample_types.second.id,
                             sample_type: data_file_assay_sample_type_attributes }

    assert_difference('Assay.count', 1) do
      assert_difference('SampleType.count', 1) do
        post :create, params: { isa_assay: data_file_isa_assay_attributes }
      end
    end

    assert_response :redirect
    data_file_isa_assay = assigns(:isa_assay)

    assert_equal data_file_isa_assay.sample_type.title, "#{data_file_isa_assay.assay.title} - 'Assay - Data file' Sample Type"
    assert_equal data_file_isa_assay.sample_type.description, "'Assay - Data file' Sample Type linked to Assay '#{data_file_isa_assay.assay.title}'."

  end

  test 'Should not run sample metadata updating callbacks and tasks when updating assay streams' do
    person = FactoryBot.create(:person)
    login_as(person)
    project = person.projects.first

    investigation = FactoryBot.create(:investigation, projects: [project], contributor: person)
    study = FactoryBot.create(:study, contributor: person, investigation: investigation)
    assay_stream = FactoryBot.create(:assay_stream, contributor: person, study: study, title: 'my asay stream', description: 'Original assay stream')

    assert assay_stream.can_edit?

    parameters = {
      assay: {
        title: 'my assay stream',
        description: 'Updated assay stream'
      }
    }

    assert_no_enqueued_jobs(only: UpdateSampleMetadataJob) do
      patch :update, params: { id: assay_stream.id, isa_assay: parameters }
    end

    assert_response :redirect
    assay_stream.reload
    assert_equal assay_stream.title, 'my assay stream'
    assert_equal assay_stream.description, 'Updated assay stream'
  end

  private

  def create_material_assay_sample_type_attributes(project, linked_sample_type_id='self', parent_template_id=nil, counter=1)
    { title: "Intermediate Assay Sample type #{counter}",
      project_ids: [project.id],
      template_id: parent_template_id,
      sample_attributes_attributes: {
        '0': {
          pos: '1', title: 'a string', required: '1', is_title: '1',
          sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id, _destroy: '0',
          isa_tag_id: FactoryBot.create(:other_material_isa_tag).id
        },
        '1': {
          pos: '2', title: 'protocol', required: '1', is_title: '0',
          sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id,
          isa_tag_id: FactoryBot.create(:protocol_isa_tag).id, _destroy: '0'
        },
        '2': {
          pos: '3', title: 'Input sample', required: '1',
          sample_attribute_type_id: FactoryBot.create(:sample_multi_sample_attribute_type).id,
          linked_sample_type_id: linked_sample_type_id, _destroy: '0'
        },
        '3': {
          pos: '4', title: 'Some material characteristic', required: '1',
          sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id,
          _destroy: '0',
          isa_tag_id: FactoryBot.create(:other_material_characteristic_isa_tag).id
        }
      }
    }
  end

  def create_data_file_assay_sample_type_attributes(project, linked_sample_type_id='self', parent_template_id=nil, counter=1)
    { title: "Data File Assay Sample type #{counter}",
      project_ids: [project.id],
      template_id: parent_template_id,
      sample_attributes_attributes: {
        '0': {
          pos: '1', title: 'Data File name', required: '1', is_title: '1',
          sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id, _destroy: '0',
          isa_tag_id: FactoryBot.create(:data_file_isa_tag).id
        },
        '1': {
          pos: '2', title: 'Protocol', required: '1', is_title: '0',
          sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id,
          isa_tag_id: FactoryBot.create(:protocol_isa_tag).id, _destroy: '0'
        },
        '2': {
          pos: '3', title: 'Input sample', required: '1',
          sample_attribute_type_id: FactoryBot.create(:sample_multi_sample_attribute_type).id,
          linked_sample_type_id: linked_sample_type_id, _destroy: '0'
        },
        '3': {
          pos: '4', title: 'Some Data File comment', required: '1',
          sample_attribute_type_id: FactoryBot.create(:string_sample_attribute_type).id,
          _destroy: '0',
          isa_tag_id: FactoryBot.create(:data_file_comment_isa_tag).id
        }
      }
    }
  end

end
