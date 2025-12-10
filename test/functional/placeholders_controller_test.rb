require 'test_helper'
require 'minitest/mock'

class PlaceholdersControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  include SharingFormTestHelper
  include MockHelper
  include HtmlHelper
  include GeneralAuthorizationTestCases

  test 'should return 406 when requesting RDF' do
    login_as(FactoryBot.create(:user))
    ft = FactoryBot.create :placeholder, contributor: User.current_user.person
    assert ft.can_view?

    get :show, params: { id: ft, format: :rdf }

    assert_response :not_acceptable
  end

  test 'should get index' do
    FactoryBot.create_list(:public_placeholder, 3)

    get :index

    assert_response :success
    assert assigns(:placeholders).any?
  end

  test "shouldn't show hidden items in index" do
    visible_ft = FactoryBot.create(:public_placeholder)
    hidden_ft = FactoryBot.create(:private_placeholder)

    get :index, params: { page: 'all' }

    assert_response :success
    assert_includes assigns(:placeholders), visible_ft
    assert_not_includes assigns(:placeholders), hidden_ft
  end

  test 'should show' do
    visible_ft = FactoryBot.create(:public_placeholder)

    get :show, params: { id: visible_ft }

    assert_response :success
  end

  test 'should not show hidden placeholder' do
    hidden_ft = FactoryBot.create(:private_placeholder)

    get :show, params: { id: hidden_ft }

    assert_response :forbidden
  end

  test 'should get new' do
    login_as(FactoryBot.create(:person))

    get :new
    assert_response :success
    assert_select 'h1', text: "New #{I18n.t('placeholder')}"
  end

  test 'should get edit' do
    login_as(FactoryBot.create(:person))

    get :new
    assert_response :success
    assert_select 'h1', text: "New #{I18n.t('placeholder')}"
  end

  test 'should create placeholder' do
    FactoryBot.create(:data_types_controlled_vocab) unless SampleControlledVocab::SystemVocabs.data_types_controlled_vocab
    FactoryBot.create(:data_formats_controlled_vocab) unless SampleControlledVocab::SystemVocabs.data_formats_controlled_vocab
    file_template = FactoryBot.create(:file_template)
    data_file = FactoryBot.create(:data_file)
    login_as(data_file.contributor)

    assert_difference('ActivityLog.count') do
      assert_difference('Placeholder.count') do
        post :create, params: { placeholder: { title: 'Placeholder', project_ids: [data_file.projects.first.id],
                                               data_format_annotations:['JSON'],
                                               data_type_annotations:['Sequence features metadata'] },
                                file_template_id: file_template.id,
                                data_file_id: data_file.id, policy_attributes: valid_sharing }
      end
    end

    placeholder = assigns(:placeholder)
    assert_redirected_to placeholder_path(placeholder)

    assert_equal ['http://edamontology.org/data_2914'], placeholder.data_type_annotations
    assert_equal ['http://edamontology.org/format_3464'], placeholder.data_format_annotations
    assert_equal data_file, placeholder.data_file
    assert_equal file_template, placeholder.file_template
  end

  test 'should update placeholder' do
    FactoryBot.create(:data_types_controlled_vocab) unless SampleControlledVocab::SystemVocabs.data_types_controlled_vocab
    FactoryBot.create(:data_formats_controlled_vocab) unless SampleControlledVocab::SystemVocabs.data_formats_controlled_vocab

    person = FactoryBot.create(:person)
    ft = FactoryBot.create(:placeholder, contributor: person)
    login_as(person)

    assert_difference('ActivityLog.count') do
      put :update, params: { id: ft.id, placeholder: { title: 'Different title', project_ids: [person.projects.first.id],
                                                       data_format_annotations: ['JSON'],
                                                       data_type_annotations: ['Sequence features metadata']} }
    end

    placeholder = assigns(:placeholder)
    assert_redirected_to placeholder_path(placeholder)
    assert_equal 'Different title', placeholder.title

    assert_equal ['http://edamontology.org/data_2914'], placeholder.data_type_annotations
    assert_equal ['http://edamontology.org/format_3464'], placeholder.data_format_annotations
  end

  test 'should destroy placeholder' do
    person = FactoryBot.create(:person)
    ft = FactoryBot.create(:placeholder, contributor: person)
    login_as(person)

    assert_difference('Placeholder.count', -1) do
      assert_no_difference('ContentBlob.count') do
        delete :destroy, params: { id: ft }
      end
    end

    assert_redirected_to placeholders_path
  end

  test "people placeholders through nested routing" do
    assert_routing 'people/2/placeholders', controller: 'placeholders', action: 'index', person_id: '2'
    person = FactoryBot.create(:person)
    login_as(person)
    ft = FactoryBot.create(:placeholder,contributor:person)
    ft2 = FactoryBot.create(:placeholder, policy: FactoryBot.create(:public_policy),contributor:FactoryBot.create(:person))


    get :index, params: { person_id: person.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]',placeholder_path(ft), text: ft.title
      assert_select 'a[href=?]', placeholder_path(ft2), text: ft2.title, count: 0
    end
  end

  test "project placeholders through nested routing" do
    assert_routing 'projects/2/placeholders', controller: 'placeholders', action: 'index', project_id: '2'
    person = FactoryBot.create(:person)
    login_as(person)
    ft = FactoryBot.create(:placeholder,contributor:person)
    ft2 = FactoryBot.create(:placeholder,policy: FactoryBot.create(:public_policy),contributor:FactoryBot.create(:person))


    get :index, params: { project_id: person.projects.first.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', placeholder_path(ft), text: ft.title
      assert_select 'a[href=?]', placeholder_path(ft2), text: ft2.title, count: 0
    end
  end

  test 'manage menu item appears according to permission' do
    check_manage_edit_menu_for_type('placeholder')
  end

  test 'can access manage page with manage rights' do
    person = FactoryBot.create(:person)
    ft = FactoryBot.create(:placeholder, contributor:person)
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
    ft = FactoryBot.create(:placeholder, policy:FactoryBot.create(:private_policy, permissions:[FactoryBot.create(:permission, contributor:person, access_type:Policy::EDITING)]))
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
    ft = {title: 'Placeholder', project_ids: [person.projects.first.id], creator_ids: []}
    assert_difference('Placeholder.count') do
      post :create, params: {placeholder: ft, content_blobs: [{data: file_for_upload}], policy_attributes: {access_type: Policy::VISIBLE}}
    end

    ft = assigns(:placeholder)
    assert_empty ft.creators
  end

  test 'update with no creators' do
    person = FactoryBot.create(:person)
    creators = [FactoryBot.create(:person), FactoryBot.create(:person)]
    ft = FactoryBot.create(:placeholder, contributor: person, creators:creators)

    assert_equal creators.sort, ft.creators.sort
    login_as(person)

    assert ft.can_manage?


    patch :manage_update,
          params: {id: ft,
                   placeholder: {
                     title:'changed title',
                     creator_ids:[""]
                   }
          }

    assert_redirected_to placeholder_path(ft = assigns(:placeholder))
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

    ft = FactoryBot.create(:placeholder, contributor:person, projects:[proj1], policy:FactoryBot.create(:private_policy))

    login_as(person)
    assert ft.can_manage?

    patch :manage_update, params: {id: ft,
                                   placeholder: {
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

    ft = FactoryBot.create(:placeholder, projects:[proj1], policy:FactoryBot.create(:private_policy,
                                                                                    permissions:[FactoryBot.create(:permission,contributor:person, access_type:Policy::EDITING)]))

    login_as(person)
    refute ft.can_manage?
    assert ft.can_edit?

    assert_equal [proj1],ft.projects
    assert_empty ft.creators

    patch :manage_update, params: {id: ft,
                                   placeholder: {
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
    FactoryBot.create_list(:public_placeholder, 20)

    with_config_value(:results_per_page_default, 5) do
      get :index

      assert_equal 5, assigns(:placeholders).length
      assert_equal '1', assigns(:page)
      assert_equal 5, assigns(:per_page)
      assert_select '.pagination-container a', href: placeholders_path(page: 2), text: /Next/
      assert_select '.pagination-container a', href: placeholders_path(page: 2), text: /2/
      assert_select '.pagination-container a', href: placeholders_path(page: 3), text: /3/

      get :index, params: { page: 2 }

      assert_equal 5, assigns(:placeholders).length
      assert_equal '2', assigns(:page)
      assert_select '.pagination-container a', href: placeholders_path(page: 3), text: /Next/
      assert_select '.pagination-container a', href: placeholders_path(page: 1), text: /Previous/
      assert_select '.pagination-container a', href: placeholders_path(page: 1), text: /1/
      assert_select '.pagination-container a', href: placeholders_path(page: 3), text: /3/
    end
  end

  test 'user can change results per page' do
    FactoryBot.create_list(:public_placeholder, 15)

    with_config_value(:results_per_page_default, 5) do
      get :index, params: { per_page: 15 }
      assert_equal 15, assigns(:placeholders).length
      assert_equal '1', assigns(:page)
      assert_equal 15, assigns(:per_page)
      assert_select '.pagination-container a', text: /Next/, count: 0

      get :index, params: { per_page: 15, page: 2 }
      assert_equal 0, assigns(:placeholders).length
      assert_equal '2', assigns(:page)
      assert_equal 15, assigns(:per_page)
      assert_select '.pagination-container a', text: /Next/, count: 0
    end
  end

  test 'show filters on index' do
    FactoryBot.create(:public_placeholder)

    get :index
    assert_select '.index-filters', count: 1
  end

  test 'do not show filters on index if disabled' do
    FactoryBot.create(:public_placeholder)

    with_config_value(:filtering_enabled, false) do
      get :index
      assert_select '.index-filters', count: 0
    end
  end

  test 'available filters are listed' do
    project = FactoryBot.create(:project)
    project_doc = FactoryBot.create(:public_placeholder, created_at: 3.days.ago, projects: [project])
    project_doc.annotate_with('awkward&id=1unsafe[]tag !', 'tag', project_doc.contributor)
    disable_authorization_checks { project_doc.save! }
    old_project_doc = FactoryBot.create(:public_placeholder, created_at: 10.years.ago, projects: [project])
    other_project = FactoryBot.create(:project)
    other_project_doc = FactoryBot.create(:public_placeholder, created_at: 3.days.ago, projects: [other_project])
    FactoryBot.create_list(:public_placeholder, 5, projects: [project])

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
        assert_select '[href=?]', placeholders_path(filter: { project: project.id })
        assert_select '.filter-option-label', text: project.title
        assert_select '.filter-option-count', text: '7'
      end
      assert_select ".filter-option[title='#{other_project.title}']" do
        assert_select '[href=?]', placeholders_path(filter: { project: other_project.id })
        assert_select '.filter-option-label', text: other_project.title
        assert_select '.filter-option-count', text: '1'
      end
      assert_select '.expand-filter-category-link', count: 0
    end

    assert_select '.filter-category[data-filter-category="contributor"]' do
      assert_select '.filter-category-title', text: 'Submitter'
      assert_select '.filter-option', href: /placeholders\?filter\[contributor\]=\d+/, count: 8
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
    assert_select 'a[href=?]', placeholders_path, text: /Clear all filters/, count: 0
  end

  test 'active filters are listed' do
    programme = FactoryBot.create(:programme)
    project = FactoryBot.create(:project, programme: programme)
    project_doc = FactoryBot.create(:public_placeholder, created_at: 3.days.ago, projects: [project])
    project_doc.annotate_with('awkward&id=1unsafe[]tag !', 'tag', project_doc.contributor)
    disable_authorization_checks { project_doc.save! }
    old_project_doc = FactoryBot.create(:public_placeholder, created_at: 10.years.ago, projects: [project])
    other_project = FactoryBot.create(:project, programme: programme)
    other_project_doc = FactoryBot.create(:public_placeholder, created_at: 3.days.ago, projects: [other_project])
    FactoryBot.create_list(:public_placeholder, 5, projects: [project])

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
        assert_select '[href=?]', placeholders_path(filter: { programme: programme.id, project: [other_project.id, project.id] })
        assert_select '.filter-option-label', text: project.title
        assert_select '.filter-option-count', text: '7'
      end
      assert_select ".filter-option[title='#{other_project.title}'].filter-option-active" do
        assert_select '[href=?]', placeholders_path(filter: { programme: programme.id })
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
        assert_select '[href=?]', placeholders_path(filter: { programme: programme.id,
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
        assert_select '[href=?]', placeholders_path(filter: { project: other_project.id })
        assert_select '.filter-option-label', text: programme.title
      end
      assert_select ".filter-option[title='#{other_project.title}'].filter-option-active" do
        assert_select '[href=?]', placeholders_path(filter: { programme: programme.id })
        assert_select '.filter-option-label', text: other_project.title
      end
    end

    assert_select 'a[href=?]', placeholders_path, text: /Clear all filters/
  end

  test 'filtering system obeys authorization and does not leak info on private resources' do
    programme = FactoryBot.create(:programme)
    project = FactoryBot.create(:project, programme: programme)
    FactoryBot.create_list(:public_placeholder, 3, projects: [project])
    private_placeholder = FactoryBot.create(:private_placeholder, created_at: 2.years.ago, projects: [project])
    private_placeholder.annotate_with('awkward&id=1unsafe[]tag !', 'tag', private_placeholder.contributor)
    disable_authorization_checks { private_placeholder.save! }

    get :index, params: { filter: { programme: programme.id } }

    assert_equal 3, assigns(:placeholders).length
    assert_not_includes assigns(:placeholders), private_placeholder
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

    assert_empty assigns(:placeholders)
    assert_equal 1, assigns(:available_filters)[:programme].length
    assert_equal 1, assigns(:active_filters)[:programme].length
    assert_equal 1, assigns(:available_filters)[:tag].length
    assert_equal 1, assigns(:active_filters)[:tag].length

    login_as(private_placeholder.contributor)

    get :index, params: { filter: { programme: programme.id } }

    assert_equal 4, assigns(:placeholders).length
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

    assert_equal 1, assigns(:placeholders).length
    assert_includes assigns(:placeholders), private_placeholder
  end

  test 'filtering with search terms' do
    programme = FactoryBot.create(:programme)
    project = FactoryBot.create(:project, programme: programme)
    FactoryBot.create_list(:public_placeholder, 3, projects: [project])

    get :index, params: { filter: { programme: programme.id, query: 'hello' } }

    assert_empty assigns(:placeholders)
    assert_equal 1, assigns(:available_filters)[:programme].length
    assert_equal 1, assigns(:active_filters)[:programme].length
    assert_equal 1, assigns(:available_filters)[:query].count
    assert_equal 1, assigns(:active_filters)[:query].count

    assert_select '.filter-category', count: 2

    assert_select '.filter-category[data-filter-category="query"]' do
      assert_select '.filter-category-title', text: 'Query'
      assert_select '#filter-search-field[value=?]', 'hello'
      assert_select '.filter-option-field-clear', count: 1, href: placeholders_path(filter: { programme: programme.id })
    end

    assert_select '.active-filters' do
      assert_select ".filter-option[title='hello'].filter-option-active" do
        assert_select '[href=?]', placeholders_path(filter: { programme: programme.id })
        assert_select '.filter-option-label', text: 'hello'
      end
      assert_select ".filter-option[title='#{programme.title}'].filter-option-active" do
        assert_select '[href=?]', placeholders_path(filter: { query: 'hello' })
        assert_select '.filter-option-label', text: programme.title
      end
    end
  end

  test 'filtering by creation date' do
    programme = FactoryBot.create(:programme)
    project = FactoryBot.create(:project, programme: programme)
    FactoryBot.create_list(:public_placeholder, 1, projects: [project], created_at: 1.hour.ago)
    FactoryBot.create_list(:public_placeholder, 2, projects: [project], created_at: 2.days.ago) # 3
    FactoryBot.create_list(:public_placeholder, 3, projects: [project], created_at: 2.weeks.ago) # 6
    FactoryBot.create_list(:public_placeholder, 4, projects: [project], created_at: 2.months.ago) # 10
    FactoryBot.create_list(:public_placeholder, 5, projects: [project], created_at: 2.years.ago) # 15
    FactoryBot.create_list(:public_placeholder, 6, projects: [project], created_at: 10.years.ago) # 21

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
        assert_select '[href=?]', placeholders_path(filter: { created_at: 'P1M' })
        assert_select '.filter-option-label', text: programme.title
      end
      assert_select ".filter-option[title='in the last 1 month'].filter-option-active" do
        assert_select '[href=?]', placeholders_path(filter: { programme: programme.id })
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
        assert_select '[href=?]', placeholders_path(filter: { created_at: date })
        assert_select '.filter-option-label', text: programme.title
      end
      assert_select ".filter-option[title='since #{date}'].filter-option-active" do
        assert_select '[href=?]', placeholders_path(filter: { programme: programme.id })
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
        assert_select '[href=?]', placeholders_path(filter: { created_at: range })
        assert_select '.filter-option-label', text: programme.title
      end
      assert_select ".filter-option[title='between #{start_date} and #{end_date}'].filter-option-active" do
        assert_select '[href=?]', placeholders_path(filter: { programme: programme.id })
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
        assert_select '[href=?]', placeholders_path(filter: { created_at: 'P3D' })
        assert_select '.filter-option-label', text: programme.title
      end
      assert_select ".filter-option[title='in the last 3 days'].filter-option-active" do
        assert_select '[href=?]', placeholders_path(filter: { programme: programme.id })
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
        assert_select '[href=?]', placeholders_path(filter: { created_at: ['PT2H3M', range] })
        assert_select '.filter-option-label', text: programme.title
      end
      assert_select ".filter-option[title='in the last 2 hours and 3 minutes'].filter-option-active" do
        assert_select '[href=?]', placeholders_path(filter: { programme: programme.id, created_at: range })
        assert_select '.filter-option-label', text: "in the last 2 hours and 3 minutes"
      end
      assert_select ".filter-option[title='between #{start_date} and #{end_date}'].filter-option-active" do
        assert_select '[href=?]', placeholders_path(filter: { programme: programme.id, created_at: 'PT2H3M' })
        assert_select '.filter-option-label', text: "between #{start_date} and #{end_date}"
      end
    end
  end

  test 'filter and sort' do
    programme = FactoryBot.create(:programme)
    project = FactoryBot.create(:project, programme: programme)
    other_project = FactoryBot.create(:project, programme: programme)
    project_doc = FactoryBot.create(:public_placeholder, created_at: 3.days.ago, projects: [project])
    old_project_doc = FactoryBot.create(:public_placeholder, created_at: 10.years.ago, projects: [project])
    other_project_doc = FactoryBot.create(:public_placeholder, created_at: 2.days.ago, projects: [other_project])

    get :index, params: { filter: { programme: programme.id }, order: 'created_at_asc' }
    assert_equal [old_project_doc, project_doc, other_project_doc], assigns(:placeholders).to_a

    get :index, params: { filter: { programme: programme.id }, order: 'created_at_desc' }
    assert_equal [other_project_doc, project_doc, old_project_doc], assigns(:placeholders).to_a

    get :index, params: { filter: { programme: programme.id, project: project.id }, order: 'created_at_asc' }
    assert_equal [old_project_doc, project_doc], assigns(:placeholders).to_a

    get :index, params: { filter: { programme: programme.id, project: project.id }, order: 'created_at_desc' }
    assert_equal [project_doc, old_project_doc], assigns(:placeholders).to_a
  end

  test 'do not get index if feature disabled' do
    with_config_value(:placeholders_enabled, false) do
      get :index
      assert_redirected_to root_path
      assert flash[:error].include?('disabled')
    end
  end
end
