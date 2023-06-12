require 'test_helper'

class TemplatesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  include SharingFormTestHelper
  include GeneralAuthorizationTestCases

  setup do
    Seek::Config.send('sample_type_template_enabled=', true)
    FactoryBot.create(:person) # to prevent person being first person and therefore admin
    @person = FactoryBot.create(:project_administrator)
    @project = @person.projects.first
    @project_ids = [@project.id]
    refute_nil @project
    login_as(@person)
    @template = FactoryBot.create(:min_template, project_ids: @project_ids, contributor: @person)
    @string_type = FactoryBot.create(:string_sample_attribute_type)
    @int_type = FactoryBot.create(:integer_sample_attribute_type)
    @controlled_vocab_type = FactoryBot.create(:controlled_vocab_attribute_type)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create template' do
    assert_difference('Template.count') do
      post :create, params: { template: { title: 'Hello!',
                                          project_ids: @project_ids,
                                          level: 'level', group: 'group', organism: 'organism',
                                          description: 'The description!!',
                                          template_attributes_attributes: {
                                            '0' => {
                                              pos: '1', title: 'a string', required: '1',
                                              short_name: 'attribute1 short name',
                                              ontology_version: '0.1.1',
                                              description: 'attribute1 description',
                                              sample_attribute_type_id: @string_type.id, _destroy: '0'
                                            },
                                            '1' => {
                                              pos: '2', title: 'a number', required: '1',
                                              short_name: 'attribute2 short name',
                                              ontology_version: '0.1.2',
                                              description: 'attribute2 description',
                                              sample_attribute_type_id: @int_type.id, _destroy: '0'
                                            }
                                          } } }
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
        id: attribute.id }
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
        id: attribute.id }
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
end
