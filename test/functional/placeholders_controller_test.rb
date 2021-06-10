require 'test_helper'
require 'minitest/mock'

class PlaceholdersControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
#  include RestTestCases
#  include SharingFormTestHelper
#  include MockHelper
#  include HtmlHelper
#  include GeneralAuthorizationTestCases

  def test_json_content
    skip "To be fixed"
    login_as(Factory(:user))
    super
  end

  def rest_api_test_object
    @object = Factory(:public_placeholder)
  end

  def edit_max_object(placeholder)
    add_tags_to_test_object(placeholder)
    add_creator_to_test_object(placeholder)
  end

  test 'should return 406 when requesting RDF' do
    login_as(Factory(:user))
    doc = Factory :placeholder, contributor: User.current_user.person
    assert doc.can_view?

    get :show, params: { id: doc, format: :rdf }

    assert_response :not_acceptable
  end

  test 'should get index' do
    FactoryGirl.create_list(:public_placeholder, 3)

    get :index

    assert_response :success
    assert assigns(:placeholders).any?
  end

  test "shouldn't show hidden items in index" do
    visible_doc = Factory(:public_placeholder)
    hidden_doc = Factory(:private_placeholder)

    get :index, params: { page: 'all' }

    assert_response :success
    assert_includes assigns(:placeholders), visible_doc
    assert_not_includes assigns(:placeholders), hidden_doc
  end

  test 'should show' do
    skip "To be fixed"
    visible_doc = Factory(:public_placeholder)

    get :show, params: { id: visible_doc }

    assert_response :success
  end

  test 'should not show hidden placeholder' do
    skip "To be fixed"
    hidden_doc = Factory(:private_placeholder)

    get :show, params: { id: hidden_doc }

    assert_response :forbidden
  end

  test 'should get new' do
    login_as(Factory(:person))

    get :new
    assert_response :success
    assert_select 'h1', text: "New #{I18n.t('placeholder')}"
  end

  test 'should get edit' do
    login_as(Factory(:person))

    get :new
    assert_response :success
    assert_select 'h1', text: "New #{I18n.t('placeholder')}"
  end

  test 'should create placeholder' do
    skip "To be fixed"
    person = Factory(:person)
    login_as(person)

    assert_difference('ActivityLog.count') do
      assert_difference('Placeholder.count') do
        post :create, params: { placeholder: { title: 'Placeholder', project_ids: [person.projects.first.id]}, policy_attributes: valid_sharing }
      end
    end

    assert_redirected_to placeholder_path(assigns(:placeholder))
  end

  test 'should update placeholder' do
    skip "To be fixed"
    person = Factory(:person)
    placeholder = Factory(:placeholder, contributor: person)
    assay = Factory(:assay, contributor: person)
    login_as(person)

    assert placeholder.assays.empty?

    assert_difference('ActivityLog.count') do
      put :update, params: { id: placeholder.id, placeholder: { title: 'Different title', project_ids: [person.projects.first.id],
                                                assay_assets_attributes: [{ assay_id: assay.id }] } }
    end

    assert_redirected_to placeholder_path(assigns(:placeholder))
    assert_equal 'Different title', assigns(:placeholder).title
    assert_includes assigns(:placeholder).assays, assay
  end

  test 'update with no assays' do
    skip "Needs to be fixed"
    person = Factory(:person)
    creators = [Factory(:person), Factory(:person)]
    assay = Factory(:assay, contributor:person)
    placeholder = Factory(:placeholder,assays:[assay], contributor: person, creators:creators)

    login_as(person)

    assert placeholder.can_edit?
    assert_difference('AssayAsset.count', -1) do
      assert_difference('ActivityLog.count',1) do
         put :update, params: { id: placeholder.id, placeholder: { title: 'Different title', project_ids: [person.projects.first.id], assay_assets_attributes: [""] } }
      end
    end
    assert_empty assigns(:placeholder).assays
    assert_redirected_to placeholder_path(placeholder)
  end

  test 'should destroy placeholder' do
    person = Factory(:person)
    placeholder = Factory(:placeholder, contributor: person)
    login_as(person)

    assert_difference('Placeholder.count', -1) do
      assert_no_difference('ContentBlob.count') do
        delete :destroy, params: { id: placeholder }
      end
    end

    assert_redirected_to placeholders_path
  end

  test "assay placeholders through nested routing" do
    assert_routing 'assays/2/placeholders', controller: 'placeholders', action: 'index', assay_id: '2'
    person = Factory(:person)
    login_as(person)
    assay = Factory(:assay, contributor:person)
    placeholder = Factory(:placeholder,assays:[assay],contributor:person)
    placeholder2 = Factory(:placeholder,contributor:person)


    get :index, params: { assay_id: assay.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', placeholder_path(placeholder), text: placeholder.title
      assert_select 'a[href=?]', placeholder_path(placeholder2), text: placeholder2.title, count: 0
    end
  end

  test "people placeholders through nested routing" do
    assert_routing 'people/2/placeholders', controller: 'placeholders', action: 'index', person_id: '2'
    person = Factory(:person)
    login_as(person)
    assay = Factory(:assay, contributor:person)
    placeholder = Factory(:placeholder,assays:[assay],contributor:person)
    placeholder2 = Factory(:placeholder,policy: Factory(:public_policy),contributor:Factory(:person))


    get :index, params: { person_id: person.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', placeholder_path(placeholder), text: placeholder.title
      assert_select 'a[href=?]', placeholder_path(placeholder2), text: placeholder2.title, count: 0
    end
  end

  test "project placeholders through nested routing" do
    assert_routing 'projects/2/placeholders', controller: 'placeholders', action: 'index', project_id: '2'
    person = Factory(:person)
    login_as(person)
    assay = Factory(:assay, contributor:person)
    placeholder = Factory(:placeholder,assays:[assay],contributor:person)
    placeholder2 = Factory(:placeholder,policy: Factory(:public_policy),contributor:Factory(:person))


    get :index, params: { project_id: person.projects.first.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', placeholder_path(placeholder), text: placeholder.title
      assert_select 'a[href=?]', placeholder_path(placeholder2), text: placeholder2.title, count: 0
    end
  end

  test 'manage menu item appears according to permission' do
    skip "To be fixed"
    check_manage_edit_menu_for_type('placeholder')
  end

  test 'can access manage page with manage rights' do
    person = Factory(:person)
    placeholder = Factory(:placeholder, contributor:person)
    login_as(person)
    assert placeholder.can_manage?
    get :manage, params: {id: placeholder}
    assert_response :success

    # check the project form exists, studies and assays don't have this
    assert_select 'div#add_projects_form', count:1

    # check sharing form exists
    assert_select 'div#sharing_form', count:1

    # should be a temporary sharing link
    assert_select 'div#temporary_links', count:1

    assert_select 'div#author_form', count:1
  end

  test 'cannot access manage page with edit rights' do
    person = Factory(:person)
    placeholder = Factory(:placeholder, policy:Factory(:private_policy, permissions:[Factory(:permission, contributor:person, access_type:Policy::EDITING)]))
    login_as(person)
    assert placeholder.can_edit?
    refute placeholder.can_manage?
    get :manage, params: {id:placeholder}
    assert_redirected_to placeholder
    refute_nil flash[:error]
  end

  test 'create with no creators' do
    person = Factory(:person)
    login_as(person)
    placeholder = {title: 'Placeholder', project_ids: [person.projects.first.id], creator_ids: []}
    assert_difference('Placeholder.count') do
      post :create, params: {placeholder: placeholder, policy_attributes: {access_type: Policy::VISIBLE}}
      puts response.status
    end

    placeholder = assigns(:placeholder)
    assert_empty placeholder.creators
  end

  test 'update with no creators' do
    person = Factory(:person)
    creators = [Factory(:person), Factory(:person)]
    placeholder = Factory(:placeholder, contributor: person, creators:creators)

    assert_equal creators.sort, placeholder.creators.sort
    login_as(person)

    assert placeholder.can_manage?


    patch :manage_update,
          params: {id: placeholder,
                   placeholder: {
                       title:'changed title',
                       creator_ids:[""]
                   }
          }

    assert_redirected_to placeholder_path(placeholder = assigns(:placeholder))
    assert_equal 'changed title', placeholder.title
    assert_empty placeholder.creators
  end

  test 'manage_update' do
    proj1=Factory(:project)
    proj2=Factory(:project)
    person = Factory(:person,project:proj1)
    other_person = Factory(:person)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!
    other_creator = Factory(:person,project:proj1)
    other_creator.add_to_project_and_institution(proj2,other_creator.institutions.first)
    other_creator.save!

    placeholder = Factory(:placeholder, contributor:person, projects:[proj1], policy:Factory(:private_policy))

    login_as(person)
    assert placeholder.can_manage?

    patch :manage_update, params: {id: placeholder,
                                   placeholder: {
                                       creator_ids: [other_creator.id],
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    assert_redirected_to placeholder

    placeholder.reload
    assert_equal [proj1,proj2],placeholder.projects.sort_by(&:id)
    assert_equal [other_creator],placeholder.creators
    assert_equal Policy::VISIBLE,placeholder.policy.access_type
    assert_equal 1,placeholder.policy.permissions.count
    assert_equal other_person,placeholder.policy.permissions.first.contributor
    assert_equal Policy::MANAGING,placeholder.policy.permissions.first.access_type

  end

  test 'manage_update fails without manage rights' do
    proj1=Factory(:project)
    proj2=Factory(:project)
    person = Factory(:person, project:proj1)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!

    other_person = Factory(:person)

    other_creator = Factory(:person,project:proj1)
    other_creator.add_to_project_and_institution(proj2,other_creator.institutions.first)
    other_creator.save!

    placeholder = Factory(:placeholder, projects:[proj1], policy:Factory(:private_policy,
                                                         permissions:[Factory(:permission,contributor:person, access_type:Policy::EDITING)]))

    login_as(person)
    refute placeholder.can_manage?
    assert placeholder.can_edit?

    assert_equal [proj1],placeholder.projects
    assert_empty placeholder.creators

    patch :manage_update, params: {id: placeholder,
                                   placeholder: {
                                       creator_ids: [other_creator.id],
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    refute_nil flash[:error]

    placeholder.reload
    assert_equal [proj1],placeholder.projects
    assert_empty placeholder.creators
    assert_equal Policy::PRIVATE,placeholder.policy.access_type
    assert_equal 1,placeholder.policy.permissions.count
    assert_equal person,placeholder.policy.permissions.first.contributor
    assert_equal Policy::EDITING,placeholder.policy.permissions.first.access_type
  end

  test 'numeric pagination' do
    FactoryGirl.create_list(:public_placeholder, 20)

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
    FactoryGirl.create_list(:public_placeholder, 15)

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
    Factory(:public_placeholder)

    get :index
    assert_select '.index-filters', count: 1
  end

  test 'do not show filters on index if disabled' do
    Factory(:public_placeholder)

    with_config_value(:filtering_enabled, false) do
      get :index
      assert_select '.index-filters', count: 0
    end
  end

  test 'available filters are listed' do
    project = Factory(:project)
    project_doc = Factory(:public_placeholder, created_at: 3.days.ago, projects: [project])
    project_doc.annotate_with('awkward&id=1unsafe[]tag !', 'tag', project_doc.contributor)
    disable_authorization_checks { project_doc.save! }
    old_project_doc = Factory(:public_placeholder, created_at: 10.years.ago, projects: [project])
    other_project = Factory(:project)
    other_project_doc = Factory(:public_placeholder, created_at: 3.days.ago, projects: [other_project])
    FactoryGirl.create_list(:public_placeholder, 5, projects: [project])

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
    programme = Factory(:programme)
    project = Factory(:project, programme: programme)
    project_doc = Factory(:public_placeholder, created_at: 3.days.ago, projects: [project])
    project_doc.annotate_with('awkward&id=1unsafe[]tag !', 'tag', project_doc.contributor)
    disable_authorization_checks { project_doc.save! }
    old_project_doc = Factory(:public_placeholder, created_at: 10.years.ago, projects: [project])
    other_project = Factory(:project, programme: programme)
    other_project_doc = Factory(:public_placeholder, created_at: 3.days.ago, projects: [other_project])
    FactoryGirl.create_list(:public_placeholder, 5, projects: [project])

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
    programme = Factory(:programme)
    project = Factory(:project, programme: programme)
    FactoryGirl.create_list(:public_placeholder, 3, projects: [project])
    private_placeholder = Factory(:private_placeholder, created_at: 2.years.ago, projects: [project])
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
    programme = Factory(:programme)
    project = Factory(:project, programme: programme)
    FactoryGirl.create_list(:public_placeholder, 3, projects: [project])

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
    programme = Factory(:programme)
    project = Factory(:project, programme: programme)
    FactoryGirl.create_list(:public_placeholder, 1, projects: [project], created_at: 1.hour.ago)
    FactoryGirl.create_list(:public_placeholder, 2, projects: [project], created_at: 2.days.ago) # 3
    FactoryGirl.create_list(:public_placeholder, 3, projects: [project], created_at: 2.weeks.ago) # 6
    FactoryGirl.create_list(:public_placeholder, 4, projects: [project], created_at: 2.months.ago) # 10
    FactoryGirl.create_list(:public_placeholder, 5, projects: [project], created_at: 2.years.ago) # 15
    FactoryGirl.create_list(:public_placeholder, 6, projects: [project], created_at: 10.years.ago) # 21

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
    programme = Factory(:programme)
    project = Factory(:project, programme: programme)
    other_project = Factory(:project, programme: programme)
    project_doc = Factory(:public_placeholder, created_at: 3.days.ago, projects: [project])
    old_project_doc = Factory(:public_placeholder, created_at: 10.years.ago, projects: [project])
    other_project_doc = Factory(:public_placeholder, created_at: 2.days.ago, projects: [other_project])

    get :index, params: { filter: { programme: programme.id }, order: 'created_at_asc' }
    assert_equal [old_project_doc, project_doc, other_project_doc], assigns(:placeholders).to_a

    get :index, params: { filter: { programme: programme.id }, order: 'created_at_desc' }
    assert_equal [other_project_doc, project_doc, old_project_doc], assigns(:placeholders).to_a

    get :index, params: { filter: { programme: programme.id, project: project.id }, order: 'created_at_asc' }
    assert_equal [old_project_doc, project_doc], assigns(:placeholders).to_a

    get :index, params: { filter: { programme: programme.id, project: project.id }, order: 'created_at_desc' }
    assert_equal [project_doc, old_project_doc], assigns(:placeholders).to_a
  end

  test 'should return to project page after destroy' do
    person = Factory(:person)
    project = Factory(:project)
    placeholder = Factory(:placeholder, contributor: person, project_ids: [project.id])
    login_as(person)
    assert_difference('Placeholder.count', -1) do
      assert_no_difference('ContentBlob.count') do
        delete :destroy, params: { id: placeholder, return_to: project_path(project)}
      end
    end
    assert_redirected_to project_path(project)
  end

  
  test "shouldn't return to unauthorised host" do
    person = Factory(:person)
    project = Factory(:project)
    placeholder = Factory(:placeholder, contributor: person, project_ids: [project.id])
    login_as(person)
    assert_difference('Placeholder.count', -1) do
      assert_no_difference('ContentBlob.count') do
        delete :destroy, params: { id: placeholder, return_to: "https://www.google.co.uk/"}
      end
    end
    assert_redirected_to placeholders_path
  end

  private

  def valid_placeholder
    { title: 'Test', project_ids: [projects(:sysmo_project).id] }
  end

  def valid_content_blob
    { data: fixture_file_upload('files/a_pdf_file.pdf'), data_url: '' }
  end
end
