require 'test_helper'

class SampleTypesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  include SharingFormTestHelper

  setup do
    FactoryBot.create(:person) # to prevent person being first person and therefore admin
    @person = FactoryBot.create(:project_administrator)
    @project = @person.projects.first
    @project_ids = [@project.id]
    refute_nil @project
    login_as(@person)
    @sample_type = FactoryBot.create(:simple_sample_type, project_ids: @project_ids, contributor: @person)
    @string_type = FactoryBot.create(:string_sample_attribute_type)
    @int_type = FactoryBot.create(:integer_sample_attribute_type)
    @controlled_vocab_type = FactoryBot.create(:controlled_vocab_attribute_type)
  end

  teardown do
    Rails.cache.clear
  end

  test 'should get index' do
    get :index
    assert_response :success
    refute_nil assigns(:sample_types)
  end

  test 'should get new fair data station enabled shows tab' do
    with_config_value(:fair_data_station_enabled, true) do
      get :new
    end
    assert_response :success
    assert_select 'ul#sample-type-tabs' do
      assert_select 'li', count: 3
      assert_select 'li a[href=?]', '#from-fair-ds-ttl'
    end
  end

  test 'should get new fair data station disabled no tab' do
    with_config_value(:fair_data_station_enabled, false) do
      get :new
    end
    assert_response :success
    assert_select 'ul#sample-type-tabs' do
      assert_select 'li', count: 2
      assert_select 'li a[href=?]', '#from-fair-ds-ttl', count: 0
    end
  end

  test 'should create sample_type' do
    FactoryBot.create :annotation, attribute_name: 'sample_type_tag', source: @person.user,
                                   annotatable: FactoryBot.create(:simple_sample_type), value: 'golf'
    policy_attributes = projects_policy(Policy::VISIBLE, [@project], Policy::MANAGING)
    assert_enqueued_with(job: SampleTemplateGeneratorJob) do
      assert_enqueued_with(job: SampleTypeUpdateJob) do
        assert_difference('ActivityLog.count') do
          assert_difference('SampleType.count') do
            assert_difference('Task.where(key: "template_generation").count') do
              post :create, params: { sample_type: { title: 'Hello!',
                                                     project_ids: @project_ids,
                                                     description: 'The description!!',
                                                     sample_attributes_attributes: {
                                                       '0' => {
                                                         pos: '1', title: 'a string', required: '1', is_title: '1',
                                                         sample_attribute_type_id: @string_type.id, _destroy: '0'
                                                       },
                                                       '1' => {
                                                         pos: '2', title: 'a number', required: '1',
                                                         sample_attribute_type_id: @int_type.id, _destroy: '0',
                                                         description: 'this is a number',
                                                         pid: 'scheme:id'

                                                       }
                                                     },
                                                     tags: ['fish', 'golf'] },
                                      policy_attributes: policy_attributes}
            end
          end
        end
      end
    end

    refute_nil sample_type = assigns(:sample_type)
    assert_redirected_to sample_type_path(sample_type)

    assert_equal @person, sample_type.contributor
    assert_equal 'Hello!', sample_type.title
    assert_equal 'The description!!', sample_type.description
    assert_equal @project_ids.sort, sample_type.project_ids.sort
    assert_equal 2, sample_type.sample_attributes.size

    assert_equal 'a string', sample_type.sample_attributes.title_attributes.first.title
    assert_nil sample_type.sample_attributes.first.description
    assert_nil sample_type.sample_attributes.first.pid
    assert_equal 'a number', sample_type.sample_attributes.second.title
    assert_equal 'this is a number', sample_type.sample_attributes.second.description
    assert_equal 'scheme:id', sample_type.sample_attributes.second.pid

    assert_equal [@project], sample_type.projects
    refute sample_type.uploaded_template?
    assert_equal %w[fish golf], sample_type.tags.sort

    policy = sample_type.policy
    assert_equal Policy::VISIBLE, policy.access_type
    assert_equal 1, policy.permissions.count
    assert_equal Policy::MANAGING, policy.permissions.first.access_type
    assert_equal @project, policy.permissions.first.contributor

    assert_equal sample_type, ActivityLog.last.activity_loggable
    assert_equal 'create', ActivityLog.last.action
    assert_equal @person.user, ActivityLog.last.culprit
    assert_equal 'Hello!', ActivityLog.last.data
    assert_equal @person.projects.first, ActivityLog.last.referenced
    assert_equal 'sample_types', ActivityLog.last.controller_name
  end

  test 'should create with linked sample type' do
    linked_sample_type = FactoryBot.create(:sample_sample_attribute_type)
    assert_difference('SampleType.count') do
      post :create, params: { sample_type: { title: 'Hello!',
                                             project_ids: [@project.id],
                                             sample_attributes_attributes: {
                                               '0' => {
                                                 pos: '1', title: 'a string', required: '1', is_title: '1',
                                                 sample_attribute_type_id: @string_type.id, _destroy: '0'
                                               },
                                               '1' => {
                                                 pos: '2', title: 'a sample', required: '1',
                                                 sample_attribute_type_id: linked_sample_type.id, linked_sample_type_id: @sample_type.id, _destroy: '0'
                                               }
                                             } } }
    end
    refute_nil sample_type = assigns(:sample_type)
    assert_redirected_to sample_type_path(sample_type)
    assert_equal 2, sample_type.sample_attributes.size
    assert_equal 'a string', sample_type.sample_attributes.title_attributes.first.title
    assert_equal 'a sample', sample_type.sample_attributes.last.title
    assert sample_type.sample_attributes.last.sample_attribute_type.seek_sample?
    assert_equal @sample_type, sample_type.sample_attributes.last.linked_sample_type
  end

  test 'should create with linked sample type of itself' do
    linked_sample_type = FactoryBot.create(:sample_sample_attribute_type)
    assert_difference('SampleType.count') do
      post :create, params: { sample_type: { title: 'Hello!',
                                             project_ids: @project_ids,
                                             sample_attributes_attributes: {
                                               '0' => {
                                                 pos: '1', title: 'a string', required: '1', is_title: '1',
                                                 sample_attribute_type_id: @string_type.id, _destroy: '0'
                                               },
                                               '1' => {
                                                 pos: '2', title: 'a sample', required: '1',
                                                 sample_attribute_type_id: linked_sample_type.id, linked_sample_type_id: 'self', _destroy: '0'
                                               }
                                             } } }
    end
    refute_nil sample_type = assigns(:sample_type)
    assert_redirected_to sample_type_path(sample_type)
    assert_equal 2, sample_type.sample_attributes.size
    assert_equal 'a string', sample_type.sample_attributes.title_attributes.first.title
    assert_equal 'a sample', sample_type.sample_attributes.last.title
    assert sample_type.sample_attributes.last.sample_attribute_type.seek_sample?
    assert_equal sample_type, sample_type.sample_attributes.last.linked_sample_type
  end

  test 'create with creators' do
    creator = FactoryBot.create(:person)
    assert_difference('SampleType.count') do
      post :create, params: { sample_type: { title: 'Hello!',
                                             project_ids: @project_ids,
                                             description: 'The description!!',
                                             contributor: @person,
                                             creator_ids: [creator.id],
                                             other_creators: 'John Smith, Jane Smith',
                                             sample_attributes_attributes: {
                                               '0' => {
                                                 pos: '1', title: 'a string', required: '1', is_title: '1',
                                                 sample_attribute_type_id: @string_type.id, _destroy: '0'
                                               }
                                             } } }
    end
    type = assigns(:sample_type)
    assert_equal @person, type.contributor
    assert_equal [creator], type.creators
    assert_equal 'John Smith, Jane Smith', type.other_creators
  end

  test 'create with no creators' do
    assert_difference('SampleType.count') do
      post :create, params: { sample_type: { title: 'Hello!',
                                             project_ids: @project_ids,
                                             description: 'The description!!',
                                             creator_ids: [],
                                             other_creators: '',
                                             sample_attributes_attributes: {
                                               '0' => {
                                                 pos: '1', title: 'a string', required: '1', is_title: '1',
                                                 sample_attribute_type_id: @string_type.id, _destroy: '0'
                                               }
                                             } } }
    end
    type = assigns(:sample_type)
    assert_empty type.creators
    assert_empty type.other_creators
  end

  test 'should show sample_type' do
    assert_difference('ActivityLog.count', 1) do
      get :show, params: { id: @sample_type }
      assert_response :success
    end
    assert_equal @sample_type, ActivityLog.last.activity_loggable
    assert_equal 'show', ActivityLog.last.action
  end

  test 'should show main_content_right' do
    get :show, params: { id: @sample_type }
    assert_response :success
    assert_select 'div#author-box', true, 'Should show author box'
    assert_select 'p#usage_count', true, 'Should show activity box'
  end

  test 'should get edit' do
    get :edit, params: { id: @sample_type }
    assert_response :success
  end

  test 'should update sample_type' do
    sample_type = nil
    perform_enqueued_jobs(only: [SampleTemplateGeneratorJob, SampleTypeUpdateJob]) do
      sample_type = FactoryBot.create(:patient_sample_type, project_ids: @project_ids, contributor: @person)
    end
    assert_empty sample_type.tags

    golf = FactoryBot.create :tag, source: @person.user, annotatable: FactoryBot.create(:simple_sample_type),
                                   value: 'golf'

    sample_attributes_fields = sample_type.sample_attributes.map do |attribute|
      { pos: attribute.pos, title: attribute.title,
        required: (attribute.required ? '1' : '0'),
        sample_attribute_type_id: attribute.sample_attribute_type_id,
        _destroy: '0',
        id: attribute.id }
    end

    sample_attributes_fields[0][:is_title] = '0'
    sample_attributes_fields[1][:title] = 'hello'
    sample_attributes_fields[1][:is_title] = '1'
    sample_attributes_fields[2][:_destroy] = '1'
    sample_attributes_fields = Hash[sample_attributes_fields.each_with_index.map { |f, i| [i.to_s, f] }]

    assert sample_type.template_generation_task.reload.completed?

    policy_attributes = projects_policy(Policy::VISIBLE, [@project], Policy::MANAGING)

    assert_enqueued_with(job: SampleTemplateGeneratorJob, args: [sample_type]) do
      assert_enqueued_with(job: SampleTypeUpdateJob, args: [sample_type, true]) do
        assert_difference('ActivityLog.count', 1) do
          assert_difference('SampleAttribute.count', -1) do
            put :update, params: { id: sample_type, sample_type: { title: 'Hello!',
                                                                   sample_attributes_attributes: sample_attributes_fields,
                                                                   tags: ['fish',golf.value.text] },
                                   policy_attributes: policy_attributes }

            assert sample_type.template_generation_task.reload.pending?
          end
        end
      end
    end
    assert_redirected_to sample_type_path(assigns(:sample_type))

    sample_type.reload
    assert_equal sample_attributes_fields.keys.size - 1, sample_type.sample_attributes.size
    assert_includes sample_type.sample_attributes.map(&:title), 'hello'
    refute sample_type.sample_attributes[0].is_title?
    assert sample_type.sample_attributes[1].is_title?
    assert_equal %w[fish golf], sample_type.tags.sort

    policy = sample_type.policy
    assert_equal Policy::VISIBLE, policy.access_type
    assert_equal 1, policy.permissions.count
    assert_equal Policy::MANAGING, policy.permissions.first.access_type
    assert_equal @project, policy.permissions.first.contributor

    assert_equal sample_type, ActivityLog.last.activity_loggable
    assert_equal 'update', ActivityLog.last.action
  end

  test 'template download link visibility' do
    person = FactoryBot.create(:person)
    sample_type = SampleType.new title: 'testing download',
                                 uploaded_template: true,
                                 project_ids: person.projects.collect(&:id),
                                 contributor: person,
                                 content_blob: FactoryBot.create(:sample_type_template_content_blob),
                                 policy: FactoryBot.create(:downloadable_public_policy)
    sample_type.build_attributes_from_template
    disable_authorization_checks { sample_type.save! }
    assert sample_type.can_view?
    assert sample_type.can_download?
    get :show, params: { id: sample_type }
    assert_response :success
    assert_select 'a[href=?]',download_sample_type_content_blob_path(sample_type,sample_type.template), text:'Download'

    sample_type.policy = FactoryBot.create(:publicly_viewable_policy)
    disable_authorization_checks { sample_type.save! }
    assert sample_type.can_view?
    refute sample_type.can_download?
    get :show, params: { id: sample_type }
    assert_response :success
    assert_select 'a[href=?]',download_sample_type_content_blob_path(sample_type,sample_type.template), text:'Download', count:0
  end

  test 'update changing from a CV attribute' do
    sample_type = FactoryBot.create(:apples_controlled_vocab_sample_type, project_ids: @project_ids,
                                                                          contributor: @person)
    assert sample_type.valid?
    assert sample_type.can_edit?
    assert_equal 1, sample_type.sample_attributes.count
    attribute = sample_type.sample_attributes.first
    assert attribute.controlled_vocab?

    # change to String
    attribute_fields = [
      { pos: attribute.pos, title: 'A String',
        required: (attribute.required ? '1' : '0'),
        sample_attribute_type_id: @string_type.id,
        _destroy: '0',
        id: attribute.id }
    ]
    put :update, params: { id: sample_type, sample_type: { title: sample_type.title,
                                                           sample_attributes_attributes: attribute_fields } }
    assert_redirected_to sample_type_path(assigns(:sample_type))
    assert_nil flash[:error]
    sample_type = assigns(:sample_type)
    attribute = sample_type.sample_attributes.first
    refute attribute.controlled_vocab?
    assert_equal 'A String', attribute.title
    assert_equal @string_type, attribute.sample_attribute_type
  end

  test 'update changing from a Sample Type attribute' do
    sample_type = FactoryBot.create(:linked_sample_type, project_ids: @project_ids, contributor: @person)
    assert sample_type.valid?
    assert sample_type.can_edit?
    assert_equal 2, sample_type.sample_attributes.count
    attribute = sample_type.sample_attributes.last
    assert attribute.seek_sample?

    # this won't be changed
    first_attribute = sample_type.sample_attributes.first

    # change to String
    attribute_fields = [
      { pos: first_attribute.pos, title: first_attribute.title,
        required: (first_attribute.required ? '1' : '0'),
        sample_attribute_type_id: first_attribute.sample_attribute_type.id,
        _destroy: '0',
        id: first_attribute.id },
      { pos: attribute.pos, title: 'A String',
        required: (attribute.required ? '1' : '0'),
        sample_attribute_type_id: @string_type.id,
        _destroy: '0',
        id: attribute.id }
    ]
    put :update, params: { id: sample_type, sample_type: { title: sample_type.title,
                                                           sample_attributes_attributes: attribute_fields } }
    assert_redirected_to sample_type_path(assigns(:sample_type))
    assert_nil flash[:error]
    sample_type = assigns(:sample_type)
    attribute = sample_type.sample_attributes.last
    refute attribute.seek_sample?
    assert_equal 'A String', attribute.title
    assert_equal @string_type, attribute.sample_attribute_type
  end

  test 'other project member cannot update sample type' do
    sample_type = FactoryBot.create(:patient_sample_type, project_ids: [FactoryBot.create(:project).id],
                                                          title: 'should not change')
    refute sample_type.can_edit?

    assert_no_difference('ActivityLog.count') do
      put :update, params: { id: sample_type, sample_type: { title: 'Hello!' } }
    end

    assert_redirected_to sample_type_path(sample_type)
    refute_nil flash[:error]
    sample_type.reload
    assert_equal 'should not change', sample_type.title
  end

  test 'other project member cannot edit sample type' do
    sample_type = FactoryBot.create(:patient_sample_type, project_ids: [FactoryBot.create(:project).id])
    refute sample_type.can_edit?
    get :edit, params: { id: sample_type }
    assert_redirected_to sample_type_path(sample_type)
    refute_nil flash[:error]
  end

  test 'should destroy sample_type' do
    assert @sample_type.can_delete?

    assert_difference('ActivityLog.count') do
      assert_difference('SampleType.count', -1) do
        delete :destroy, params: { id: @sample_type }
      end
    end

    assert_redirected_to sample_types_path
  end

  test 'should not destroy sample_type if has existing samples' do
    FactoryBot.create_list(:sample, 3, sample_type: @sample_type)

    refute @sample_type.can_delete?

    assert_no_difference('ActivityLog.count') do
      assert_no_difference('SampleType.count') do
        delete :destroy, params: { id: @sample_type }
      end
    end

    assert_response :redirect
    assert_equal 'Cannot destroy this sample type - There are 3 samples using it.', flash[:error]
  end

  test 'create from template' do
    blob = { data: template_for_upload }

    policy_attributes = projects_policy(Policy::VISIBLE, [@project], Policy::MANAGING)

    assert_difference('ActivityLog.count', 1) do
      assert_difference('SampleType.count', 1) do
        assert_difference('ContentBlob.count', 1) do
          post :create_from_template,
               params: { sample_type: { title: 'Hello!', project_ids: @project_ids, tags: ['fish','golf'] },
                         content_blobs: [blob],
                         policy_attributes: policy_attributes }

        end
      end
    end

    sample_type = assigns(:sample_type)
    assert_redirected_to edit_sample_type_path(sample_type)
    assert_empty sample_type.errors
    assert sample_type.uploaded_template?

    policy = sample_type.policy
    assert_equal Policy::VISIBLE, policy.access_type
    assert_equal 1, policy.permissions.count
    assert_equal Policy::MANAGING, policy.permissions.first.access_type
    assert_equal @project, policy.permissions.first.contributor

    assert_equal %w[fish golf], sample_type.tags.sort

    assert_equal sample_type, ActivityLog.last.activity_loggable
    assert_equal 'create', ActivityLog.last.action
  end

  test 'create from template with some blank columns' do
    blob = { data: missing_columns_template_for_upload }

    assert_difference('SampleType.count', 1) do
      assert_difference('ContentBlob.count', 1) do
        post :create_from_template,
             params: { sample_type: { title: 'Hello!', project_ids: @project_ids }, content_blobs: [blob] }
      end
    end

    assert_redirected_to edit_sample_type_path(assigns(:sample_type))
    assert_empty assigns(:sample_type).errors
  end

  test "don't create from bad template" do
    blob = { data: bad_template_for_upload }

    assert_no_difference('ActivityLog.count') do
      assert_no_difference('SampleType.count') do
        assert_no_difference('ContentBlob.count') do
          post :create_from_template, params: { sample_type: { title: 'Hello!' }, content_blobs: [blob] }
        end
      end
    end

    assert_template :new
    refute_empty assigns(:sample_type).errors
  end

  test 'create from fair data station ttl' do
    blob = { data: fixture_file_upload('fair_data_station/seek-fair-data-station-test-case-irregular.ttl', 'text/turtle') }
    FactoryBot.create(:string_sample_attribute_type, title: 'String') unless SampleAttributeType.where(title: 'String').any?
    policy_attributes = projects_policy(Policy::VISIBLE, [@project], Policy::MANAGING)
    assert_difference('ActivityLog.count', 1) do
      assert_difference('SampleType.count', 1) do
        assert_no_difference('ContentBlob.count') do
          with_config_value(:fair_data_station_enabled, true) do
            post :create_from_fair_ds_ttl,
                 params: { sample_type: { title: 'Hello!', project_ids: @project_ids, tags: ['fish','golf'] },
                           content_blobs: [blob],
                           policy_attributes: policy_attributes}
          end
        end
      end
    end

    sample_type = assigns(:sample_type)
    assert_equal sample_type, ActivityLog.last.activity_loggable
    assert_equal 'create', ActivityLog.last.action
    assert_equal @person.user, ActivityLog.last.culprit
    assert_redirected_to edit_sample_type_path(sample_type)
    assert_empty sample_type.errors
    refute sample_type.uploaded_template?
    assert_equal @person, sample_type.contributor
    assert_equal 'Hello!', sample_type.title

    policy = sample_type.policy
    assert_equal Policy::VISIBLE, policy.access_type
    assert_equal 1, policy.permissions.count
    assert_equal Policy::MANAGING, policy.permissions.first.access_type
    assert_equal @project, policy.permissions.first.contributor

    assert_equal %w[fish golf], sample_type.tags.sort

    assert_equal sample_type, ActivityLog.last.activity_loggable
    assert_equal 'create', ActivityLog.last.action

    assert_equal 6, sample_type.sample_attributes.count

    expected = ["http://schema.org/name", "http://schema.org/description", "http://fairbydesign.nl/ontology/biosafety_level", "http://gbol.life/0.1/scientificName", "http://purl.uniprot.org/core/organism", "https://w3id.org/mixs/0000011"].sort
    assert_equal expected, sample_type.sample_attributes.collect(&:pid).sort

    expected = ["Title", "Description", "biosafety level", "scientific name", "ncbi taxonomy id", "collection date"].sort
    assert_equal expected, sample_type.sample_attributes.collect(&:title).sort
  end

  test 'create from fair data station ttl but exact match exists' do
    original_sample_type = FactoryBot.create(:fairdatastation_test_case_sample_type, contributor: @person)
    assert original_sample_type.can_view?
    blob = { data: fixture_file_upload('fair_data_station/seek-fair-data-station-test-case-irregular.ttl', 'text/turtle') }
    FactoryBot.create(:string_sample_attribute_type, title: 'String') unless SampleAttributeType.where(title: 'String').any?
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('SampleType.count') do
        assert_no_difference('ContentBlob.count') do
          with_config_value(:fair_data_station_enabled, true) do
            post :create_from_fair_ds_ttl,
                 params: { sample_type: { title: 'Hello!', project_ids: @project_ids }, content_blobs: [blob] }
          end
        end
      end
    end

    existing_sample_type = assigns(:existing_sample_type)
    assert_redirected_to sample_type_path(existing_sample_type)
    assert_equal 'An exact matching Sample type already exists, and now shown.', flash[:error]
  end

  test 'create from fair data station ttl ignore private exact match' do
    private_matching_sample_type = FactoryBot.create(:fairdatastation_test_case_sample_type, policy: FactoryBot.create(:private_policy))
    refute private_matching_sample_type.can_view?
    blob = { data: fixture_file_upload('fair_data_station/seek-fair-data-station-test-case-irregular.ttl', 'text/turtle') }
    FactoryBot.create(:string_sample_attribute_type, title: 'String') unless SampleAttributeType.where(title: 'String').any?
    assert_difference('ActivityLog.count', 1) do
      assert_difference('SampleType.count', 1) do
        assert_no_difference('ContentBlob.count') do
          with_config_value(:fair_data_station_enabled, true) do
            post :create_from_fair_ds_ttl,
                 params: { sample_type: { title: 'Hello!', project_ids: @project_ids }, content_blobs: [blob] }
          end
        end
      end
    end

    sample_type = assigns(:sample_type)
    assert_redirected_to edit_sample_type_path(sample_type)
    assert_empty sample_type.errors
    refute sample_type.uploaded_template?
    assert_equal @person, sample_type.contributor
    assert_equal 'Hello!', sample_type.title
  end

  test 'create from empty fair data station ttl' do
    blob = { data: fixture_file_upload('fair_data_station/empty.ttl', 'text/turtle') }

    assert_no_difference('ActivityLog.count') do
      assert_no_difference('SampleType.count') do
        assert_no_difference('ContentBlob.count') do
          with_config_value(:fair_data_station_enabled, true) do
            post :create_from_fair_ds_ttl,
                 params: { sample_type: { title: 'Hello!', project_ids: @project_ids }, content_blobs: [blob] }
          end
        end
      end
    end

    assert_template :new
    assert_equal 'No Sample type metadata could be found.', flash.now[:error]
    refute_empty assigns(:sample_type).errors
  end

  test 'cannot create from fair data station ttl if disabled' do
    blob = { data: fixture_file_upload('fair_data_station/seek-fair-data-station-test-case-irregular.ttl', 'text/turtle') }
    FactoryBot.create(:string_sample_attribute_type, title: 'String') unless SampleAttributeType.where(title: 'String').any?
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('SampleType.count') do
        assert_no_difference('ContentBlob.count') do
          with_config_value(:fair_data_station_enabled, false) do
            post :create_from_fair_ds_ttl,
                 params: { sample_type: { title: 'Hello!', project_ids: @project_ids }, content_blobs: [blob] }
          end
        end
      end
    end

    assert_redirected_to :root
    assert_equal 'Fair data station are disabled', flash[:error]
  end


  test 'should show link to sample type for linked attribute' do
    linked_type = FactoryBot.create(:linked_sample_type, project_ids: @project_ids, contributor: @person)
    linked_attribute = linked_type.sample_attributes.last

    assert linked_attribute.sample_attribute_type.seek_sample?

    sample_type_linked_to = linked_attribute.linked_sample_type
    refute_nil sample_type_linked_to

    get :show, params: { id: linked_type.id }

    assert_select 'table tbody' do
      assert_select 'td', text: /#{linked_attribute.sample_attribute_type.title}/i do
        assert_select 'a[href=?]', sample_type_path(sample_type_linked_to), text: sample_type_linked_to.title
      end
    end

  end

  test 'add attribute button' do
    type = FactoryBot.create(:simple_sample_type, project_ids: @project_ids, contributor: @person)
    assert_empty type.samples
    login_as(@person)
    get :edit, params: { id: type.id }
    assert_response :success
    assert_select 'a#add-attribute', count: 1
  end

  test 'cannot access when disabled' do
    sample_type = FactoryBot.create(:simple_sample_type)
    login_as(@person.user)
    with_config_value :samples_enabled, false do
      get :show, params: { id: sample_type.id }
      assert_redirected_to :root
      refute_nil flash[:error]

      clear_flash(:error)

      get :index
      assert_redirected_to :root
      refute_nil flash[:error]

      clear_flash(:error)

      get :new
      assert_redirected_to :root
      refute_nil flash[:error]
    end
  end

  test 'select' do
    get :select
    assert_response :success
  end

  test 'select without login' do
    logout
    get :select
    assert_redirected_to sample_types_path
    refute_nil flash[:error]
  end

  test 'filter for select authorization' do
    visible_type = FactoryBot.create(:simple_sample_type, policy: FactoryBot.create(:public_policy), contributor: FactoryBot.create(:person))
    hidden_type = FactoryBot.create(:simple_sample_type, policy: FactoryBot.create(:private_policy), contributor: FactoryBot.create(:person))
    assert visible_type.can_view?
    refute hidden_type.can_view?

    projects = (visible_type.projects | hidden_type.projects).collect(&:id)

    get :filter_for_select, params: { projects: projects }
    assert_response :success
    assert assigns(:sample_types)
    assert_includes assigns(:sample_types), visible_type
    refute_includes assigns(:sample_types), hidden_type

    assert_select 'div.list_items_container' do
      assert_select 'div.list_item_title a[href=?]', sample_type_path(visible_type), text:visible_type.title
      assert_select 'div.list_item_title a[href=?]', sample_type_path(hidden_type), text:hidden_type.title, count: 0
    end

  end

  test 'filter for select' do
    st1 = FactoryBot.create(:patient_sample_type, policy: FactoryBot.create(:public_policy))
    st2 = FactoryBot.create(:patient_sample_type, policy: FactoryBot.create(:public_policy))
    st3 = FactoryBot.create(:simple_sample_type, policy: FactoryBot.create(:public_policy))
    st3.tags = 'fred,mary'
    st1.tags = 'monkey'
    st3.save!
    st1.save!

    get :filter_for_select, params: { projects: st1.projects.collect(&:id), tags: ['monkey'] }
    assert_response :success
    assert assigns(:sample_types)
    assert_includes assigns(:sample_types), st1
    refute_includes assigns(:sample_types), st2
    refute_includes assigns(:sample_types), st3

    get :filter_for_select, params: { projects: st2.projects.collect(&:id) }
    assert_response :success
    assert assigns(:sample_types)
    assert_includes assigns(:sample_types), st2
    refute_includes assigns(:sample_types), st1
    refute_includes assigns(:sample_types), st3

    get :filter_for_select
    assert_response :success
    assert assigns(:sample_types)
    assert_empty assigns(:sample_types)

    get :filter_for_select, params: { projects: (st1.projects + st3.projects).collect(&:id), tags: %w[fred mary] }
    assert_response :success
    assert assigns(:sample_types)
    assert_includes assigns(:sample_types), st3
    refute_includes assigns(:sample_types), st2
    refute_includes assigns(:sample_types), st1

    get :filter_for_select,
        params: { projects: (st1.projects + st3.projects).collect(&:id), tags: %w[fred mary monkey] }

    assert_includes assigns(:sample_types), st1
    assert_includes assigns(:sample_types), st3
    refute_includes assigns(:sample_types), st2
  end

  test 'filter for select exclusive tags' do
    st1 = FactoryBot.create(:simple_sample_type, projects: [@project], policy: FactoryBot.create(:public_policy))
    st2 = FactoryBot.create(:simple_sample_type, projects: [@project], policy: FactoryBot.create(:public_policy))
    st3 = FactoryBot.create(:simple_sample_type, projects: [@project], policy: FactoryBot.create(:public_policy))
    st1.tags = 'fred,mary'
    st2.tags = 'fred,bob,jane'
    st3.tags = 'frank,john,jane,peter'
    st1.save!
    st2.save!
    st3.save!

    get :filter_for_select, params: { projects: (st1.projects + st3.projects).collect(&:id), tags: %w[fred bob] }
    assert_response :success
    assert results = assigns(:sample_types)
    results.sort!
    assert_equal [st1, st2].sort, results

    get :filter_for_select,
        params: { projects: (st1.projects + st3.projects).collect(&:id), tags: %w[fred bob], exclusive_tags: '0' }
    assert_response :success
    assert results = assigns(:sample_types)
    results.sort!
    assert_equal [st1, st2].sort, results

    get :filter_for_select,
        params: { projects: (st1.projects + st3.projects).collect(&:id), tags: %w[fred bob], exclusive_tags: '1' }
    assert_response :success
    assert results = assigns(:sample_types)
    results.sort!
    assert_equal [st2], results

    get :filter_for_select,
        params: { projects: (st1.projects + st3.projects).collect(&:id), tags: %w[jane frank], exclusive_tags: '1' }
    assert_response :success
    assert results = assigns(:sample_types)
    results.sort!
    assert_equal [st3], results

    get :filter_for_select,
        params: { projects: (st1.projects + st3.projects).collect(&:id), tags: %w[peter frank jane],
                  exclusive_tags: '1' }
    assert_response :success
    assert results = assigns(:sample_types)
    results.sort!
    assert_equal [st3], results

    get :filter_for_select,
        params: { projects: (st1.projects + st3.projects).collect(&:id), tags: %w[frank jane bob],
                  exclusive_tags: '1' }
    assert_response :success
    assert results = assigns(:sample_types)
    assert_empty results
  end

  test 'create sample type with a controlled vocab' do
    cv = FactoryBot.create(:apples_sample_controlled_vocab)
    assert_difference('ActivityLog.count', 1) do
      assert_difference('SampleType.count') do
        post :create, params: { sample_type: { title: 'Hello!',
                                               project_ids: @project_ids,
                                               sample_attributes_attributes: {
                                                 '0' => {
                                                   pos: '1', title: 'a string', required: '1', is_title: '1',
                                                   sample_attribute_type_id: @string_type.id, _destroy: '0'
                                                 },
                                                 '1' => {
                                                   pos: '2', title: 'cv', required: '1',
                                                   sample_attribute_type_id: @controlled_vocab_type.id,
                                                   allow_cv_free_text: '0',
                                                   sample_controlled_vocab_id: cv.id,
                                                   destroy: '0'
                                                 }
                                               } } }
      end
    end

    refute_nil type = assigns(:sample_type)
    assert_redirected_to sample_type_path(type)
    assert_equal 2, type.sample_attributes.count
    attr = type.sample_attributes.last
    assert attr.controlled_vocab?
    assert_equal cv, attr.sample_controlled_vocab
    refute attr.allow_cv_free_text
  end

  test 'create sample type with a controlled vocab with allow_cv_free_text' do
    cv = FactoryBot.create(:apples_sample_controlled_vocab)
    assert_difference('ActivityLog.count', 1) do
      assert_difference('SampleType.count') do
        post :create, params: { sample_type: { title: 'Hello!',
                                               project_ids: @project_ids,
                                               sample_attributes_attributes: {
                                                 '0' => {
                                                   pos: '1', title: 'a string', required: '1', is_title: '1',
                                                   sample_attribute_type_id: @string_type.id, _destroy: '0'
                                                 },
                                                 '1' => {
                                                   pos: '2', title: 'cv', required: '1',
                                                   sample_attribute_type_id: @controlled_vocab_type.id,
                                                   allow_cv_free_text: '1',
                                                   sample_controlled_vocab_id: cv.id,
                                                   destroy: '0'
                                                 }
                                               } } }
      end
    end

    refute_nil type = assigns(:sample_type)
    assert_redirected_to sample_type_path(type)
    assert_equal 2, type.sample_attributes.count
    attr = type.sample_attributes.last
    assert attr.controlled_vocab?
    assert_equal cv, attr.sample_controlled_vocab
    assert attr.allow_cv_free_text
  end

  test 'only visible sample types are listed' do
    person = FactoryBot.create(:person)
    st1 = FactoryBot.create(:simple_sample_type, projects: person.projects, contributor: person)
    st2 = FactoryBot.create(:simple_sample_type)
    st3 = FactoryBot.create(:simple_sample_type, projects: person.projects, policy: FactoryBot.create(:public_policy))
    login_as(person.user)

    assert st1.can_view?
    refute st2.can_view?
    assert st3.can_view?

    get :index

    assert_select 'div.list_items_container' do
      assert_select 'div.list_item_title a[href=?]', sample_type_path(st1)
      assert_select 'div.list_item_title a[href=?]', sample_type_path(st2), count: 0
      assert_select 'div.list_item_title a[href=?]', sample_type_path(st3)
    end
  end

  test 'cannot view private sample type' do
    st = FactoryBot.create(:simple_sample_type)
    refute st.can_view?

    get :show, params: { id: st.id }

    assert_response :forbidden

    assert_select 'h2.forbidden', text: /The Sample type is not visible to you/
  end

  test 'filter sample types with template when advanced single page is enabled' do
    project = FactoryBot.create(:project)
    FactoryBot.create(:simple_sample_type, template_id: 1, projects: [project], policy: FactoryBot.create(:public_policy))
    params = { projects: [project.id]}
    get :filter_for_select, params: params
    assert_equal assigns(:sample_types).length, 1
    with_config_value(:isa_json_compliance_enabled, true) do
      get :filter_for_select, params: params
      assert_equal assigns(:sample_types).length, 0
    end
  end


  test 'Should not be allowed to show the manage page of ISA-JSON compliant sample type' do
    with_config_value(:isa_json_compliance_enabled, true) do
      person = FactoryBot.create(:person)

      investigation = FactoryBot.create(:investigation, contributor: person, policy: FactoryBot.create(:public_policy),
                                                        is_isa_json_compliant: true)
      study = FactoryBot.create(:isa_json_compliant_study, investigation: investigation , contributor: person,
                                                           policy: FactoryBot.create(:public_policy))
      source_sample_type = study.sample_types.first

      project_sample_type = FactoryBot.create(:simple_sample_type, projects: study.projects, contributor: person)

      login_as(person)
      assert source_sample_type.is_isa_json_compliant?
      get :manage, params: { id: source_sample_type }
      assert_redirected_to sample_type_path

      refute project_sample_type.is_isa_json_compliant?
      get :manage, params: { id: project_sample_type }
      assert_response :success
    end
  end

  test 'Should be able to manage if permitted' do
    creator = FactoryBot.create(:person)
    authorized_person = FactoryBot.create(:person)
    unauthorized_person = FactoryBot.create(:person)
    sample_type = FactoryBot.create(:simple_sample_type, projects: creator.projects, contributor: creator,
                                                         policy: FactoryBot.create(:private_policy,
                                                                                   permissions: [FactoryBot.create(:permission, contributor: authorized_person, access_type: Policy::MANAGING),
                                                                                                 FactoryBot.create(:permission, contributor: unauthorized_person, access_type: Policy::EDITING)])
    )
    assert sample_type.can_manage?(creator)
    assert sample_type.can_manage?(authorized_person)
    refute sample_type.can_manage?(unauthorized_person)

    login_as(creator)
    get :manage, params: { id: sample_type }
    assert_response :success
    get :show, params: { id: sample_type }
    assert_response :success
    assert_select 'a', text: 'Manage Sample Type'

    login_as(authorized_person)
    get :manage, params: { id: sample_type }
    assert_response :success
    get :show, params: { id: sample_type }
    assert_response :success
    assert_select 'a', text: 'Manage Sample Type'

    login_as(unauthorized_person)
    get :manage, params: { id: sample_type }
    assert_redirected_to sample_type_path(sample_type)
    assert_equal flash[:error], 'You are not authorized to manage this Sample type.'
    get :show, params: { id: sample_type }
    assert_response :success
    assert_select 'a', text: 'Manage Sample Type', count: 0
  end

  test 'add new attribute to an existing sample type populated with samples' do
    sample_type = FactoryBot.create(:simple_sample_type, project_ids: @project_ids, contributor: @person)
    (1..10).map do |_i|
      FactoryBot.create(:sample, contributor: @person, project_ids: @project_ids, sample_type: sample_type)
    end
    refute_empty sample_type.samples
    login_as(@person)
    get :edit, params: { id: sample_type.id }
    assert_response :success
    assert_select 'a#add-attribute', count: 1

    # Should be able to add an optional new attribute to a sample type with samples
    assert_difference('SampleAttribute.count', 1) do
      patch :update, params: { id: sample_type.id, sample_type: {
        sample_attributes_attributes: {
          '1': { title: 'new optional attribute', sample_attribute_type_id: @string_type.id, required: '0' }
        }
      } }
    end
    assert_redirected_to sample_type_path(sample_type)
    sample_type.reload
    assert_equal 'new optional attribute', sample_type.sample_attributes.last.title

    # Should not be able to add a mandatory new attribute to a sample type with samples
    assert_no_difference('SampleAttribute.count') do
      patch :update, params: { id: sample_type.id, sample_type: {
        sample_attributes_attributes: {
          '2': { title: 'new mandatory attribute', sample_attribute_type_id: @string_type.id, required: '1' }
        }
      } }
    end

  end

  test 'check if sample type is locked' do
    refute @sample_type.locked?

    login_as(@person)

    %i[edit manage].each do |action|
      get action, params: { id: @sample_type.id }
      assert_nil flash[:error]
      assert_response :success
    end

    # lock the sample type by adding a fake update task
    UpdateSampleMetadataJob.perform_later(@sample_type, @person.user, [])
    assert @sample_type.locked?

    %i[edit manage].each do |action|
      get action, params: { id: @sample_type.id }
      assert_redirected_to sample_type_path(@sample_type)
      assert_equal flash[:error], 'This sample type is locked and cannot be edited right now.'
    end
  end

  test 'update a locked sample type' do
    other_person = FactoryBot.create(:person)
    sample_type = FactoryBot.create(:simple_sample_type, project_ids: @project_ids, contributor: @person)
    sample_type.policy.permissions << FactoryBot.create(:permission, contributor: other_person, access_type: Policy::MANAGING)

    (1..10).map do |_i|
      FactoryBot.create(:sample, contributor: @person, project_ids: @project_ids, sample_type: sample_type)
    end

    login_as(@person)

    refute @sample_type.locked?

    patch :update, params: { id: sample_type.id, sample_type: {
      sample_attributes_attributes: {
        '0': { id: sample_type.sample_attributes.detect(&:is_title), title: 'new title' }
      }
    } }
    assert_nil flash[:error]
    assert_redirected_to sample_type_path(sample_type)
    sample_type.reload
    assert sample_type.locked?

    login_as(other_person)

    patch :update, params: { id: sample_type.id, sample_type: {
      sample_attributes_attributes: {
        '0': { id: sample_type.sample_attributes.detect(&:is_title), title: 'new title' }
      }
    } }
    sample_type.reload
    sample_type.errors.added?(:base, 'This sample type is locked and cannot be edited right now.')

    assert_redirected_to sample_type_path(sample_type)
    assert(sample_type.locked?)
    assert_equal flash[:error], 'This sample type is locked and cannot be edited right now.'
  end

  private

  def template_for_upload
    fixture_file_upload('sample-type-example.xlsx', 'application/excel')
  end

  def bad_template_for_upload
    fixture_file_upload('small-test-spreadsheet.xls', 'application/excel')
  end

  def missing_columns_template_for_upload
    fixture_file_upload('samples-data-missing-columns.xls', 'application/excel')
  end
end
