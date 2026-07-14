require 'test_helper'

class SinglePagesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  def setup
    @instance_name = Seek::Config.instance_name
    @member = FactoryBot.create :person
    @project = @member.projects.first
    login_as @member
    @initial_isa_json_compliance_enabled = Seek::Config.isa_json_compliance_enabled
    Seek::Config.isa_json_compliance_enabled = true
  end

  def teardown
    Seek::Config.isa_json_compliance_enabled = @initial_isa_json_compliance_enabled
  end

  test 'should show' do
    with_config_value(:project_single_page_enabled, true) do
      get :show, params: { id: @project.id }
      assert_response :success
    end
  end

  test 'should hide inaccessible items in treeview' do
    FactoryBot.create(:investigation, contributor: @member.person, policy: FactoryBot.create(:private_policy),
                      projects: [@project])

    login_as(FactoryBot.create(:user))
    inv_two = FactoryBot.create(:investigation, contributor: User.current_user.person, policy: FactoryBot.create(:private_policy),
                                projects: [@project])

    controller = TreeviewBuilder.new @project, nil
    result = controller.send(:build_tree_data)

    json = JSON.parse(result)[0]

    assert_equal 'hidden item', json['children'][0]['text']
    assert_equal inv_two.title, json['children'][1]['text']
  end

  test 'should return dynamic table data when ISA-study is public' do
    investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true, policy: FactoryBot.create(:public_policy))
    study = FactoryBot.create(:isa_json_compliant_study, investigation: investigation,
                              policy: FactoryBot.create(:public_policy))
    source_sample_type = study.sample_types.first
    FactoryBot.create(:isa_source, sample_type: source_sample_type, policy: FactoryBot.create(:public_policy))

    logout

    get :dynamic_table_data, params: { id: @project.id, study_id: study.id }

    assert_response :success
    json = JSON.parse(response.body)
    refute json.key?('error')
    assert_equal 1, json['data'].length
    refute json['data'].flatten.include?('#HIDDEN')
  end

  test 'should return dynamic table data when ISA-assay is public' do
    investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true, policy: FactoryBot.create(:public_policy))
    study = FactoryBot.create(:isa_json_compliant_study, investigation: investigation,
                              policy: FactoryBot.create(:public_policy))
    source_sample_type = study.sample_types.first
    sample_collection_sample_type = study.sample_types.second

    assay_stream = FactoryBot.create(:assay_stream, study: study, policy: FactoryBot.create(:public_policy))
    assay = FactoryBot.create(:isa_json_compliant_material_assay, assay_stream: assay_stream, study: study,
                              linked_sample_type: sample_collection_sample_type,
                              policy: FactoryBot.create(:public_policy), position: 0)
    material_assay_sample_type = assay.sample_type
    source = FactoryBot.create(:isa_source, sample_type: source_sample_type, policy: FactoryBot.create(:public_policy))
    sample = FactoryBot.create(:isa_sample, sample_type: sample_collection_sample_type, linked_samples: [source],
                               policy: FactoryBot.create(:public_policy))
    FactoryBot.create(:isa_material_assay_sample, sample_type: material_assay_sample_type, linked_samples: [sample],
                      policy: FactoryBot.create(:public_policy))

    logout

    get :dynamic_table_data, params: { id: @project.id, study_id: study.id, assay_id: assay.id }

    assert_response :success
    json = JSON.parse(response.body)
    refute json.key?('error')
    assert_equal 1, json['data'].length
    refute json['data'].flatten.include?('#HIDDEN')
  end

  test 'dynamic table data should not have unauthorized items' do
    investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true, policy: FactoryBot.create(:private_policy))
    study = FactoryBot.create(:isa_json_compliant_study, investigation: investigation,
                              policy: FactoryBot.create(:private_policy))
    source_sample_type = study.sample_types.first
    sample_collection_sample_type = study.sample_types.second

    assay_stream = FactoryBot.create(:assay_stream, study: study, policy: FactoryBot.create(:private_policy))
    assay = FactoryBot.create(:isa_json_compliant_material_assay, assay_stream: assay_stream, study: study,
                              linked_sample_type: sample_collection_sample_type,
                              policy: FactoryBot.create(:private_policy), position: 0)
    material_assay_sample_type = assay.sample_type
    source = FactoryBot.create(:isa_source, sample_type: source_sample_type, policy: FactoryBot.create(:private_policy))
    sample = FactoryBot.create(:isa_sample, sample_type: sample_collection_sample_type, linked_samples: [source],
                               policy: FactoryBot.create(:private_policy))
    FactoryBot.create(:isa_material_assay_sample, sample_type: material_assay_sample_type, linked_samples: [sample],
                      policy: FactoryBot.create(:private_policy))

    logout

    get :dynamic_table_data, params: { id: @project.id, study_id: study.id }

    assert_response :success
    json = JSON.parse(response.body)
    refute json.key?('error')
    # Since Study and Assay are unauthorized, nothing should be returned
    assert_equal 0, json['data'].length
    assert json['data'].flatten.all? { |value| value == '#HIDDEN' }
  end

  test 'dynamic table data should not contain unauthorized samples' do
    other_person = FactoryBot.create(:person)

    investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true, policy: FactoryBot.create(:public_policy))
    study = FactoryBot.create(:isa_json_compliant_study, investigation: investigation,
                              policy: FactoryBot.create(:public_policy))
    source_sample_type = study.sample_types.first

    visible_source = FactoryBot.create(:isa_source, title: 'visible source', sample_type: source_sample_type,
                                       contributor: @member, policy: FactoryBot.create(:public_policy))
    FactoryBot.create(:isa_source, title: 'hidden source', sample_type: source_sample_type,
                      contributor: other_person, policy: FactoryBot.create(:private_policy))

    logout

    get :dynamic_table_data, params: { id: @project.id, study_id: study.id }

    assert_response :success
    json = JSON.parse(response.body)
    refute json.key?('error')
    assert_equal 2, json['data'].length

    visible_row = json['data'].detect { |row| row.include?(visible_source.id) }
    hidden_row = json['data'].detect { |row| row != visible_row }

    refute_nil visible_row
    assert visible_row.none? { |value| value == '#HIDDEN' }
    assert hidden_row.all? { |value| value == '#HIDDEN' || value.blank? }
  end

  test 'dynamic table data should return an empty array when the requested assay is unauthorized' do
    investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true, policy: FactoryBot.create(:public_policy))
    study = FactoryBot.create(:isa_json_compliant_study, investigation: investigation, policy: FactoryBot.create(:public_policy))
    source_sample_type = study.sample_types.first
    sample_collection_sample_type = study.sample_types.second

    assay_stream = FactoryBot.create(:assay_stream, study: study, policy: FactoryBot.create(:private_policy))
    assay = FactoryBot.create(:isa_json_compliant_material_assay, assay_stream: assay_stream, study: study,
                              linked_sample_type: sample_collection_sample_type,
                              policy: FactoryBot.create(:private_policy), position: 0)
    material_assay_sample_type = assay.sample_type

    source = FactoryBot.create(:isa_source, sample_type: source_sample_type, policy: FactoryBot.create(:public_policy))
    sample = FactoryBot.create(:isa_sample, sample_type: sample_collection_sample_type, linked_samples: [source],
                      policy: FactoryBot.create(:public_policy))
    FactoryBot.create(:isa_material_assay_sample, sample_type: material_assay_sample_type, linked_samples: [sample],
                      policy: FactoryBot.create(:public_policy))

    logout

    get :dynamic_table_data, params: { id: @project.id, study_id: study.id, assay_id: assay.id }

    assert_response :success
    json = JSON.parse(response.body)
    refute json.key?('error')
    # The assay itself is unauthorized, so no data should be returned, even though the parent study is public.
    assert_equal [], json['data']
  end

  test 'dynamic table data for a public assay is unaffected by an unauthorized parent study' do
    investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true, policy: FactoryBot.create(:private_policy))
    study = FactoryBot.create(:isa_json_compliant_study, investigation: investigation, policy: FactoryBot.create(:private_policy))
    source_sample_type = study.sample_types.first
    sample_collection_sample_type = study.sample_types.second

    assay_stream = FactoryBot.create(:assay_stream, study: study, policy: FactoryBot.create(:public_policy))
    assay = FactoryBot.create(:isa_json_compliant_material_assay, assay_stream: assay_stream, study: study,
                              linked_sample_type: sample_collection_sample_type,
                              policy: FactoryBot.create(:public_policy), position: 0)
    source = FactoryBot.create(:isa_source, sample_type: source_sample_type, policy: FactoryBot.create(:public_policy))
    sample = FactoryBot.create(:isa_sample, sample_type: sample_collection_sample_type, linked_samples: [source],
                               policy: FactoryBot.create(:public_policy))
    FactoryBot.create(:isa_material_assay_sample, sample_type: assay.sample_type, linked_samples: [sample],
                      policy: FactoryBot.create(:public_policy))

    logout

    get :dynamic_table_data, params: { id: @project.id, study_id: study.id, assay_id: assay.id }

    assert_response :success
    json = JSON.parse(response.body)
    refute json.key?('error')
    # The assay's own policy is public and assay-level aggregation doesn't depend on the parent study,
    # so its data is still returned even though the study itself is private.
    assert_equal 1, json['data'].length
    refute json['data'].flatten.include?('#HIDDEN')
  end

  test 'should return dynamic table data for a public sample type' do
    sample_type = FactoryBot.create(:isa_source_sample_type, policy: FactoryBot.create(:public_policy))
    FactoryBot.create(:isa_source, sample_type: sample_type, policy: FactoryBot.create(:public_policy))

    logout

    get :dynamic_table_data, params: { id: @project.id, sample_type_id: sample_type.id }

    assert_response :success
    json = JSON.parse(response.body)
    refute json.key?('error')
    assert_equal 1, json['data'].length
  end

  test 'dynamic table data should not error out for an unauthorized sample type' do
    sample_type = FactoryBot.create(:isa_source_sample_type, policy: FactoryBot.create(:private_policy))
    FactoryBot.create(:isa_source, sample_type: sample_type, policy: FactoryBot.create(:private_policy))

    logout

    get :dynamic_table_data, params: { id: @project.id, sample_type_id: sample_type.id }

    assert_response :success
    json = JSON.parse(response.body)
    refute json.key?('error')
    assert_equal [], json['data']
  end
end
