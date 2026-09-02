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
    @investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true, policy: FactoryBot.create(:public_policy),
                                      projects: [@project], contributor: @member)
    @study = FactoryBot.create(:isa_json_compliant_study, investigation: @investigation,
                              policy: FactoryBot.create(:public_policy), contributor: @member)
    @source_sample_type = @study.sample_types.first
    @sample_collection_sample_type = @study.sample_types.second

    @assay_stream = FactoryBot.create(:assay_stream, study: @study, policy: FactoryBot.create(:public_policy), contributor: @member)
    @assay = FactoryBot.create(:isa_json_compliant_material_assay, assay_stream: @assay_stream, study: @study,
                              linked_sample_type: @sample_collection_sample_type, contributor: @member,
                              policy: FactoryBot.create(:public_policy), position: 0)
    @material_assay_sample_type = @assay.sample_type

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
    # Another user creates an investigation under the same project
    other_user = FactoryBot.create(:user)
    FactoryBot.create(:investigation, contributor: other_user.person, policy: FactoryBot.create(:private_policy),
                                projects: [@project])

    # @member visualises the treeview of the project
    controller = TreeviewBuilder.new @project, nil
    result = controller.send(:build_tree_data)

    json = JSON.parse(result)[0]

    # @member sees his / her investigation but not the one made by other_user
    assert_equal @investigation.title, json['children'][0]['text']
    assert_equal 'hidden item', json['children'][1]['text']
  end

  test 'should return dynamic table data to an unauthenticated user when ISA-study is public' do
    FactoryBot.create(:isa_source, sample_type: @source_sample_type, contributor: @member, policy: FactoryBot.create(:public_policy))

    logout

    get :dynamic_table_data, params: { id: @project.id, study_id: @study.id }

    assert_response :success
    json = JSON.parse(response.body)
    refute json.key?('error')
    assert_equal 1, json['data'].length
    refute json['data'].flatten.include?('#HIDDEN')
  end

  test 'should return dynamic table data when ISA-assay is public' do
    source = FactoryBot.create(:isa_source, sample_type: @source_sample_type, policy: FactoryBot.create(:public_policy))
    sample = FactoryBot.create(:isa_sample, sample_type: @sample_collection_sample_type, linked_samples: [source],
                               policy: FactoryBot.create(:public_policy))
    FactoryBot.create(:isa_material_assay_sample, sample_type: @material_assay_sample_type, linked_samples: [sample],
                      policy: FactoryBot.create(:public_policy))

    logout

    get :dynamic_table_data, params: { id: @project.id, study_id: @study.id, assay_id: @assay.id }

    assert_response :success
    json = JSON.parse(response.body)
    refute json.key?('error')
    assert_equal 1, json['data'].length
    refute json['data'].flatten.include?('#HIDDEN')
  end

  test 'dynamic table data should not have unauthorized items' do
    first_source = FactoryBot.create(:isa_source, contributor: @member, sample_type: @source_sample_type, policy: FactoryBot.create(:private_policy))
    _second_source = FactoryBot.create(:isa_source, contributor: @member, sample_type: @source_sample_type, policy: FactoryBot.create(:private_policy))
    sample = FactoryBot.create(:isa_sample, contributor: @member, sample_type: @sample_collection_sample_type, linked_samples: [first_source],
                               policy: FactoryBot.create(:private_policy))
    FactoryBot.create(:isa_material_assay_sample, contributor: @member, sample_type: @material_assay_sample_type, linked_samples: [sample],
                      policy: FactoryBot.create(:private_policy))

    logout

    # Since Study and Assay samples are private, nothing should be returned
    get :dynamic_table_data, params: { id: @project.id, study_id: @study.id, assay_id: @assay.id }

    assert_response :success
    json = JSON.parse(response.body)
    refute json.key?('error')
    assert_equal 1, json['data'].length
    assert json['data'].flatten.all? { |value| value == '#HIDDEN' }

    get :dynamic_table_data, params: { id: @project.id, study_id: @study.id }

    assert_response :success
    json = JSON.parse(response.body)
    refute json.key?('error')
    assert_equal 2, json['data'].length
    assert json['data'].flatten.all? { |value| value == '#HIDDEN' || value.blank? }
  end

  test 'dynamic table data should not contain unauthorized samples' do
    other_person = FactoryBot.create(:person)

    visible_source = FactoryBot.create(:isa_source, title: 'visible source', sample_type: @source_sample_type,
                                       contributor: @member, policy: FactoryBot.create(:public_policy))
    FactoryBot.create(:isa_source, title: 'hidden source', sample_type: @source_sample_type,
                      contributor: other_person, policy: FactoryBot.create(:private_policy))

    logout

    get :dynamic_table_data, params: { id: @project.id, study_id: @study.id }

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
    source = FactoryBot.create(:isa_source, sample_type: @source_sample_type, policy: FactoryBot.create(:public_policy))
    sample = FactoryBot.create(:isa_sample, sample_type: @sample_collection_sample_type, linked_samples: [source],
                      policy: FactoryBot.create(:public_policy))
    private_assay = FactoryBot.create(:isa_json_compliant_material_assay, study: @study, assay_stream: @assay.assay_stream, linked_sample_type: @sample_collection_sample_type, contributor: @member, policy: FactoryBot.create(:private_policy))
    private_assay_sample_type = private_assay.sample_type
    FactoryBot.create(:isa_material_assay_sample, sample_type: private_assay_sample_type, linked_samples: [sample],
                      policy: FactoryBot.create(:public_policy))

    logout

    get :dynamic_table_data, params: { id: @project.id, study_id: @study.id, assay_id: private_assay.id }

    assert_response :success
    json = JSON.parse(response.body)
    refute json.key?('error')
    # The assay itself is unauthorized, so no data should be returned, even though the parent study is public.
    assert_equal [], json['data']
  end

  test 'dynamic table data for a public assay is unaffected by an unauthorized parent study' do
    source = FactoryBot.create(:isa_source, sample_type: @source_sample_type, policy: FactoryBot.create(:public_policy))
    sample = FactoryBot.create(:isa_sample, sample_type: @sample_collection_sample_type, linked_samples: [source],
                               policy: FactoryBot.create(:public_policy))
    FactoryBot.create(:isa_material_assay_sample, sample_type: @material_assay_sample_type, linked_samples: [sample],
                      policy: FactoryBot.create(:public_policy))

    @study.update!(policy: FactoryBot.create(:private_policy))
    logout

    get :dynamic_table_data, params: { id: @project.id, study_id: @study.id, assay_id: @assay.id }

    assert_response :success
    json = JSON.parse(response.body)
    refute json.key?('error')
    # The assay's own policy is public and assay-level aggregation doesn't depend on the parent study,
    # so its data is still returned even though the study itself is private.
    assert_equal 1, json['data'].length
    refute json['data'].flatten.include?('#HIDDEN')
  end

  test 'should return dynamic table data for a public sample type' do
    FactoryBot.create(:isa_source, contributor: @member, sample_type: @source_sample_type, policy: FactoryBot.create(:public_policy))

    logout

    get :dynamic_table_data, params: { id: @project.id, sample_type_id: @source_sample_type.id }

    assert_response :success
    json = JSON.parse(response.body)
    refute json.key?('error')
    assert_equal 1, json['data'].length
  end

  test 'dynamic table data should not error out for an unauthorized sample type' do
    private_study = FactoryBot.create(:isa_json_compliant_study, contributor: @member, investigation: @investigation, policy: FactoryBot.create(:private_policy))
    private_source_sample_type = private_study.sample_types.first
    FactoryBot.create(:isa_source, sample_type: private_source_sample_type, projects: [@project], policy: FactoryBot.create(:private_policy), contributor: @member)

    # Authorized person sees the source with its metadata
    get :dynamic_table_data, params: { id: @project.id, sample_type_id: private_source_sample_type.id }

    assert_response :success
    json = JSON.parse(response.body)
    refute json.key?('error')
    assert_equal 1, json['data'].size
    refute json['data'].flatten.include?('#HIDDEN')

    # Unauthenticated user does not get to see any sources
    logout

    get :dynamic_table_data, params: { id: @project.id, sample_type_id: private_source_sample_type.id }

    assert_response :success
    json = JSON.parse(response.body)
    refute json.key?('error')
    assert_equal [], json['data']

    # Unauthorized user does not get to see any sources
    unauthorized_person = FactoryBot.create(:person)

    login_as(unauthorized_person)
    get :dynamic_table_data, params: { id: @project.id, sample_type_id: private_source_sample_type.id }

    assert_response :success
    json = JSON.parse(response.body)
    refute json.key?('error')
    assert_equal [], json['data']
  end

  test 'dynamic table data should not return a sample type belonging to a different project' do
    other_project = FactoryBot.create(:project)
    FactoryBot.create(:isa_source, sample_type: @source_sample_type, policy: FactoryBot.create(:public_policy))

    get :dynamic_table_data, params: { id: other_project.id, sample_type_id: @source_sample_type.id }

    assert_response :success
    json = JSON.parse(response.body)
    refute json.key?('error')
    assert_equal [], json['data']
  end

  test 'dynamic table data should not return a study belonging to a different project' do
    other_project = FactoryBot.create(:project)
    other_investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true, policy: FactoryBot.create(:public_policy),
                                      projects: [other_project])
    other_study = FactoryBot.create(:isa_json_compliant_study, investigation: other_investigation, policy: FactoryBot.create(:public_policy))
    FactoryBot.create(:isa_source, sample_type: other_study.sample_types.first, policy: FactoryBot.create(:public_policy))

    get :dynamic_table_data, params: { id: @project.id, study_id: other_study.id }

    assert_response :success
    json = JSON.parse(response.body)
    refute json.key?('error')
    assert_equal [], json['data']
  end

  test 'dynamic table data should not return an assay that does not belong to the requested study' do
    other_investigation = FactoryBot.create(:investigation, is_isa_json_compliant: true, policy: FactoryBot.create(:public_policy),
                                            projects: [@project])
    other_study = FactoryBot.create(:isa_json_compliant_study, investigation: other_investigation, policy: FactoryBot.create(:public_policy))
    other_study.sample_types.each { |st| st.update!(projects: [@project]) }

    other_source_sample_type = other_study.sample_types.first
    other_sample_collection_sample_type = other_study.sample_types.second

    other_source = FactoryBot.create(:isa_source, sample_type: other_source_sample_type, policy: FactoryBot.create(:public_policy))
    other_sample = FactoryBot.create(:isa_sample, sample_type: other_sample_collection_sample_type, linked_samples: [other_source],
                                     policy: FactoryBot.create(:public_policy))

    source = FactoryBot.create(:isa_source, sample_type: @source_sample_type, policy: FactoryBot.create(:public_policy))
    sample = FactoryBot.create(:isa_sample, sample_type: @sample_collection_sample_type, linked_samples: [source],
                               policy: FactoryBot.create(:public_policy))

    FactoryBot.create(:isa_material_assay_sample, sample_type: @material_assay_sample_type, linked_samples: [sample],
                      policy: FactoryBot.create(:public_policy))

    # The assay belongs to `study`, not the requested `other_study`, so it should be rejected
    # even though both are public and in the same project.
    get :dynamic_table_data, params: { id: @project.id, study_id: other_study.id, assay_id: @assay.id }

    assert_response :success
    json = JSON.parse(response.body)
    refute json.key?('error')
    assert_equal [], json['data']
  end
end
