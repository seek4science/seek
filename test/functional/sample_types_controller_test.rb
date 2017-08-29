require 'test_helper'

class SampleTypesControllerTest < ActionController::TestCase
  include RestTestCases
  include AuthenticatedTestHelper

  setup do
    Factory(:person) # to prevent person being first person and therefore admin
    @person = Factory(:project_administrator)
    @project = @person.projects.first
    @project_ids = [@project.id]
    refute_nil @project
    login_as(@person)
    @sample_type = Factory(:simple_sample_type, project_ids: @project_ids)
    @string_type = Factory(:string_sample_attribute_type)
    @int_type = Factory(:integer_sample_attribute_type)
    @controlled_vocab_type=Factory(:controlled_vocab_attribute_type)
  end

  def rest_api_test_object
    @object = @sample_type #Factory(:sample_type, project_ids: @project_ids)
  end

  test 'should get index' do
    get :index
    assert_response :success
    refute_nil assigns(:sample_types)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create sample_type' do
    @person.projects.first

    golf = Factory :tag, source: @person.user, annotatable: Factory(:simple_sample_type), value: 'golf'

    assert_difference('SampleType.count') do
      post :create, sample_type: { title: 'Hello!',
                                   project_ids: @project_ids,
                                   description: 'The description!!',
                                   sample_attributes_attributes: {
                                     '0' => {
                                       pos: '1', title: 'a string', required: '1', is_title: '1',
                                       sample_attribute_type_id: @string_type.id, _destroy: '0' },
                                     '1' => {
                                       pos: '2', title: 'a number', required: '1',
                                       sample_attribute_type_id: @int_type.id, _destroy: '0'
                                     }
                                   },
                                   tags: 'fish,golf'

      }
    end

    refute_nil type=assigns(:sample_type)
    assert_redirected_to sample_type_path(type)

    assert_equal 'Hello!',type.title
    assert_equal 'The description!!',type.description
    assert_equal @project_ids.sort,type.project_ids.sort
    assert_equal 2, type.sample_attributes.size
    assert_equal 'a string', type.sample_attributes.title_attributes.first.title
    assert_equal [@project], type.projects
    refute type.uploaded_template?
    assert_equal %w(fish golf), type.tags.sort
    assert SampleTemplateGeneratorJob.new(type).exists?
    assert SampleTypeUpdateJob.new(type, true).exists?
  end

  test 'should create with linked sample type' do
    linked_sample_type = Factory(:sample_sample_attribute_type)
    assert_difference('SampleType.count') do
      post :create, sample_type: { title: 'Hello!',
                                   project_ids: [@project.id],
                                   sample_attributes_attributes: {
                                     '0' => {
                                       pos: '1', title: 'a string', required: '1', is_title: '1',
                                       sample_attribute_type_id: @string_type.id, _destroy: '0' },
                                     '1' => {
                                       pos: '2', title: 'a sample', required: '1',
                                       sample_attribute_type_id: linked_sample_type.id, linked_sample_type_id: @sample_type.id, _destroy: '0'
                                     }
                                   }
      }
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
    linked_sample_type = Factory(:sample_sample_attribute_type)
    assert_difference('SampleType.count') do
      post :create, sample_type: { title: 'Hello!',
                                   project_ids: @project_ids,
                                   sample_attributes_attributes: {
                                     '0' => {
                                       pos: '1', title: 'a string', required: '1', is_title: '1',
                                       sample_attribute_type_id: @string_type.id, _destroy: '0' },
                                     '1' => {
                                       pos: '2', title: 'a sample', required: '1',
                                       sample_attribute_type_id: linked_sample_type.id, linked_sample_type_id: 'self', _destroy: '0'
                                     }
                                   }
      }
    end
    refute_nil sample_type = assigns(:sample_type)
    assert_redirected_to sample_type_path(sample_type)
    assert_equal 2, sample_type.sample_attributes.size
    assert_equal 'a string', sample_type.sample_attributes.title_attributes.first.title
    assert_equal 'a sample', sample_type.sample_attributes.last.title
    assert sample_type.sample_attributes.last.sample_attribute_type.seek_sample?
    assert_equal sample_type, sample_type.sample_attributes.last.linked_sample_type
  end

  test 'should show sample_type' do
    get :show, id: @sample_type
    assert_response :success
  end

  test 'should get edit' do
    get :edit, id: @sample_type
    assert_response :success
  end

  test 'should update sample_type' do
    sample_type = Factory(:patient_sample_type, project_ids: @project_ids)
    assert_empty sample_type.tags_as_text_array

    golf = Factory :tag, source: @person.user, annotatable: Factory(:simple_sample_type), value: 'golf'

    sample_attributes_fields = sample_type.sample_attributes.map do |attribute|
      { pos: attribute.pos, title: attribute.title,
        required: (attribute.required ? '1' : '0'),
        sample_attribute_type_id: attribute.sample_attribute_type_id,
        _destroy: '0',
        id: attribute.id
      }
    end

    sample_attributes_fields[0][:is_title] = '0'
    sample_attributes_fields[1][:title] = 'hello'
    sample_attributes_fields[1][:is_title] = '1'
    sample_attributes_fields[2][:_destroy] = '1'
    sample_attributes_fields = Hash[sample_attributes_fields.each_with_index.map { |f, i| [i.to_s, f] }]

    assert_difference('SampleAttribute.count', -1) do
      put :update, id: sample_type, sample_type: { title: 'Hello!',
                                                   sample_attributes_attributes: sample_attributes_fields,
                                                   tags: "fish,#{golf.value.text}"
      }
    end
    assert_redirected_to sample_type_path(assigns(:sample_type))

    assert_equal sample_attributes_fields.keys.size - 1, assigns(:sample_type).sample_attributes.size
    assert_includes assigns(:sample_type).sample_attributes.map(&:title), 'hello'
    refute assigns(:sample_type).sample_attributes[0].is_title?
    assert assigns(:sample_type).sample_attributes[1].is_title?
    assert_equal %w(fish golf), assigns(:sample_type).tags.sort
    assert SampleTemplateGeneratorJob.new(assigns(:sample_type)).exists?
    assert SampleTypeUpdateJob.new(assigns(:sample_type), true).exists?
  end

  test 'update changing from a CV attribute' do
    sample_type = Factory(:apples_controlled_vocab_sample_type, project_ids: @project_ids)
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
        id: attribute.id
      }
    ]
    put :update, id: sample_type, sample_type: { title: sample_type.title,
                                                 sample_attributes_attributes: attribute_fields
    }
    assert_redirected_to sample_type_path(assigns(:sample_type))
    assert_nil flash[:error]
    sample_type = assigns(:sample_type)
    attribute = sample_type.sample_attributes.first
    refute attribute.controlled_vocab?
    assert_equal 'A String', attribute.title
    assert_equal @string_type, attribute.sample_attribute_type
  end

  test 'update changing from a Sample Type attribute' do
    sample_type = Factory(:linked_sample_type, project_ids: @project_ids)
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
        id: first_attribute.id
      },
      { pos: attribute.pos, title: 'A String',
        required: (attribute.required ? '1' : '0'),
        sample_attribute_type_id: @string_type.id,
        _destroy: '0',
        id: attribute.id
      }
    ]
    put :update, id: sample_type, sample_type: { title: sample_type.title,
                                                 sample_attributes_attributes: attribute_fields
    }
    assert_redirected_to sample_type_path(assigns(:sample_type))
    assert_nil flash[:error]
    sample_type = assigns(:sample_type)
    attribute = sample_type.sample_attributes.last
    refute attribute.seek_sample?
    assert_equal 'A String', attribute.title
    assert_equal @string_type, attribute.sample_attribute_type
  end

  test 'other project member cannot update sample type' do
    sample_type = Factory(:patient_sample_type, project_ids: [Factory(:project).id], title: 'should not change')
    refute sample_type.can_edit?
    put :update, id: sample_type, sample_type: { title: 'Hello!' }
    assert_redirected_to sample_type_path(sample_type)
    refute_nil flash[:error]
    sample_type.reload
    assert_equal 'should not change', sample_type.title
  end

  test 'other project member cannot edit sample type' do
    sample_type = Factory(:patient_sample_type, project_ids: [Factory(:project).id])
    refute sample_type.can_edit?
    get :edit, id: sample_type
    assert_redirected_to sample_type_path(sample_type)
    refute_nil flash[:error]
  end

  test 'should destroy sample_type' do
    assert_difference('SampleType.count', -1) do
      delete :destroy, id: @sample_type
    end

    assert_redirected_to sample_types_path
  end

  test 'should not destroy sample_type if has existing samples' do
    FactoryGirl.create_list(:sample, 3, sample_type: @sample_type)

    assert_no_difference('SampleType.count') do
      delete :destroy, id: @sample_type
    end

    assert_response :redirect
    assert_equal 'Cannot destroy this sample type - There are 3 samples using it.', flash[:error]
  end

  test 'create from template' do
    blob = { data: template_for_upload }

    assert_difference('SampleType.count', 1) do
      assert_difference('ContentBlob.count', 1) do
        post :create_from_template, sample_type: { title: 'Hello!', project_ids: @project_ids }, content_blobs: [blob]
      end
    end

    assert_redirected_to edit_sample_type_path(assigns(:sample_type))
    assert_empty assigns(:sample_type).errors
    assert assigns(:sample_type).uploaded_template?
  end

  test 'create from template with some blank columns' do
    blob = { data: missing_columns_template_for_upload }

    assert_difference('SampleType.count', 1) do
      assert_difference('ContentBlob.count', 1) do
        post :create_from_template, sample_type: { title: 'Hello!', project_ids: @project_ids }, content_blobs: [blob]
      end
    end

    assert_redirected_to edit_sample_type_path(assigns(:sample_type))
    assert_empty assigns(:sample_type).errors
  end

  test "don't create from bad template" do
    blob = { data: bad_template_for_upload }

    assert_no_difference('SampleType.count') do
      assert_no_difference('ContentBlob.count') do
        post :create_from_template, sample_type: { title: 'Hello!' }, content_blobs: [blob]
      end
    end

    assert_template :new
    assert_not_empty assigns(:sample_type).errors
  end

  test 'should show link to sample type for linked attribute' do
    linked_type = Factory(:linked_sample_type, project_ids: @project_ids)
    linked_attribute = linked_type.sample_attributes.last

    assert linked_attribute.sample_attribute_type.seek_sample?

    sample_type_linked_to = linked_attribute.linked_sample_type
    refute_nil sample_type_linked_to

    get :show, id: linked_type.id

    assert_select 'li', text: /patient \(#{linked_attribute.sample_attribute_type.title}/i do
      assert_select 'a[href=?]', sample_type_path(sample_type_linked_to), text: sample_type_linked_to.title
    end
  end

  test 'add attribute button' do
    type = Factory(:simple_sample_type, project_ids: @project_ids)
    assert_empty type.samples
    login_as(@person)
    get :edit, id: type.id
    assert_response :success
    assert_select 'a#add-attribute', count: 1

    sample = Factory(:patient_sample, contributor: @person.user,
                                      sample_type: Factory(:patient_sample_type, project_ids: @project_ids))
    type = sample.sample_type
    refute_empty type.samples
    assert type.can_edit?

    get :edit, id: type.id
    assert_response :success
    assert_select 'a#add-attribute', count: 0
  end

  test 'cannot access when disabled' do
    sample_type = Factory(:simple_sample_type)
    login_as(@person.user)
    with_config_value :samples_enabled, false do
      get :show, id: sample_type.id
      assert_redirected_to :root
      refute_nil flash[:error]

      flash[:error] = nil

      get :index
      assert_redirected_to :root
      refute_nil flash[:error]

      flash[:error] = nil

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

  test 'filter for select' do
    st1 = Factory(:patient_sample_type)
    st2 = Factory(:patient_sample_type)
    st3 = Factory(:simple_sample_type)
    st3.tags = 'fred,mary'
    st1.tags = 'monkey'
    st3.save!
    st1.save!

    get :filter_for_select, projects: st1.projects.collect(&:id), tags: ['monkey']
    assert_response :success
    assert assigns(:sample_types)
    assert_includes assigns(:sample_types), st1
    refute_includes assigns(:sample_types), st2
    refute_includes assigns(:sample_types), st3

    get :filter_for_select, projects: st2.projects.collect(&:id)
    assert_response :success
    assert assigns(:sample_types)
    assert_includes assigns(:sample_types), st2
    refute_includes assigns(:sample_types), st1
    refute_includes assigns(:sample_types), st3

    get :filter_for_select
    assert_response :success
    assert assigns(:sample_types)
    assert_empty assigns(:sample_types)

    get :filter_for_select, projects: (st1.projects + st3.projects).collect(&:id), tags: %w(fred mary)
    assert_response :success
    assert assigns(:sample_types)
    assert_includes assigns(:sample_types), st3
    refute_includes assigns(:sample_types), st2
    refute_includes assigns(:sample_types), st1

    get :filter_for_select, projects: (st1.projects + st3.projects).collect(&:id), tags: %w(fred mary monkey)

    assert_includes assigns(:sample_types), st1
    assert_includes assigns(:sample_types), st3
    refute_includes assigns(:sample_types), st2
  end

  test 'filter for select exclusive tags' do
    st1 = Factory(:simple_sample_type, projects: [@project])
    st2 = Factory(:simple_sample_type, projects: [@project])
    st3 = Factory(:simple_sample_type, projects: [@project])
    st1.tags = 'fred,mary'
    st2.tags = 'fred,bob,jane'
    st3.tags = 'frank,john,jane,peter'
    st1.save!
    st2.save!
    st3.save!

    get :filter_for_select, projects: (st1.projects + st3.projects).collect(&:id), tags: %w(fred bob)
    assert_response :success
    assert results = assigns(:sample_types)
    results.sort!
    assert_equal [st1, st2].sort, results

    get :filter_for_select, projects: (st1.projects + st3.projects).collect(&:id), tags: %w(fred bob), exclusive_tags: '0'
    assert_response :success
    assert results = assigns(:sample_types)
    results.sort!
    assert_equal [st1, st2].sort, results

    get :filter_for_select, projects: (st1.projects + st3.projects).collect(&:id), tags: %w(fred bob), exclusive_tags: '1'
    assert_response :success
    assert results = assigns(:sample_types)
    results.sort!
    assert_equal [st2], results

    get :filter_for_select, projects: (st1.projects + st3.projects).collect(&:id), tags: %w(jane frank), exclusive_tags: '1'
    assert_response :success
    assert results = assigns(:sample_types)
    results.sort!
    assert_equal [st3], results

    get :filter_for_select, projects: (st1.projects + st3.projects).collect(&:id), tags: %w(peter frank jane), exclusive_tags: '1'
    assert_response :success
    assert results = assigns(:sample_types)
    results.sort!
    assert_equal [st3], results

    get :filter_for_select, projects: (st1.projects + st3.projects).collect(&:id), tags: %w(frank jane bob), exclusive_tags: '1'
    assert_response :success
    assert results = assigns(:sample_types)
    assert_empty results
  end

  test 'create sample type with a controlled vocab' do
    cv = Factory(:apples_sample_controlled_vocab)
    assert_difference('SampleType.count') do
      post :create, sample_type: { title: 'Hello!',
                                   project_ids: @project_ids,
                                   sample_attributes_attributes: {
                                       '0' => {
                                           pos: '1', title: 'a string', required: '1', is_title: '1',
                                           sample_attribute_type_id: @string_type.id, _destroy: '0' },
                                       '1' => {
                                           pos: '2', title: 'cv', required: '1',
                                           sample_attribute_type_id:@controlled_vocab_type.id,
                                           sample_controlled_vocab_id:cv.id,
                                           destroy: '0'
                                       }
                                   }
      }
    end
    refute_nil type=assigns(:sample_type)
    assert_redirected_to sample_type_path(type)
    assert_equal 2,type.sample_attributes.count
    attr=type.sample_attributes.last
    assert attr.controlled_vocab?
    assert_equal cv,attr.sample_controlled_vocab
  end

  private

  def template_for_upload
    ActionDispatch::Http::UploadedFile.new(filename: 'sample-type-example.xlsx',
                                           content_type: 'application/excel',
                                           tempfile: fixture_file_upload('files/sample-type-example.xlsx'))
  end

  def bad_template_for_upload
    ActionDispatch::Http::UploadedFile.new(filename: 'small-test-spreadsheet.xls',
                                           content_type: 'application/excel',
                                           tempfile: fixture_file_upload('files/small-test-spreadsheet.xls'))
  end

  def missing_columns_template_for_upload
    ActionDispatch::Http::UploadedFile.new(filename: 'samples-data-missing-columns.xls',
                                           content_type: 'application/excel',
                                           tempfile: fixture_file_upload('files/samples-data-missing-columns.xls'))
  end
end
