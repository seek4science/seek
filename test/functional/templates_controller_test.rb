require 'test_helper'

class TemplatesControllerTest < ActionController::TestCase
  fixtures :isa_tags

  include AuthenticatedTestHelper
  include SharingFormTestHelper
  include GeneralAuthorizationTestCases

  setup do
    @old_setting = Seek::Config.isa_json_compliance_enabled
    Seek::Config.isa_json_compliance_enabled = true
    Seek::Util.clear_cached

    FactoryBot.create(:person) # to prevent person being first person and therefore admin
    @person = FactoryBot.create(:project_administrator)
    @project = @person.projects.first
    @project_ids = [@project.id]
    refute_nil @project
    login_as(@person)
    @template = FactoryBot.create(:min_template, project_ids: @project_ids, contributor: @person)
    @string_type = FactoryBot.create(:string_sample_attribute_type)
    @int_type = FactoryBot.create(:integer_sample_attribute_type)
    @registered_sample_attribute_type = FactoryBot.create(:sample_sample_attribute_type)
    @registered_sample_multi_attribute_type = FactoryBot.create(:sample_multi_sample_attribute_type)
    @controlled_vocab_type = FactoryBot.create(:controlled_vocab_attribute_type)
    @controlled_vocab_list_type = FactoryBot.create(:cv_list_attribute_type)
    @default_isa_tag = FactoryBot.create(:default_isa_tag)
  end

  teardown do
    Seek::Config.isa_json_compliance_enabled = @old_setting
    Seek::Util.clear_cached
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create template' do
    assert_difference('Template.count') do
      post :create, params: { template: { title: 'Hello!',
                                          project_ids: @project_ids,
                                          level: 'study source',
                                          organism: 'any',
                                          version: '1.0.0',
                                          parent_id: nil,
                                          description: 'The description!!',
                                          template_attributes_attributes: {
                                            '0' => {
                                              pos: '1',
                                              title: 'a string',
                                              required: '1',
                                              short_name: 'attribute1 short name',
                                              ontology_version: '0.1.1',
                                              description: 'attribute1 description',
                                              sample_attribute_type_id: @string_type.id,
                                              _destroy: '0',
                                              isa_tag_id: @default_isa_tag
                                            },
                                            '1' => {
                                              pos: '2',
                                              title: 'a number',
                                              required: '1',
                                              short_name: 'attribute2 short name',
                                              ontology_version: '0.1.2',
                                              description: 'attribute2 description',
                                              sample_attribute_type_id: @int_type.id,
                                              _destroy: '0',
                                              isa_tag_id: @default_isa_tag
                                            }
                                          }
                                        }
                            }
    end

    refute_nil template = assigns(:template)
    assert_redirected_to template_path(template)

    assert_equal @person, template.contributor
    assert_equal 'Hello!', template.title
    assert_equal 'The description!!', template.description
    assert_equal @project_ids.sort, template.project_ids.sort
    assert_equal 2, template.template_attributes.size
    assert_equal 'a string', template.template_attributes.first.title
    assert_equal [@project], template.projects
  end

  test 'should show template' do
    get :show, params: { id: @template }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @template }
    assert_response :success
  end

  test 'should update template' do
    template = nil
    template = FactoryBot.create(:min_template, project_ids: @project_ids, contributor: @person, title: 'new_template')

    template_attributes_fields = template.template_attributes.map do |attribute|
      { pos: attribute.pos, title: attribute.title,
        required: (attribute.required ? '1' : '0'),
        short_name: attribute.short_name,
        ontology_version: attribute.ontology_version,
        description: attribute.description,
        sample_attribute_type_id: attribute.sample_attribute_type_id,
        _destroy: '0',
        id: attribute.id,
        isa_tag_id: attribute.isa_tag_id
      }
    end

    template_attributes_fields[0][:title] = 'full_name'
    template_attributes_fields = Hash[template_attributes_fields.each_with_index.map { |f, i| [i.to_s, f] }]

    put :update, params: { id: template, template: { title: 'Hello!',
                                                     template_attributes_attributes: template_attributes_fields } }

    assert_redirected_to template_path(assigns(:template))
    assert_includes assigns(:template).template_attributes.map(&:title), 'full_name'
    assert_equal assigns(:template).title, 'Hello!'
  end

  test 'update changing from a CV attribute' do
    template = FactoryBot.create(:apples_controlled_vocab_template, project_ids: @project_ids, contributor: @person)
    assert template.valid?
    assert template.can_edit?
    assert_equal 1, template.template_attributes.count
    attribute = template.template_attributes.first
    refute_nil attribute.sample_controlled_vocab

    attribute_fields = [
      { pos: attribute.pos, title: 'A String',
        required: (attribute.required ? '1' : '0'),
        sample_attribute_type_id: @string_type.id,
        _destroy: '0',
        id: attribute.id,
        isa_tag_id: attribute.isa_tag_id
      }
    ]
    put :update, params: { id: template, template: { title: template.title,
                                                     template_attributes_attributes: attribute_fields } }
    assert_redirected_to template_path(assigns(:template))
    assert_nil flash[:error]
    template = assigns(:template)
    attribute = template.template_attributes.first
    assert_equal 'A String', attribute.title
    assert_equal @string_type, attribute.sample_attribute_type
  end

  test 'should destroy template' do
    assert @template.can_delete?

    assert_difference('Template.count', -1) do
      delete :destroy, params: { id: @template }
    end

    assert_redirected_to templates_path
  end

  test 'should not destroy template if has existing sample_types' do
    FactoryBot.create(:simple_sample_type, isa_template: @template)
    refute @template.can_delete?

    assert_no_difference('Template.count') do
      delete :destroy, params: { id: @template }
    end

    assert_response :redirect
    refute_nil flash[:error]
  end

  test 'should show private template to the contributor' do
    p = FactoryBot.create :person
    login_as p.user
    template = FactoryBot.create(:template, policy: FactoryBot.create(:policy, access_type: Policy::NO_ACCESS), contributor: p)
    get :show, params: { id: template }
    assert_response :success
  end

  test 'should not show private template to other users' do
    template = FactoryBot.create(:template, policy: FactoryBot.create(:policy, access_type: Policy::NO_ACCESS))
    get :show, params: { id: template }
    assert_response :forbidden
  end

  test 'should show public template to all users' do
    template = FactoryBot.create(:template, policy: FactoryBot.create(:policy, access_type: Policy::VISIBLE))
    login_as FactoryBot.create(:user)
    get :show, params: { id: template }
    assert_response :success
  end

  test 'authlookup item queued if creator changed' do
    template = FactoryBot.create(:template)
    login_as(template.contributor)
    creator = FactoryBot.create(:person)

    AuthLookupUpdateQueue.destroy_all

    with_config_value(:auth_lookup_enabled, true) do
      assert_difference('AuthLookupUpdateQueue.count', 1) do
        put :update, params: { id: template.id, template: { title: 'fish', creator_ids: [creator.id.to_s] } }
        assert_redirected_to template
        assert_equal 'fish', assigns(:template).title
        assert_equal [creator], assigns(:template).creators
      end

      AuthLookupUpdateQueue.destroy_all

      # no job if no change to creators
      assert_no_difference('AuthLookupUpdateQueue.count') do
        put :update, params: { id: template.id, template: { title: 'horse', creator_ids: [creator.id.to_s] } }
        assert_redirected_to template
        assert_equal 'horse', assigns(:template).title
        assert_equal [creator], assigns(:template).creators
      end

      AuthLookupUpdateQueue.destroy_all

      # job if creator removed
      assert_difference('AuthLookupUpdateQueue.count', 1) do
        put :update, params: { id: template.id, template: { title: 'fish', creator_ids: [''] } }
        assert_redirected_to template
        assert_equal 'fish', assigns(:template).title
        assert_equal [], assigns(:template).creators
      end
    end
  end

  test 'should show default_templates to admin only' do
    get :default_templates
    assert_equal 'Admin rights required', flash[:error]
    assert_response :redirect

    login_as(FactoryBot.create(:admin))
    get :default_templates
    assert_response :success
  end

  test 'should get task_status' do
    login_as(FactoryBot.create(:admin))
    get :task_status
    assert_template partial: 'templates/_result'
  end

  test 'should set default template population task status' do
    @controller.send(:set_status)
    status = assigns(:status)
    assert_equal 'not_started', status

    File.open(@controller.send(:resultfile), 'w+') { |f| f.write('content') }
    @controller.send(:set_status)
    status = assigns(:status)
    assert_equal 'content', status

    @controller.send(:running!)
    status = assigns(:status)
    @controller.send(:done!)
    assert_equal 'working', status
  end

  test 'sample type templates through nested routing' do
    assert_routing 'sample_types/2/templates', controller: 'templates', action: 'index', sample_type_id: '2'


    template = FactoryBot.create(:min_template, project_ids: @project_ids, contributor: @person, title:'related template')
    template2 = FactoryBot.create(:min_template, project_ids: @project_ids, contributor: @person, title:'unrelated template')
    sample_type = FactoryBot.create(:simple_sample_type, isa_template: template, project_ids: @project_ids, contributor: @person)

    assert_equal template, sample_type.isa_template

    get :index, params: { sample_type_id: sample_type.id }

    assert_response :success

    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', template_path(template), text: template.title
      assert_select 'a[href=?]', template_path(template2), text: template2.title, count: 0
    end
  end

  test 'editable isa tags' do
    login_as(@person)
    parent_template = FactoryBot.create(:isa_source_template, project_ids: @project_ids, contributor: @person)
    inherited_template = create_template_from_parent_template(parent_template)

    refute parent_template.template_attributes.all?(&:inherited?)
    assert inherited_template.template_attributes.all?(&:inherited?)

    get :edit, params: { id: inherited_template.id }
    assert_response :success

    inherited_template.template_attributes.each_with_index do |_ta, i|
      id = "select#template_template_attributes_attributes_#{i}_isa_tag_title[disabled='disabled']"
      assert_select id
    end

    inherited_template.template_attributes << FactoryBot.create(:template_attribute, title: 'Extra attribute', isa_tag: FactoryBot.create(:source_characteristic_isa_tag), sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), pos: 4)
    inherited_template.reload

    assert inherited_template.template_attributes.last.title == 'Extra attribute'
    refute inherited_template.template_attributes.last.inherited?
    assert inherited_template.template_attributes.first.title == 'Source Name'
    assert inherited_template.template_attributes.first.inherited?
    refute inherited_template.template_attributes.first.allow_isa_tag_change?
    assert inherited_template.template_attributes.last.allow_isa_tag_change?

    get :edit, params: { id: inherited_template.id }
    assert_response :success

    assert_select "select#template_template_attributes_attributes_0_isa_tag_title[disabled='disabled']"
    cnt_last_attribute = inherited_template.template_attributes.count - 1

    assert_select "select#template_template_attributes_attributes_#{cnt_last_attribute}_isa_tag_title[disabled='disabled']", text: 'source_characteristic', count: 0

  end

  test 'should not allow to create template with registered sample template attributes with no linked sample type' do
    source_isa_tag = FactoryBot.create(:source_isa_tag)
    source_characteristic_isa_tag = FactoryBot.create(:source_characteristic_isa_tag)
    source_attribute = {
      pos: '1',
      title: 'Source Name',
      required: '1',
      short_name: 'attribute1 short name',
      ontology_version: '0.1.1',
      description: 'attribute1 description',
      isa_tag_id: source_isa_tag.id,
      sample_attribute_type_id: @string_type.id,
      is_title: '1',
      _destroy: '0'
    }

    bad_registered_sample_attribute = {
      pos: '2',
      title: 'Correct registered sample attribute',
      required: '1',
      short_name: 'attribute2 short name',
      ontology_version: '0.1.2',
      description: 'attribute2 description',
      isa_tag_id: source_characteristic_isa_tag,
      sample_attribute_type_id: @registered_sample_attribute_type.id,
      linked_sample_type_id: nil,
      _destroy: '0'
    }

    bad_template_params = { title: 'Bad template',
                            project_ids: @project_ids,
                            level: 'study source',
                            organism: 'any',
                            version: '1.0.0',
                            parent_id: nil,
                            description: 'Template containing registered samples attributes with no linked sample type',
                            template_attributes_attributes: {
                              '0' => source_attribute,
                              '1' => bad_registered_sample_attribute
                            } }

    assert_no_difference('Template.count') do
      post :create, params: { template: bad_template_params }
      assert_response :unprocessable_entity
      assert_template :new
      assert_select 'div#error_explanation', text: /Linked Sample Type must be set if attribute type is Registered Sample/
    end

    sample_type = FactoryBot.create(:simple_sample_type, project_ids: @project_ids, contributor: @person)

    correct_registered_sample_attribute = {
      pos: '2',
      title: 'Correct registered sample attribute',
      required: '1',
      short_name: 'attribute2 short name',
      ontology_version: '0.1.2',
      description: 'attribute2 description',
      isa_tag_id: source_characteristic_isa_tag,
      sample_attribute_type_id: @registered_sample_attribute_type.id,
      linked_sample_type_id: sample_type.id,
      _destroy: '0'
    }

    correct_source_template_params = { title: 'Correct source template',
                                       project_ids: @project_ids,
                                       level: 'study source',
                                       organism: 'any',
                                       version: '1.0.0',
                                       parent_id: nil,
                                       description: 'Template containing attributes with no isa tags',
                                       template_attributes_attributes: {
                                         '0' => source_attribute,
                                         '1' => correct_registered_sample_attribute
                                       } }

    assert_difference('Template.count', 1) do
      post :create, params: { template: correct_source_template_params }
      assert_response :redirect
      assert_redirected_to template_path(assigns(:template))
    end

    sample_isa_tag = FactoryBot.create(:sample_isa_tag)
    sample_characteristic_isa_tag = FactoryBot.create(:sample_characteristic_isa_tag)

    input_sample_attribute = {
      pos: '1',
      title: 'Input (Source sample)',
      required: '1',
      short_name: 'attribute1 short name',
      ontology_version: '0.1.2',
      description: 'attribute1 description',
      sample_attribute_type_id: @registered_sample_multi_attribute_type.id,
      linked_sample_type_id: nil,
      _destroy: '0'
    }

    collected_sample_attribute = {
      pos: '2',
      title: 'Sample Name',
      required: '1',
      short_name: 'attribute2 short name',
      ontology_version: '0.1.1',
      description: 'attribute2 description',
      isa_tag_id: sample_isa_tag.id,
      sample_attribute_type_id: @string_type.id,
      is_title: '1',
      _destroy: '0'
    }

    sample_characteristic_attribute = {
      pos: '3',
      title: 'Correct registered sample attribute',
      required: '1',
      short_name: 'attribute3 short name',
      ontology_version: '0.1.2',
      description: 'attribute3 description',
      isa_tag_id: sample_characteristic_isa_tag.id,
      sample_attribute_type_id: @registered_sample_attribute_type.id,
      linked_sample_type_id: sample_type.id,
      _destroy: '0'
    }

    correct_sample_collection_template_params = { title: 'Correct Sample collection template',
                                                  project_ids: @project_ids,
                                                  level: 'study sample',
                                                  organism: 'any',
                                                  version: '1.0.0',
                                                  parent_id: nil,
                                                  description: 'Sample collection template made correctly',
                                                  template_attributes_attributes: {
                                                    '0' => input_sample_attribute,
                                                    '1' => collected_sample_attribute,
                                                    '2' => sample_characteristic_attribute
                                                  } }

    assert_difference('Template.count', 1) do
      post :create, params: { template: correct_sample_collection_template_params }
      assert_response :redirect
      assert_redirected_to template_path(assigns(:template))
    end

  end

  test 'should not allow to create template with controlled vocabulary template attributes with no sample controlled vocabulary' do
    source_isa_tag = FactoryBot.create(:source_isa_tag)
    source_characteristic_isa_tag = FactoryBot.create(:source_characteristic_isa_tag)
    source_attribute = {
      pos: '1',
      title: 'Source Name',
      required: '1',
      short_name: 'attribute1 short name',
      ontology_version: '0.1.1',
      description: 'attribute1 description',
      isa_tag_id: source_isa_tag.id,
      sample_attribute_type_id: @string_type.id,
      is_title: '1',
      _destroy: '0'
    }

    bad_controlled_vocab_attribute = {
      pos: '2',
      title: 'Correct registered sample attribute',
      required: '1',
      short_name: 'attribute2 short name',
      ontology_version: '0.1.2',
      description: 'attribute2 description',
      isa_tag_id: source_characteristic_isa_tag,
      sample_attribute_type_id: @controlled_vocab_type.id,
      _destroy: '0'
    }

    bad_template_params = { title: 'Bad template',
                            project_ids: @project_ids,
                            level: 'study source',
                            organism: 'any',
                            version: '1.0.0',
                            parent_id: nil,
                            description: 'Template containing controlled vocabulary attributes with no sample controlled vocabulary',
                            template_attributes_attributes: {
                              '0' => source_attribute,
                              '1' => bad_controlled_vocab_attribute
                            } }

    assert_no_difference('Template.count') do
      post :create, params: { template: bad_template_params }
      assert_response :unprocessable_entity
      assert_template :new
      assert_select 'div#error_explanation', text: /Controlled vocabulary must be set if attribute type is CV/
    end

    controlled_vocab = FactoryBot.create(:apples_sample_controlled_vocab)
    correct_controlled_vocab_attribute = {
      pos: '2',
      title: 'Correct registered sample attribute',
      required: '1',
      short_name: 'attribute2 short name',
      ontology_version: '0.1.2',
      description: 'attribute2 description',
      isa_tag_id: source_characteristic_isa_tag,
      sample_attribute_type_id: @controlled_vocab_type.id,
      sample_controlled_vocab_id: controlled_vocab.id,
      _destroy: '0'
    }

    correct_source_template_params = { title: 'Correct source template',
                                       project_ids: @project_ids,
                                       level: 'study source',
                                       organism: 'any',
                                       version: '1.0.0',
                                       parent_id: nil,
                                       description: 'Template containing controlled vocabulary attributes with sample controlled vocabulary',
                                       template_attributes_attributes: {
                                         '0' => source_attribute,
                                         '1' => correct_controlled_vocab_attribute
                                       } }

    assert_difference('Template.count', 1) do
      post :create, params: { template: correct_source_template_params }
      assert_response :redirect
      assert_redirected_to template_path(assigns(:template))
    end
  end

  test 'should not allow to create template with controlled vocabulary list template attributes with no sample controlled vocabulary' do
    source_isa_tag = FactoryBot.create(:source_isa_tag)
    source_characteristic_isa_tag = FactoryBot.create(:source_characteristic_isa_tag)
    source_attribute = {
      pos: '1',
      title: 'Source Name',
      required: '1',
      short_name: 'attribute1 short name',
      ontology_version: '0.1.1',
      description: 'attribute1 description',
      isa_tag_id: source_isa_tag.id,
      sample_attribute_type_id: @string_type.id,
      is_title: '1',
      _destroy: '0'
    }

    bad_controlled_vocab_list_attribute = {
      pos: '2',
      title: 'Correct registered sample attribute',
      required: '1',
      short_name: 'attribute2 short name',
      ontology_version: '0.1.2',
      description: 'attribute2 description',
      isa_tag_id: source_characteristic_isa_tag,
      sample_attribute_type_id: @controlled_vocab_list_type.id,
      _destroy: '0'
    }

    bad_template_params = { title: 'Bad template',
                            project_ids: @project_ids,
                            level: 'study source',
                            organism: 'any',
                            version: '1.0.0',
                            parent_id: nil,
                            description: 'Template containing controlled vocabulary list attributes with no sample controlled vocabulary',
                            template_attributes_attributes: {
                              '0' => source_attribute,
                              '1' => bad_controlled_vocab_list_attribute
                            } }

    assert_no_difference('Template.count') do
      post :create, params: { template: bad_template_params }
      assert_response :unprocessable_entity
      assert_template :new
      assert_select 'div#error_explanation', text: /Controlled vocabulary must be set if attribute type is LIST/
    end

    controlled_vocab = FactoryBot.create(:apples_sample_controlled_vocab)
    correct_controlled_vocab_list_attribute = {
      pos: '2',
      title: 'Correct registered sample attribute',
      required: '1',
      short_name: 'attribute2 short name',
      ontology_version: '0.1.2',
      description: 'attribute2 description',
      isa_tag_id: source_characteristic_isa_tag,
      sample_attribute_type_id: @controlled_vocab_list_type.id,
      sample_controlled_vocab_id: controlled_vocab.id,
      _destroy: '0'
    }

    correct_source_template_params = { title: 'Correct source template',
                                       project_ids: @project_ids,
                                       level: 'study source',
                                       organism: 'any',
                                       version: '1.0.0',
                                       parent_id: nil,
                                       description: 'Template containing controlled vocabulary attributes with sample controlled vocabulary',
                                       template_attributes_attributes: {
                                         '0' => source_attribute,
                                         '1' => correct_controlled_vocab_list_attribute
                                       } }

    assert_difference('Template.count', 1) do
      post :create, params: { template: correct_source_template_params }
      assert_response :redirect
      assert_redirected_to template_path(assigns(:template))
    end
  end

  test 'Should not see add new attribute button at template creation time' do
    get :new
    assert_response :success
    assert_select 'a#add-attribute.hidden', text: /Add new attribute/, count: 1
  end

  test 'Should see add new attribute button at template edit time' do
    my_template = FactoryBot.create(:isa_source_template, project_ids: @project_ids, contributor: @person)
    get :edit, params: { id: my_template.id }
    assert_response :success
    assert_select 'a#add-attribute.hidden', text: /Add new attribute/, count: 0
  end

  test 'Should only be able link a new template to projects the current user is project admin of' do
    project = FactoryBot.create(:project)
    project_admin = FactoryBot.create(:project_administrator, project: project)
    login_as(project_admin.user)
    get :new
    assert_response :success

    # The project selector is a vue-component, which is not translated to html in the test environment
    # Instead we check that the json data is present in 'project-selector-possibilities-json'
    assert_select 'script#project-selector-possibilities-json', count: 1
    options = "[{\"id\":#{project.id},\"text\":\"#{project.title}\"}]"
    assert_select 'script#project-selector-possibilities-json', text: /#{options}/, count: 1
  end

  def create_template_from_parent_template(parent_template, person= @person, linked_sample_type= nil)
    child_template_attributes = parent_template.template_attributes.map do |ta|
      FactoryBot.create(:template_attribute, parent_attribute_id: ta.id, title: ta.title, isa_tag_id: ta.isa_tag_id, sample_attribute_type: ta.sample_attribute_type, is_title: ta.is_title, required: ta.required, sample_controlled_vocab: ta.sample_controlled_vocab, pos: ta.pos)
    end
    FactoryBot.create(:template, contributor: person, template_attributes: child_template_attributes, parent_id: parent_template.id)
  end
end
