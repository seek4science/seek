require 'test_helper'
require 'minitest/mock'

class FileTemplatesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  include SharingFormTestHelper
  include MockHelper
  include HtmlHelper
  include GeneralAuthorizationTestCases

  test 'should return 406 when requesting RDF' do
    login_as(FactoryBot.create(:user))
    ft = FactoryBot.create :file_template, contributor: User.current_user.person
    assert ft.can_view?

    get :show, params: { id: ft, format: :rdf }

    assert_response :not_acceptable
  end

  test 'should get index' do
    FactoryBot.create_list(:public_file_template, 3)

    get :index

    assert_response :success
    assert assigns(:file_templates).any?
  end

  test "shouldn't show hidden items in index" do
    visible_ft = FactoryBot.create(:public_file_template)
    hidden_ft = FactoryBot.create(:private_file_template)

    get :index, params: { page: 'all' }

    assert_response :success
    assert_includes assigns(:file_templates), visible_ft
    assert_not_includes assigns(:file_templates), hidden_ft
  end

  test 'should show' do
    visible_ft = FactoryBot.create(:public_file_template)

    get :show, params: { id: visible_ft }

    assert_response :success
  end

  test 'should not show hidden file template' do
    hidden_ft = FactoryBot.create(:private_file_template)

    get :show, params: { id: hidden_ft }

    assert_response :forbidden
  end

  test 'should get new' do
    login_as(FactoryBot.create(:person))

    get :new
    assert_response :success
    assert_select 'h1', text: "New #{I18n.t('file_template')}"
  end

  test 'should get edit' do
    login_as(FactoryBot.create(:person))

    get :new
    assert_response :success
    assert_select 'h1', text: "New #{I18n.t('file_template')}"
  end

  test 'should create file template' do
    FactoryBot.create(:data_types_controlled_vocab) unless SampleControlledVocab::SystemVocabs.data_types_controlled_vocab
    FactoryBot.create(:data_formats_controlled_vocab) unless SampleControlledVocab::SystemVocabs.data_formats_controlled_vocab
    person = FactoryBot.create(:person)
    login_as(person)

    assert_difference('ActivityLog.count') do
      assert_difference('FileTemplate.count') do
        assert_difference('FileTemplate::Version.count') do
          assert_difference('ContentBlob.count') do
            post :create, params: { file_template: { title: 'File Template', project_ids: [person.projects.first.id], data_format_annotations:['JSON'], data_type_annotations:['Sequence features metadata'] }, content_blobs: [valid_content_blob], policy_attributes: valid_sharing }
          end
        end
      end
    end

    template = assigns(:file_template)
    assert_redirected_to file_template_path(template)

    assert_equal ['http://edamontology.org/data_2914'], template.data_type_annotations
    assert_equal ['http://edamontology.org/format_3464'], template.data_format_annotations
  end

  test 'should create file template version' do
    ft = FactoryBot.create(:file_template)
    login_as(ft.contributor)

    assert_difference('ActivityLog.count') do
      assert_no_difference('FileTemplate.count') do
        assert_difference('FileTemplate::Version.count') do
          assert_difference('ContentBlob.count') do
            post :create_version, params: { id: ft.id, content_blobs: [{ data: fixture_file_upload('little_file.txt') }], revision_comments: 'new version!' }
          end
        end
      end
    end

    assert_redirected_to file_template_path(assigns(:file_template))
    assert_equal 2, assigns(:file_template).version
    assert_equal 2, assigns(:file_template).versions.count
    assert_equal 'new version!', assigns(:file_template).latest_version.revision_comments
  end

  test 'should update file template' do
    FactoryBot.create(:data_types_controlled_vocab) unless SampleControlledVocab::SystemVocabs.data_types_controlled_vocab
    FactoryBot.create(:data_formats_controlled_vocab) unless SampleControlledVocab::SystemVocabs.data_formats_controlled_vocab

    person = FactoryBot.create(:person)
    ft = FactoryBot.create(:file_template, contributor: person)
    login_as(person)

    assert_difference('ActivityLog.count') do
      put :update, params: { id: ft.id, file_template: { title: 'Different title', project_ids: [person.projects.first.id], data_format_annotations: ['JSON'], data_type_annotations: ['Sequence features metadata']} }
    end

    template = assigns(:file_template)
    assert_redirected_to file_template_path(template)
    assert_equal 'Different title', template.title

    assert_equal ['http://edamontology.org/data_2914'], template.data_type_annotations
    assert_equal ['http://edamontology.org/format_3464'], template.data_format_annotations
  end

  test 'should destroy file template' do
    person = FactoryBot.create(:person)
    ft = FactoryBot.create(:file_template, contributor: person)
    login_as(person)

    assert_difference('FileTemplate.count', -1) do
      assert_no_difference('ContentBlob.count') do
        delete :destroy, params: { id: ft }
      end
    end

    assert_redirected_to file_templates_path
  end

  test 'should be able to view pdf content' do
    ft = FactoryBot.create(:public_file_template)
    assert ft.content_blob.is_content_viewable?
    get :show, params: { id: ft.id }
    assert_response :success
    assert_select 'a', text: /View content/, count: 1
  end

  test "people file_templates through nested routing" do
    assert_routing 'people/2/file_templates', controller: 'file_templates', action: 'index', person_id: '2'
    person = FactoryBot.create(:person)
    login_as(person)
    ft = FactoryBot.create(:file_template,contributor:person)
    ft2 = FactoryBot.create(:file_template, policy: FactoryBot.create(:public_policy),contributor:FactoryBot.create(:person))


    get :index, params: { person_id: person.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]',file_template_path(ft), text: ft.title
      assert_select 'a[href=?]', file_template_path(ft2), text: ft2.title, count: 0
    end
  end

  test "project file templates through nested routing" do
    assert_routing 'projects/2/file_templates', controller: 'file_templates', action: 'index', project_id: '2'
    person = FactoryBot.create(:person)
    login_as(person)
    ft = FactoryBot.create(:file_template,contributor:person)
    ft2 = FactoryBot.create(:file_template,policy: FactoryBot.create(:public_policy),contributor:FactoryBot.create(:person))


    get :index, params: { project_id: person.projects.first.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', file_template_path(ft), text: ft.title
      assert_select 'a[href=?]', file_template_path(ft2), text: ft2.title, count: 0
    end
  end

  test 'manage menu item appears according to permission' do
    check_manage_edit_menu_for_type('file_template')
  end

  test 'can access manage page with manage rights' do
    person = FactoryBot.create(:person)
    ft = FactoryBot.create(:file_template, contributor:person)
    login_as(person)
    assert ft.can_manage?
    get :manage, params: {id: ft}
    assert_response :success

    # check the project form exists
    assert_select 'div#add_projects_form', count:1

    # check sharing form exists
    assert_select 'div#sharing_form', count:1

    # should be a temporary sharing link
    assert_select 'div#temporary_links', count:1

#    assert_select 'div#author-form', count:1
  end

  test 'cannot access manage page with edit rights' do
    person = FactoryBot.create(:person)
    ft = FactoryBot.create(:file_template, policy:FactoryBot.create(:private_policy, permissions:[FactoryBot.create(:permission, contributor:person, access_type:Policy::EDITING)]))
    login_as(person)
    assert ft.can_edit?
    refute ft.can_manage?
    get :manage, params: {id: ft}
    assert_redirected_to ft
    refute_nil flash[:error]
  end

  test 'create with no creators' do
    person = FactoryBot.create(:person)
    login_as(person)
    ft = {title: 'FileTemplate', project_ids: [person.projects.first.id], creator_ids: []}
    assert_difference('FileTemplate.count') do
      post :create, params: {file_template: ft, content_blobs: [{data: file_for_upload}], policy_attributes: {access_type: Policy::VISIBLE}}
    end

    ft = assigns(:file_template)
    assert_empty ft.creators
  end

  test 'update with no creators' do
    person = FactoryBot.create(:person)
    creators = [FactoryBot.create(:person), FactoryBot.create(:person)]
    ft = FactoryBot.create(:file_template, contributor: person, creators:creators)

    assert_equal creators.sort, ft.creators.sort
    login_as(person)

    assert ft.can_manage?


    patch :manage_update,
          params: {id: ft,
                   file_template: {
                       title:'changed title',
                       creator_ids:[""]
                   }
          }

    assert_redirected_to file_template_path(ft = assigns(:file_template))
    assert_equal 'changed title', ft.title
    assert_empty ft.creators
  end

  test 'manage_update' do
    proj1=FactoryBot.create(:project)
    proj2=FactoryBot.create(:project)
    person = FactoryBot.create(:person,project:proj1)
    other_person = FactoryBot.create(:person)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!
    other_creator = FactoryBot.create(:person,project:proj1)
    other_creator.add_to_project_and_institution(proj2,other_creator.institutions.first)
    other_creator.save!

    ft = FactoryBot.create(:file_template, contributor:person, projects:[proj1], policy:FactoryBot.create(:private_policy))

    login_as(person)
    assert ft.can_manage?

    patch :manage_update, params: {id: ft,
                                   file_template: {
                                       creator_ids: [other_creator.id],
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    assert_redirected_to ft

    ft.reload
    assert_equal [proj1,proj2],ft.projects.sort_by(&:id)
    assert_equal [other_creator],ft.creators
    assert_equal Policy::VISIBLE,ft.policy.access_type
    assert_equal 1,ft.policy.permissions.count
    assert_equal other_person,ft.policy.permissions.first.contributor
    assert_equal Policy::MANAGING,ft.policy.permissions.first.access_type

  end

  test 'manage_update fails without manage rights' do
    proj1=FactoryBot.create(:project)
    proj2=FactoryBot.create(:project)
    person = FactoryBot.create(:person, project:proj1)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!

    other_person = FactoryBot.create(:person)

    other_creator = FactoryBot.create(:person,project:proj1)
    other_creator.add_to_project_and_institution(proj2,other_creator.institutions.first)
    other_creator.save!

    ft = FactoryBot.create(:file_template, projects:[proj1], policy:FactoryBot.create(:private_policy,
                                                         permissions:[FactoryBot.create(:permission,contributor:person, access_type:Policy::EDITING)]))

    login_as(person)
    refute ft.can_manage?
    assert ft.can_edit?

    assert_equal [proj1],ft.projects
    assert_empty ft.creators

    patch :manage_update, params: {id: ft,
                                   file_template: {
                                       creator_ids: [other_creator.id],
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    refute_nil flash[:error]

    ft.reload
    assert_equal [proj1],ft.projects
    assert_empty ft.creators
    assert_equal Policy::PRIVATE,ft.policy.access_type
    assert_equal 1,ft.policy.permissions.count
    assert_equal person,ft.policy.permissions.first.contributor
    assert_equal Policy::EDITING,ft.policy.permissions.first.access_type
  end

  test 'numeric pagination' do
    FactoryBot.create_list(:public_file_template, 20)

    with_config_value(:results_per_page_default, 5) do
      get :index

      assert_equal 5, assigns(:file_templates).length
      assert_equal '1', assigns(:page)
      assert_equal 5, assigns(:per_page)
      assert_select '.pagination-container a', href: file_templates_path(page: 2), text: /Next/
      assert_select '.pagination-container a', href: file_templates_path(page: 2), text: /2/
      assert_select '.pagination-container a', href: file_templates_path(page: 3), text: /3/

      get :index, params: { page: 2 }

      assert_equal 5, assigns(:file_templates).length
      assert_equal '2', assigns(:page)
      assert_select '.pagination-container a', href: file_templates_path(page: 3), text: /Next/
      assert_select '.pagination-container a', href: file_templates_path(page: 1), text: /Previous/
      assert_select '.pagination-container a', href: file_templates_path(page: 1), text: /1/
      assert_select '.pagination-container a', href: file_templates_path(page: 3), text: /3/
    end
  end

  test 'user can change results per page' do
    FactoryBot.create_list(:public_file_template, 15)

    with_config_value(:results_per_page_default, 5) do
      get :index, params: { per_page: 15 }
      assert_equal 15, assigns(:file_templates).length
      assert_equal '1', assigns(:page)
      assert_equal 15, assigns(:per_page)
      assert_select '.pagination-container a', text: /Next/, count: 0

      get :index, params: { per_page: 15, page: 2 }
      assert_equal 0, assigns(:file_templates).length
      assert_equal '2', assigns(:page)
      assert_equal 15, assigns(:per_page)
      assert_select '.pagination-container a', text: /Next/, count: 0
    end
  end

  test 'show filters on index' do
    FactoryBot.create(:public_file_template)

    get :index
    assert_select '.index-filters', count: 1
  end

  test 'do not show filters on index if disabled' do
    FactoryBot.create(:public_file_template)

    with_config_value(:filtering_enabled, false) do
      get :index
      assert_select '.index-filters', count: 0
    end
  end

  test 'available filters are listed' do
    project = FactoryBot.create(:project)
    project_doc = FactoryBot.create(:public_file_template, created_at: 3.days.ago, projects: [project])
    project_doc.annotate_with('awkward&id=1unsafe[]tag !', 'tag', project_doc.contributor)
    disable_authorization_checks { project_doc.save! }
    old_project_doc = FactoryBot.create(:public_file_template, created_at: 10.years.ago, projects: [project])
    other_project = FactoryBot.create(:project)
    other_project_doc = FactoryBot.create(:public_file_template, created_at: 3.days.ago, projects: [other_project])
    FactoryBot.create_list(:public_file_template, 5, projects: [project])

    get :index

    assert_equal 8, assigns(:available_filters)[:contributor].length
    assert_equal 2, assigns(:available_filters)[:project].length

    assert_select '.filter-category[data-filter-category="query"]' do
      assert_select '.filter-category-title', text: 'Query'
      assert_select '.filter-option-field-clear', count: 0
    end

    assert_select '.filter-category[data-filter-category="project"]' do
      assert_select '.filter-category-title', text: 'Project'
      assert_select '.filter-option', count: 2
      assert_select '.filter-option.filter-option-active', count: 0
      assert_select ".filter-option[title='#{project.title}']" do
        assert_select '[href=?]', file_templates_path(filter: { project: project.id })
        assert_select '.filter-option-label', text: project.title
        assert_select '.filter-option-count', text: '7'
      end
      assert_select ".filter-option[title='#{other_project.title}']" do
        assert_select '[href=?]', file_templates_path(filter: { project: other_project.id })
        assert_select '.filter-option-label', text: other_project.title
        assert_select '.filter-option-count', text: '1'
      end
      assert_select '.expand-filter-category-link', count: 0
    end

    assert_select '.filter-category[data-filter-category="contributor"]' do
      assert_select '.filter-category-title', text: 'Submitter'
      assert_select '.filter-option', href: /file_templates\?filter\[contributor\]=\d+/, count: 8
      assert_select '.filter-option.filter-option-active', count: 0
      # Should show 6 options and hide the rest
      assert_select '.filter-option.filter-option-hidden', count: 2
      assert_select '.expand-filter-category-link', count: 1
    end

    assert_select '.filter-category[data-filter-category="tag"]' do
      assert_select '.filter-category-title', text: 'Tag'
      assert_select '.filter-option', count: 1
      assert_select '.filter-option.filter-option-active', count: 0
      assert_select ".filter-option[title='awkward&id=1unsafe[]tag !']" do
        assert_select '.filter-option-label', text: 'awkward&id=1unsafe[]tag !'
        assert_select '.filter-option-count', text: '1'
      end
    end

    assert_select '.active-filters', count: 0
    assert_select 'a[href=?]', file_templates_path, text: /Clear all filters/, count: 0
  end

  test 'active filters are listed' do
    programme = FactoryBot.create(:programme)
    project = FactoryBot.create(:project, programme: programme)
    project_doc = FactoryBot.create(:public_file_template, created_at: 3.days.ago, projects: [project])
    project_doc.annotate_with('awkward&id=1unsafe[]tag !', 'tag', project_doc.contributor)
    disable_authorization_checks { project_doc.save! }
    old_project_doc = FactoryBot.create(:public_file_template, created_at: 10.years.ago, projects: [project])
    other_project = FactoryBot.create(:project, programme: programme)
    other_project_doc = FactoryBot.create(:public_file_template, created_at: 3.days.ago, projects: [other_project])
    FactoryBot.create_list(:public_file_template, 5, projects: [project])

    get :index, params: { filter: { programme: programme.id, project: other_project.id } }

    assert_equal 1, assigns(:available_filters)[:contributor].length
    assert_equal 2, assigns(:available_filters)[:project].length

    assert_select '.filter-category[data-filter-category="query"]' do
      assert_select '.filter-category-title', text: 'Query'
    end

    # Should show other project in projects category
    assert_select '.filter-category[data-filter-category="project"]' do
      assert_select '.filter-category-title', text: 'Project'
      assert_select '.filter-option.filter-option-active', count: 1
      assert_select '.filter-option', count: 2
      assert_select ".filter-option[title='#{project.title}']" do
        assert_select '[href=?]', file_templates_path(filter: { programme: programme.id, project: [other_project.id, project.id] })
        assert_select '.filter-option-label', text: project.title
        assert_select '.filter-option-count', text: '7'
      end
      assert_select ".filter-option[title='#{other_project.title}'].filter-option-active" do
        assert_select '[href=?]', file_templates_path(filter: { programme: programme.id })
        assert_select '.filter-option-label', text: other_project.title
        assert_select '.filter-option-count', text: '1'
      end
      assert_select '.expand-filter-category-link', count: 0
    end

    assert_select '.filter-category[data-filter-category="contributor"]' do
      assert_select '.filter-category-title', text: 'Submitter'
      assert_select '.filter-option', count: 1
      assert_select '.filter-option.filter-option-active', count: 0
      assert_select '.filter-option.filter-option-hidden', count: 0
      assert_select ".filter-option[title='#{other_project_doc.contributor.name}']" do
        # Note if this check ever fails for an unknown reason, check the ordering of the filter parameters
        assert_select '[href=?]', file_templates_path(filter: { programme: programme.id,
                                                           contributor: other_project_doc.contributor.id,
                                                           project: other_project.id })
      end
      assert_select '.filter-option-label', text: other_project_doc.contributor.name
      assert_select '.filter-option-count', text: '1'
      assert_select '.expand-filter-category-link', count: 0
    end

    # Nothing in the filtered set has a tag, so the whole category should be hidden
    assert_select '.filter-category[data-filter-category="tag"]', count: 0

    assert_select '.active-filters' do
      assert_select '.active-filter-category-title', count: 2
      assert_select ".filter-option[title='#{programme.title}'].filter-option-active" do
        assert_select '[href=?]', file_templates_path(filter: { project: other_project.id })
        assert_select '.filter-option-label', text: programme.title
      end
      assert_select ".filter-option[title='#{other_project.title}'].filter-option-active" do
        assert_select '[href=?]', file_templates_path(filter: { programme: programme.id })
        assert_select '.filter-option-label', text: other_project.title
      end
    end

    assert_select 'a[href=?]', file_templates_path, text: /Clear all filters/
  end

  test 'filtering system obeys authorization and does not leak info on private resources' do
    programme = FactoryBot.create(:programme)
    project = FactoryBot.create(:project, programme: programme)
    FactoryBot.create_list(:public_file_template, 3, projects: [project])
    private_file_template = FactoryBot.create(:private_file_template, created_at: 2.years.ago, projects: [project])
    private_file_template.annotate_with('awkward&id=1unsafe[]tag !', 'tag', private_file_template.contributor)
    disable_authorization_checks { private_file_template.save! }

    get :index, params: { filter: { programme: programme.id } }

    assert_equal 3, assigns(:file_templates).length
    assert_not_includes assigns(:file_templates), private_file_template
    assert_equal 3, assigns(:available_filters)[:contributor].length
    assert_equal 1, assigns(:available_filters)[:project].length
    assert_equal 0, assigns(:available_filters)[:tag].length
    assert_select '.filter-category[data-filter-category="created_at"]' do
      assert_select '.filter-option-dropdown' do
        assert_select 'option[value="PT24H"]', text: 'in the last 24 hours (3)'
        assert_select 'option[value="P1W"]', text: 'in the last 1 week (3)'
        assert_select 'option[value="P1M"]', text: 'in the last 1 month (3)'
        assert_select 'option[value="P1Y"]', text: 'in the last 1 year (3)'
        assert_select 'option[value="P5Y"]', text: 'in the last 5 years (3)'
      end
    end

    get :index, params: { filter: { programme: programme.id, tag: ['awkward&id=1unsafe[]tag !'] } }

    assert_empty assigns(:file_templates)
    assert_equal 1, assigns(:available_filters)[:programme].length
    assert_equal 1, assigns(:active_filters)[:programme].length
    assert_equal 1, assigns(:available_filters)[:tag].length
    assert_equal 1, assigns(:active_filters)[:tag].length

    login_as(private_file_template.contributor)

    get :index, params: { filter: { programme: programme.id } }

    assert_equal 4, assigns(:file_templates).length
    assert_equal 4, assigns(:available_filters)[:contributor].length
    assert_equal 1, assigns(:available_filters)[:project].length
    assert_equal 1, assigns(:available_filters)[:tag].length
    assert_select '.filter-category[data-filter-category="created_at"]' do
      assert_select '.filter-option-dropdown' do
        assert_select 'option[value="PT24H"]', text: 'in the last 24 hours (3)'
        assert_select 'option[value="P1W"]', text: 'in the last 1 week (3)'
        assert_select 'option[value="P1M"]', text: 'in the last 1 month (3)'
        assert_select 'option[value="P1Y"]', text: 'in the last 1 year (3)'
        assert_select 'option[value="P5Y"]', text: 'in the last 5 years (4)'
      end
    end

    get :index, params: { filter: { programme: programme.id, tag: ['awkward&id=1unsafe[]tag !'] } }

    assert_equal 1, assigns(:file_templates).length
    assert_includes assigns(:file_templates), private_file_template
  end

  test 'filtering with search terms' do
    programme = FactoryBot.create(:programme)
    project = FactoryBot.create(:project, programme: programme)
    FactoryBot.create_list(:public_file_template, 3, projects: [project])

    get :index, params: { filter: { programme: programme.id, query: 'hello' } }

    assert_empty assigns(:file_templates)
    assert_equal 1, assigns(:available_filters)[:programme].length
    assert_equal 1, assigns(:active_filters)[:programme].length
    assert_equal 1, assigns(:available_filters)[:query].count
    assert_equal 1, assigns(:active_filters)[:query].count

    assert_select '.filter-category', count: 2

    assert_select '.filter-category[data-filter-category="query"]' do
      assert_select '.filter-category-title', text: 'Query'
      assert_select '#filter-search-field[value=?]', 'hello'
      assert_select '.filter-option-field-clear', count: 1, href: file_templates_path(filter: { programme: programme.id })
    end

    assert_select '.active-filters' do
      assert_select ".filter-option[title='hello'].filter-option-active" do
        assert_select '[href=?]', file_templates_path(filter: { programme: programme.id })
        assert_select '.filter-option-label', text: 'hello'
      end
      assert_select ".filter-option[title='#{programme.title}'].filter-option-active" do
        assert_select '[href=?]', file_templates_path(filter: { query: 'hello' })
        assert_select '.filter-option-label', text: programme.title
      end
    end
  end

  test 'filtering by creation date' do
    programme = FactoryBot.create(:programme)
    project = FactoryBot.create(:project, programme: programme)
    FactoryBot.create_list(:public_file_template, 1, projects: [project], created_at: 1.hour.ago)
    FactoryBot.create_list(:public_file_template, 2, projects: [project], created_at: 2.days.ago) # 3
    FactoryBot.create_list(:public_file_template, 3, projects: [project], created_at: 2.weeks.ago) # 6
    FactoryBot.create_list(:public_file_template, 4, projects: [project], created_at: 2.months.ago) # 10
    FactoryBot.create_list(:public_file_template, 5, projects: [project], created_at: 2.years.ago) # 15
    FactoryBot.create_list(:public_file_template, 6, projects: [project], created_at: 10.years.ago) # 21

    # No creation date filter
    get :index, params: { filter: { programme: programme.id } }

    assert_equal 21, assigns(:visible_count)
    assert_select '.filter-category[data-filter-category="created_at"]' do
      assert_select '.filter-category-title', text: 'Created At'
      assert_select '.filter-option-dropdown' do
        assert_select "option[value='other']", text: 'Other', count: 0
        assert_select 'option[value="custom"]', text: 'Custom range'
        assert_select 'option[value=""]', text: 'Any time'
        assert_select 'option[value="PT24H"]', text: 'in the last 24 hours (1)'
        assert_select 'option[value="P1W"]', text: 'in the last 1 week (3)'
        assert_select 'option[value="P1M"]', text: 'in the last 1 month (6)'
        assert_select 'option[value="P1Y"]', text: 'in the last 1 year (10)'
        assert_select 'option[value="P5Y"]', text: 'in the last 5 years (15)'
      end
    end

    # Preset duration filter
    get :index, params: { filter: { programme: programme.id, created_at: 'P1M' } }

    assert_equal 6, assigns(:visible_count)
    assert_select '.filter-category[data-filter-category="created_at"]' do
      assert_select '.filter-category-title', text: 'Created At'
      assert_select '.filter-option-dropdown' do
        assert_select 'option[value="custom"]', text: 'Custom range'
        assert_select 'option[value=""]', text: 'Any time'
        assert_select 'option[value="PT24H"]', text: 'in the last 24 hours (1)'
        assert_select 'option[value="P1W"]', text: 'in the last 1 week (3)'
        assert_select "option[value='P1M'][selected='selected']", text: 'in the last 1 month (6)'
        assert_select 'option[value="P1Y"]', text: 'in the last 1 year (10)'
        assert_select 'option[value="P5Y"]', text: 'in the last 5 years (15)'
      end
    end
    assert_select '.active-filters' do
      assert_select ".filter-option[title='#{programme.title}'].filter-option-active" do
        assert_select '[href=?]', file_templates_path(filter: { created_at: 'P1M' })
        assert_select '.filter-option-label', text: programme.title
      end
      assert_select ".filter-option[title='in the last 1 month'].filter-option-active" do
        assert_select '[href=?]', file_templates_path(filter: { programme: programme.id })
        assert_select '.filter-option-label', text: 'in the last 1 month'
      end
    end

    # Custom single date
    date = 1.year.ago.to_date.iso8601
    get :index, params: { filter: { programme: programme.id, created_at: date } }

    assert_equal 10, assigns(:visible_count)
    assert_select '.filter-category[data-filter-category="created_at"]' do
      assert_select '.filter-category-title', text: 'Created At'
      assert_select '.filter-option-dropdown' do
        assert_select "option[value='custom'][selected='selected']", text: 'Custom range'
        assert_select 'option[value=""]', text: 'Any time'
        assert_select 'option[value="PT24H"]', text: 'in the last 24 hours (1)'
        assert_select 'option[value="P1W"]', text: 'in the last 1 week (3)'
        assert_select "option[value='P1M']", text: 'in the last 1 month (6)'
        assert_select 'option[value="P1Y"]', text: 'in the last 1 year (10)'
        assert_select 'option[value="P5Y"]', text: 'in the last 5 years (15)'
      end
      assert_select '[data-role="seek-date-filter-period-start"]' do
        assert_select '[value=?]', date
      end
    end
    assert_select '.active-filters' do
      assert_select ".filter-option[title='#{programme.title}'].filter-option-active" do
        assert_select '[href=?]', file_templates_path(filter: { created_at: date })
        assert_select '.filter-option-label', text: programme.title
      end
      assert_select ".filter-option[title='since #{date}'].filter-option-active" do
        assert_select '[href=?]', file_templates_path(filter: { programme: programme.id })
        assert_select '.filter-option-label', text: "since #{date}"
      end
    end

    # Custom date range
    start_date = 3.years.ago.to_date.iso8601
    end_date = 3.weeks.ago.to_date.iso8601
    range = "#{start_date}/#{end_date}"
    get :index, params: { filter: { programme: programme.id, created_at: range } }

    assert_equal 9, assigns(:visible_count)
    assert_select '.filter-category[data-filter-category="created_at"]' do
      assert_select '.filter-category-title', text: 'Created At'
      assert_select '.filter-option-dropdown' do
        assert_select "option[value='custom'][selected='selected']", text: 'Custom range'
        assert_select 'option[value=""]', text: 'Any time'
        assert_select 'option[value="PT24H"]', text: 'in the last 24 hours (1)'
        assert_select 'option[value="P1W"]', text: 'in the last 1 week (3)'
        assert_select "option[value='P1M']", text: 'in the last 1 month (6)'
        assert_select 'option[value="P1Y"]', text: 'in the last 1 year (10)'
        assert_select 'option[value="P5Y"]', text: 'in the last 5 years (15)'
      end
      assert_select '[data-role="seek-date-filter-period-start"]' do
        assert_select '[value=?]', start_date
      end
      assert_select '[data-role="seek-date-filter-period-end"]' do
        assert_select '[value=?]', end_date
      end
    end
    assert_select '.active-filters' do
      assert_select ".filter-option[title='#{programme.title}'].filter-option-active" do
        assert_select '[href=?]', file_templates_path(filter: { created_at: range })
        assert_select '.filter-option-label', text: programme.title
      end
      assert_select ".filter-option[title='between #{start_date} and #{end_date}'].filter-option-active" do
        assert_select '[href=?]', file_templates_path(filter: { programme: programme.id })
        assert_select '.filter-option-label', text: "between #{start_date} and #{end_date}"
      end
    end

    # Custom duration
    get :index, params: { filter: { programme: programme.id, created_at: 'P3D' } }

    assert_equal 3, assigns(:visible_count)
    assert_select '.filter-category[data-filter-category="created_at"]' do
      assert_select '.filter-category-title', text: 'Created At'
      assert_select '.filter-option-dropdown' do
        assert_select "option[value='other'][selected='selected']", text: 'Other'
        assert_select "option[value='custom']", text: 'Custom range'
        assert_select 'option[value=""]', text: 'Any time'
        assert_select 'option[value="PT24H"]', text: 'in the last 24 hours (1)'
        assert_select 'option[value="P1W"]', text: 'in the last 1 week (3)'
        assert_select "option[value='P1M']", text: 'in the last 1 month (6)'
        assert_select 'option[value="P1Y"]', text: 'in the last 1 year (10)'
        assert_select 'option[value="P5Y"]', text: 'in the last 5 years (15)'
      end
    end
    assert_select '.active-filters' do
      assert_select ".filter-option[title='#{programme.title}'].filter-option-active" do
        assert_select '[href=?]', file_templates_path(filter: { created_at: 'P3D' })
        assert_select '.filter-option-label', text: programme.title
      end
      assert_select ".filter-option[title='in the last 3 days'].filter-option-active" do
        assert_select '[href=?]', file_templates_path(filter: { programme: programme.id })
        assert_select '.filter-option-label', text: "in the last 3 days"
      end
    end

    # Complex query
    start_date = 12.years.ago.to_date.iso8601
    end_date = 9.years.ago.to_date.iso8601
    range = "#{start_date}/#{end_date}"
    get :index, params: { filter: { programme: programme.id, created_at: ['PT2H3M', range] } }

    assert_equal 7, assigns(:visible_count)
    assert_select '.filter-category[data-filter-category="created_at"]' do
      assert_select '.filter-category-title', text: 'Created At'
      assert_select '.filter-option-dropdown' do
        assert_select "option[value='other'][selected='selected']", text: 'Other'
        assert_select "option[value='custom']", text: 'Custom range'
        assert_select 'option[value=""]', text: 'Any time'
        assert_select 'option[value="PT24H"]', text: 'in the last 24 hours (1)'
        assert_select 'option[value="P1W"]', text: 'in the last 1 week (3)'
        assert_select "option[value='P1M']", text: 'in the last 1 month (6)'
        assert_select 'option[value="P1Y"]', text: 'in the last 1 year (10)'
        assert_select 'option[value="P5Y"]', text: 'in the last 5 years (15)'
      end
    end
    assert_select '.active-filters' do
      assert_select ".filter-option[title='#{programme.title}'].filter-option-active" do
        assert_select '[href=?]', file_templates_path(filter: { created_at: ['PT2H3M', range] })
        assert_select '.filter-option-label', text: programme.title
      end
      assert_select ".filter-option[title='in the last 2 hours and 3 minutes'].filter-option-active" do
        assert_select '[href=?]', file_templates_path(filter: { programme: programme.id, created_at: range })
        assert_select '.filter-option-label', text: "in the last 2 hours and 3 minutes"
      end
      assert_select ".filter-option[title='between #{start_date} and #{end_date}'].filter-option-active" do
        assert_select '[href=?]', file_templates_path(filter: { programme: programme.id, created_at: 'PT2H3M' })
        assert_select '.filter-option-label', text: "between #{start_date} and #{end_date}"
      end
    end
  end

  test 'filter and sort' do
    programme = FactoryBot.create(:programme)
    project = FactoryBot.create(:project, programme: programme)
    other_project = FactoryBot.create(:project, programme: programme)
    project_doc = FactoryBot.create(:public_file_template, created_at: 3.days.ago, projects: [project])
    old_project_doc = FactoryBot.create(:public_file_template, created_at: 10.years.ago, projects: [project])
    other_project_doc = FactoryBot.create(:public_file_template, created_at: 2.days.ago, projects: [other_project])

    get :index, params: { filter: { programme: programme.id }, order: 'created_at_asc' }
    assert_equal [old_project_doc, project_doc, other_project_doc], assigns(:file_templates).to_a

    get :index, params: { filter: { programme: programme.id }, order: 'created_at_desc' }
    assert_equal [other_project_doc, project_doc, old_project_doc], assigns(:file_templates).to_a

    get :index, params: { filter: { programme: programme.id, project: project.id }, order: 'created_at_asc' }
    assert_equal [old_project_doc, project_doc], assigns(:file_templates).to_a

    get :index, params: { filter: { programme: programme.id, project: project.id }, order: 'created_at_desc' }
    assert_equal [project_doc, old_project_doc], assigns(:file_templates).to_a
  end

  test 'should create with discussion link' do
    person = FactoryBot.create(:person)
    login_as(person)
    file_template =  {title: 'FileTemplate', project_ids: [person.projects.first.id], discussion_links_attributes:[{url: "http://www.slack.com/", label:'our slack'}]}
    assert_difference('AssetLink.discussion.count') do
      assert_difference('FileTemplate.count') do
        assert_difference('ContentBlob.count') do
          post :create, params: {file_template: file_template, content_blobs: [{ data: file_for_upload }], policy_attributes: { access_type: Policy::VISIBLE }}
        end
      end
    end
    file_template = assigns(:file_template)
    assert_equal 'http://www.slack.com/', file_template.discussion_links.first.url
    assert_equal 'our slack', file_template.discussion_links.first.label
    assert_equal AssetLink::DISCUSSION, file_template.discussion_links.first.link_type
  end

  test 'should show discussion link with label' do
    asset_link = FactoryBot.create(:discussion_link, label:'discuss-label')
    file_template = FactoryBot.create(:file_template, discussion_links: [asset_link], policy: FactoryBot.create(:public_policy, access_type: Policy::VISIBLE))
    assert_equal [asset_link],file_template.discussion_links
    get :show, params: { id: file_template }
    assert_response :success
    assert_select 'div.panel-heading', text: /Discussion Channel/, count: 1
    assert_select 'div.discussion-link', count:1 do
      assert_select 'a[href=?]',asset_link.url,text:'discuss-label'
    end
  end

  test 'should show discussion link without label' do
    asset_link = FactoryBot.create(:discussion_link)
    file_template = FactoryBot.create(:file_template, discussion_links: [asset_link], policy: FactoryBot.create(:public_policy, access_type: Policy::VISIBLE))
    assert_equal [asset_link],file_template.discussion_links
    get :show, params: { id: file_template }
    assert_response :success
    assert_select 'div.panel-heading', text: /Discussion Channel/, count: 1
    assert_select 'div.discussion-link', count:1 do
      assert_select 'a[href=?]',asset_link.url,text:asset_link.url
    end

    #blank rather than nil
    asset_link.update_column(:label,'')
    file_template.reload
    assert_equal [asset_link],file_template.discussion_links
    get :show, params: { id: file_template }
    assert_response :success
    assert_select 'div.panel-heading', text: /Discussion Channel/, count: 1
    assert_select 'div.discussion-link', count:1 do
      assert_select 'a[href=?]',asset_link.url,text:asset_link.url
    end
  end

  test 'should update file_template with new discussion link' do
    person = FactoryBot.create(:person)
    file_template = FactoryBot.create(:file_template, contributor: person)
    login_as(person)
    assert_nil file_template.discussion_links.first
    assert_difference('AssetLink.discussion.count') do
      assert_difference('ActivityLog.count') do
        put :update, params: { id: file_template.id, file_template: { discussion_links_attributes:[{url: "http://www.slack.com/", label:'our slack'}] } }
      end
    end
    assert_redirected_to file_template_path(file_template = assigns(:file_template))
    assert_equal 'http://www.slack.com/', file_template.discussion_links.first.url
    assert_equal 'our slack', file_template.discussion_links.first.label
  end

  test 'should update file_template with edited discussion link' do
    person = FactoryBot.create(:person)
    file_template = FactoryBot.create(:file_template, contributor: person, discussion_links:[FactoryBot.create(:discussion_link)])
    login_as(person)
    assert_equal 1,file_template.discussion_links.count
    assert_no_difference('AssetLink.discussion.count') do
      assert_difference('ActivityLog.count') do
        put :update, params: { id: file_template.id, file_template: { discussion_links_attributes:[{id:file_template.discussion_links.first.id, url: "http://www.wibble.com/"}] } }
      end
    end
    file_template = assigns(:file_template)
    assert_redirected_to file_template_path(file_template)
    assert_equal 1,file_template.discussion_links.count
    assert_equal 'http://www.wibble.com/', file_template.discussion_links.first.url
  end

  test 'do not get index if feature disabled' do
    with_config_value(:file_templates_enabled, false) do
      get :index
      assert_redirected_to root_path
      assert flash[:error].include?('disabled')
    end
  end

  def valid_content_blob
    { data: fixture_file_upload('a_pdf_file.pdf'), data_url: '' }
  end

end
