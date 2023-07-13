require 'test_helper'
require 'minitest/mock'

class DocumentsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include SharingFormTestHelper
  include MockHelper
  include HtmlHelper
  include GeneralAuthorizationTestCases

  test 'should return 406 when requesting RDF' do
    login_as(FactoryBot.create(:user))
    doc = FactoryBot.create :document, contributor: User.current_user.person
    assert doc.can_view?

    get :show, params: { id: doc, format: :rdf }

    assert_response :not_acceptable
  end

  test 'should get index' do
    FactoryBot.create_list(:public_document, 3)

    get :index

    assert_response :success
    assert assigns(:documents).any?
  end

  test "shouldn't show hidden items in index" do
    visible_doc = FactoryBot.create(:public_document)
    hidden_doc = FactoryBot.create(:private_document)

    get :index, params: { page: 'all' }

    assert_response :success
    assert_includes assigns(:documents), visible_doc
    assert_not_includes assigns(:documents), hidden_doc
  end

  test 'should show' do
    visible_doc = FactoryBot.create(:public_document)

    get :show, params: { id: visible_doc }

    assert_response :success
  end

  test 'should not show hidden document' do
    hidden_doc = FactoryBot.create(:private_document)

    get :show, params: { id: hidden_doc }

    assert_response :forbidden
  end

  test 'should get new' do
    login_as(FactoryBot.create(:person))

    get :new
    assert_response :success
    assert_select 'h1', text: "New #{I18n.t('document')}"
  end

  test 'should get edit' do
    login_as(FactoryBot.create(:person))

    get :new
    assert_response :success
    assert_select 'h1', text: "New #{I18n.t('document')}"
  end

  test 'should create document' do
    person = FactoryBot.create(:person)
    login_as(person)

    assert_difference('ActivityLog.count') do
      assert_difference('Document.count') do
        assert_difference('Document::Version.count') do
          assert_difference('ContentBlob.count') do
            post :create, params: { document: { title: 'Document', project_ids: [person.projects.first.id]}, content_blobs: [valid_content_blob], policy_attributes: valid_sharing }
          end
        end
      end
    end

    assert_redirected_to document_path(assigns(:document))
  end

  test 'should create document version' do
    document = FactoryBot.create(:document)
    login_as(document.contributor)

    assert_difference('ActivityLog.count') do
      assert_no_difference('Document.count') do
        assert_difference('Document::Version.count') do
          assert_difference('ContentBlob.count') do
            post :create_version, params: { id: document.id, content_blobs: [{ data: fixture_file_upload('little_file.txt') }], revision_comments: 'new version!' }
          end
        end
      end
    end

    assert_redirected_to document_path(assigns(:document))
    assert_equal 2, assigns(:document).version
    assert_equal 2, assigns(:document).versions.count
    assert_equal 'new version!', assigns(:document).latest_version.revision_comments
  end

  test 'should create and link to event' do
    person = FactoryBot.create(:person)
    login_as(person)
    event = FactoryBot.create(:event,contributor:person)
    event2 = FactoryBot.create(:event,contributor:person)
    assert_difference('Document.count') do
      post :create, params: { document: { title: 'Document', project_ids: [person.projects.first.id],event_ids:[event.id.to_s,event2.id.to_s]}, content_blobs: [valid_content_blob], policy_attributes: valid_sharing }
    end

    assert (doc = assigns(:document))
    assert_redirected_to document_path(doc)

    assert_equal [event,event2].sort,doc.events.sort

  end

  test 'should not create event with link to none visible event' do
    person = FactoryBot.create(:person)
    login_as(person)

    event = FactoryBot.create(:event)
    refute event.can_view?

    assert_no_difference('Document.count') do
      post :create, params: { document: { title: 'Document', project_ids: [person.projects.first.id],event_ids:[event.id.to_s]}, content_blobs: [valid_content_blob], policy_attributes: valid_sharing }
    end

  end

  test 'should update document' do
    person = FactoryBot.create(:person)
    document = FactoryBot.create(:document, contributor: person)
    assay = FactoryBot.create(:assay, contributor: person)
    login_as(person)

    assert document.assays.empty?

    assert_difference('ActivityLog.count') do
      put :update, params: { id: document.id, document: { title: 'Different title', project_ids: [person.projects.first.id],
                                                assay_assets_attributes: [{ assay_id: assay.id }] } }
    end

    assert_redirected_to document_path(assigns(:document))
    assert_equal 'Different title', assigns(:document).title
    assert_includes assigns(:document).assays, assay
  end

  test 'should update and link to event' do
    person = FactoryBot.create(:person)
    document = FactoryBot.create(:document, contributor: person)
    assert_empty document.events

    login_as(person)

    event = FactoryBot.create(:event,contributor:person)

    assert_difference('ActivityLog.count') do
      put :update, params: { id: document.id, document: { title: 'Different title', project_ids: [person.projects.first.id],
                                                event_ids:['',event.id.to_s] } }
    end

    assert (doc = assigns(:document))
    assert_redirected_to document_path(doc)
    assert_equal [event],doc.events
  end

  test 'should update and link to workflow' do
    person = FactoryBot.create(:person)
    document = FactoryBot.create(:document, contributor: person)
    assert_empty document.workflows

    login_as(person)

    workflow = FactoryBot.create(:workflow,contributor:person)

    assert_difference('ActivityLog.count') do
      put :update, params: { id: document.id, document: { title: 'Different title', project_ids: [person.projects.first.id],
                                                          workflow_ids:['',workflow.id.to_s] } }
    end

    assert (doc = assigns(:document))
    assert_redirected_to document_path(doc)
    assert_equal [workflow],doc.workflows
  end

  test 'update with no assays' do
    person = FactoryBot.create(:person)
    creators = [FactoryBot.create(:person), FactoryBot.create(:person)]
    assay = FactoryBot.create(:assay, contributor:person)
    document = FactoryBot.create(:document,assays:[assay], contributor: person, creators:creators)

    login_as(person)

    assert document.can_edit?
    assert_difference('AssayAsset.count', -1) do
      assert_difference('ActivityLog.count',1) do
         put :update, params: { id: document.id, document: { title: 'Different title', project_ids: [person.projects.first.id], assay_assets_attributes: [""] } }
      end
    end
    assert_empty assigns(:document).assays
    assert_redirected_to document_path(document)
  end

  test 'should destroy document' do
    person = FactoryBot.create(:person)
    document = FactoryBot.create(:document, contributor: person)
    login_as(person)

    assert_difference('Document.count', -1) do
      assert_no_difference('ContentBlob.count') do
        delete :destroy, params: { id: document }
      end
    end

    assert_redirected_to documents_path
  end

  test 'should be able to view pdf content' do
    doc = FactoryBot.create(:public_document)
    assert doc.content_blob.is_content_viewable?
    get :show, params: { id: doc.id }
    assert_response :success
    assert_select 'a', text: /View content/, count: 1
  end

  test 'show explore button' do
    doc = FactoryBot.create(:small_test_spreadsheet_document)
    login_as(doc.contributor.user)
    get :show, params: { id: doc }
    assert_response :success
    assert_select '#buttons' do
      assert_select 'a[href=?]', explore_document_path(doc, version: doc.version), count: 1
      assert_select 'a.disabled', text: 'Explore', count: 0
    end
  end

  test 'not show explore button if spreadsheet not supported' do
    doc = FactoryBot.create(:non_spreadsheet_document)
    login_as(doc.contributor.user)
    with_config_value(:max_extractable_spreadsheet_size, 0) do
      get :show, params: { id: doc }
    end
    assert_response :success
    assert_select '#buttons' do
      assert_select 'a[href=?]', explore_document_path(doc, version: doc.version), count: 0
      assert_select 'a', text: 'Explore', count: 0
    end
  end

  test 'show disabled explore button if spreadsheet too big' do
    doc = FactoryBot.create(:small_test_spreadsheet_document)
    login_as(doc.contributor.user)
    with_config_value(:max_extractable_spreadsheet_size, 0) do
      get :show, params: { id: doc }
    end
    assert_response :success
    assert_select '#buttons' do
      assert_select 'a[href=?]', explore_document_path(doc, version: doc.version), count: 0
      assert_select 'a.disabled', text: 'Explore', count: 1
    end
  end

  test 'explore latest version' do
    data = FactoryBot.create :small_test_spreadsheet_document, policy: FactoryBot.create(:public_policy)
    get :explore, params: { id: data }
    assert_response :success
  end

  test 'explore earlier version' do
    doc = FactoryBot.create(:small_test_spreadsheet_document)
    login_as(doc.contributor.user)
    assert doc.save_as_new_version('no comment')
    FactoryBot.create(:pdf_content_blob, asset_version: doc.version, asset: doc)
    doc.reload
    assert_equal 2, doc.versions.count
    assert doc.find_version(1).content_blob.is_extractable_excel?
    refute doc.find_version(2).content_blob.is_extractable_excel?
    get :explore, params: { id: doc, version: 1 }
    assert_response :success
  end

  test 'gracefully handles explore with no spreadsheet' do
    doc = FactoryBot.create(:document, version: 1)
    login_as(doc.contributor)
    get :explore, params: { id: doc, version: 1 }
    assert_redirected_to document_path(doc, version: 1)
    assert flash[:error]
  end

  test 'gracefully handles explore with invalid mime type' do
    doc = FactoryBot.create(:csv_spreadsheet_document, policy: FactoryBot.create(:public_policy))
    doc.content_blob.update_column(:content_type, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    # incorrectly thinks it's excel
    assert doc.content_blob.is_excel?
    # check mime type cannot be resolved, otherwise it will autofix without error
    assert_nil doc.content_blob.send(:mime_magic_content_type)
    get :explore, params: { id: doc, version: 1 }
    assert_redirected_to document_path(doc, version: 1)
    assert flash[:error]
  end

  test "assay documents through nested routing" do
    assert_routing 'assays/2/documents', controller: 'documents', action: 'index', assay_id: '2'
    person = FactoryBot.create(:person)
    login_as(person)
    assay = FactoryBot.create(:assay, contributor:person)
    document = FactoryBot.create(:document,assays:[assay],contributor:person)
    document2 = FactoryBot.create(:document,contributor:person)


    get :index, params: { assay_id: assay.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', document_path(document), text: document.title
      assert_select 'a[href=?]', document_path(document2), text: document2.title, count: 0
    end
  end

  test "studies documents through nested routing" do
    assert_routing 'studies/2/documents', controller: 'documents', action: 'index', study_id: '2'
    person = FactoryBot.create(:person)
    login_as(person)
    assay = FactoryBot.create(:assay, contributor:person)
    document = FactoryBot.create(:document,assays:[assay],contributor:person)
    document2 = FactoryBot.create(:document,contributor:person)


    get :index, params: { study_id: assay.study.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', document_path(document), text: document.title
      assert_select 'a[href=?]', document_path(document2), text: document2.title, count: 0
    end
  end

  test "investigation documents through nested routing" do
    assert_routing 'investigations/2/documents', controller: 'documents', action: 'index', investigation_id: '2'
    person = FactoryBot.create(:person)
    login_as(person)
    assay = FactoryBot.create(:assay, contributor:person)
    document = FactoryBot.create(:document,assays:[assay],contributor:person)
    document2 = FactoryBot.create(:document,contributor:person)


    get :index, params: { investigation_id: assay.study.investigation.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', document_path(document), text: document.title
      assert_select 'a[href=?]', document_path(document2), text: document2.title, count: 0
    end
  end

  test "people documents through nested routing" do
    assert_routing 'people/2/documents', controller: 'documents', action: 'index', person_id: '2'
    person = FactoryBot.create(:person)
    login_as(person)
    assay = FactoryBot.create(:assay, contributor:person)
    document = FactoryBot.create(:document,assays:[assay],contributor:person)
    document2 = FactoryBot.create(:document,policy: FactoryBot.create(:public_policy),contributor:FactoryBot.create(:person))


    get :index, params: { person_id: person.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', document_path(document), text: document.title
      assert_select 'a[href=?]', document_path(document2), text: document2.title, count: 0
    end
  end

  test "project documents through nested routing" do
    assert_routing 'projects/2/documents', controller: 'documents', action: 'index', project_id: '2'
    person = FactoryBot.create(:person)
    login_as(person)
    document = FactoryBot.create(:document, contributor:person)
    document2 = FactoryBot.create(:document,policy: FactoryBot.create(:public_policy),contributor:FactoryBot.create(:person))


    get :index, params: { project_id: person.projects.first.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', document_path(document), text: document.title
      assert_select 'a[href=?]', document_path(document2), text: document2.title, count: 0
    end
  end

  test "workflow documents through nested routing" do
    assert_routing 'workflows/2/documents', controller: 'documents', action: 'index', workflow_id: '2'
    person = FactoryBot.create(:person)
    login_as(person)
    workflow = FactoryBot.create(:workflow, contributor:person)
    document = FactoryBot.create(:document,workflows:[workflow],contributor:person)
    document2 = FactoryBot.create(:document,policy: FactoryBot.create(:public_policy),contributor:FactoryBot.create(:person))

    get :index, params: { workflow_id: workflow.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', document_path(document), text: document.title
      assert_select 'a[href=?]', document_path(document2), text: document2.title, count: 0
    end
  end

  test 'manage menu item appears according to permission' do
    check_manage_edit_menu_for_type('document')
  end

  test 'publish menu items appears according to status and permission' do
    check_publish_menu_for_type('document')
  end

  test 'can access manage page with manage rights' do
    person = FactoryBot.create(:person)
    document = FactoryBot.create(:document, contributor:person)
    login_as(person)
    assert document.can_manage?
    get :manage, params: {id: document}
    assert_response :success

    # check the project form exists, studies and assays don't have this
    assert_select 'div#add_projects_form', count:1

    # check sharing form exists
    assert_select 'div#sharing_form', count:1

    # should be a temporary sharing link
    assert_select 'div#temporary_links', count:1

    assert_select 'div#author-form', count:1
  end

  test 'cannot access manage page with edit rights' do
    person = FactoryBot.create(:person)
    document = FactoryBot.create(:document, policy:FactoryBot.create(:private_policy, permissions:[FactoryBot.create(:permission, contributor:person, access_type:Policy::EDITING)]))
    login_as(person)
    assert document.can_edit?
    refute document.can_manage?
    get :manage, params: {id:document}
    assert_redirected_to document
    refute_nil flash[:error]
  end

  test 'create with no creators' do
    person = FactoryBot.create(:person)
    login_as(person)
    document = {title: 'Document', project_ids: [person.projects.first.id], creator_ids: []}
    assert_difference('Document.count') do
      post :create, params: {document: document, content_blobs: [{data: file_for_upload}], policy_attributes: {access_type: Policy::VISIBLE}}
    end

    document = assigns(:document)
    assert_empty document.creators
  end

  test 'update with no creators' do
    person = FactoryBot.create(:person)
    creators = [FactoryBot.create(:person), FactoryBot.create(:person)]
    document = FactoryBot.create(:document, contributor: person, creators:creators)

    assert_equal creators.sort, document.creators.sort
    login_as(person)

    assert document.can_manage?


    patch :manage_update,
          params: {id: document,
                   document: {
                       title:'changed title',
                       creator_ids:[""]
                   }
          }

    assert_redirected_to document_path(document = assigns(:document))
    assert_equal 'changed title', document.title
    assert_empty document.creators
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

    document = FactoryBot.create(:document, contributor:person, projects:[proj1], policy:FactoryBot.create(:private_policy))

    login_as(person)
    assert document.can_manage?

    patch :manage_update, params: {id: document,
                                   document: {
                                       creator_ids: [other_creator.id],
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    assert_redirected_to document

    document.reload
    assert_equal [proj1,proj2],document.projects.sort_by(&:id)
    assert_equal [other_creator],document.creators
    assert_equal Policy::VISIBLE,document.policy.access_type
    assert_equal 1,document.policy.permissions.count
    assert_equal other_person,document.policy.permissions.first.contributor
    assert_equal Policy::MANAGING,document.policy.permissions.first.access_type

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

    document = FactoryBot.create(:document, projects:[proj1], policy:FactoryBot.create(:private_policy,
                                                         permissions:[FactoryBot.create(:permission,contributor:person, access_type:Policy::EDITING)]))

    login_as(person)
    refute document.can_manage?
    assert document.can_edit?

    assert_equal [proj1],document.projects
    assert_empty document.creators

    patch :manage_update, params: {id: document,
                                   document: {
                                       creator_ids: [other_creator.id],
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    refute_nil flash[:error]

    document.reload
    assert_equal [proj1],document.projects
    assert_empty document.creators
    assert_equal Policy::PRIVATE,document.policy.access_type
    assert_equal 1,document.policy.permissions.count
    assert_equal person,document.policy.permissions.first.contributor
    assert_equal Policy::EDITING,document.policy.permissions.first.access_type
  end

  test 'numeric pagination' do
    FactoryBot.create_list(:public_document, 20)

    with_config_value(:results_per_page_default, 5) do
      get :index

      assert_equal 5, assigns(:documents).length
      assert_equal '1', assigns(:page)
      assert_equal 5, assigns(:per_page)
      assert_select '.pagination-container a', href: documents_path(page: 2), text: /Next/
      assert_select '.pagination-container a', href: documents_path(page: 2), text: /2/
      assert_select '.pagination-container a', href: documents_path(page: 3), text: /3/

      get :index, params: { page: 2 }

      assert_equal 5, assigns(:documents).length
      assert_equal '2', assigns(:page)
      assert_select '.pagination-container a', href: documents_path(page: 3), text: /Next/
      assert_select '.pagination-container a', href: documents_path(page: 1), text: /Previous/
      assert_select '.pagination-container a', href: documents_path(page: 1), text: /1/
      assert_select '.pagination-container a', href: documents_path(page: 3), text: /3/
    end
  end

  test 'user can change results per page' do
    FactoryBot.create_list(:public_document, 15)

    with_config_value(:results_per_page_default, 5) do
      get :index, params: { per_page: 15 }
      assert_equal 15, assigns(:documents).length
      assert_equal '1', assigns(:page)
      assert_equal 15, assigns(:per_page)
      assert_select '.pagination-container a', text: /Next/, count: 0

      get :index, params: { per_page: 15, page: 2 }
      assert_equal 0, assigns(:documents).length
      assert_equal '2', assigns(:page)
      assert_equal 15, assigns(:per_page)
      assert_select '.pagination-container a', text: /Next/, count: 0
    end
  end

  test 'show filters on index' do
    FactoryBot.create(:public_document)

    get :index
    assert_select '.index-filters', count: 1
  end

  test 'do not show filters on index if disabled' do
    FactoryBot.create(:public_document)

    with_config_value(:filtering_enabled, false) do
      get :index
      assert_select '.index-filters', count: 0
    end
  end

  test 'available filters are listed' do
    project = FactoryBot.create(:project)
    project_doc = FactoryBot.create(:public_document, created_at: 3.days.ago, projects: [project])
    project_doc.annotate_with('awkward&id=1unsafe[]tag !', 'tag', project_doc.contributor)
    disable_authorization_checks { project_doc.save! }
    old_project_doc = FactoryBot.create(:public_document, created_at: 10.years.ago, projects: [project])
    other_project = FactoryBot.create(:project)
    other_project_doc = FactoryBot.create(:public_document, created_at: 3.days.ago, projects: [other_project])
    FactoryBot.create_list(:public_document, 5, projects: [project])

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
        assert_select '[href=?]', documents_path(filter: { project: project.id })
        assert_select '.filter-option-label', text: project.title
        assert_select '.filter-option-count', text: '7'
      end
      assert_select ".filter-option[title='#{other_project.title}']" do
        assert_select '[href=?]', documents_path(filter: { project: other_project.id })
        assert_select '.filter-option-label', text: other_project.title
        assert_select '.filter-option-count', text: '1'
      end
      assert_select '.expand-filter-category-link', count: 0
    end

    assert_select '.filter-category[data-filter-category="contributor"]' do
      assert_select '.filter-category-title', text: 'Submitter'
      assert_select '.filter-option', href: /documents\?filter\[contributor\]=\d+/, count: 8
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
    assert_select 'a[href=?]', documents_path, text: /Clear all filters/, count: 0
  end

  test 'active filters are listed' do
    programme = FactoryBot.create(:programme)
    project = FactoryBot.create(:project, programme: programme)
    project_doc = FactoryBot.create(:public_document, created_at: 3.days.ago, projects: [project])
    project_doc.annotate_with('awkward&id=1unsafe[]tag !', 'tag', project_doc.contributor)
    disable_authorization_checks { project_doc.save! }
    old_project_doc = FactoryBot.create(:public_document, created_at: 10.years.ago, projects: [project])
    other_project = FactoryBot.create(:project, programme: programme)
    other_project_doc = FactoryBot.create(:public_document, created_at: 3.days.ago, projects: [other_project])
    FactoryBot.create_list(:public_document, 5, projects: [project])

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
        assert_select '[href=?]', documents_path(filter: { programme: programme.id, project: [other_project.id, project.id] })
        assert_select '.filter-option-label', text: project.title
        assert_select '.filter-option-count', text: '7'
      end
      assert_select ".filter-option[title='#{other_project.title}'].filter-option-active" do
        assert_select '[href=?]', documents_path(filter: { programme: programme.id })
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
        assert_select '[href=?]', documents_path(filter: { programme: programme.id,
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
        assert_select '[href=?]', documents_path(filter: { project: other_project.id })
        assert_select '.filter-option-label', text: programme.title
      end
      assert_select ".filter-option[title='#{other_project.title}'].filter-option-active" do
        assert_select '[href=?]', documents_path(filter: { programme: programme.id })
        assert_select '.filter-option-label', text: other_project.title
      end
    end

    assert_select 'a[href=?]', documents_path, text: /Clear all filters/
  end

  test 'filtering system obeys authorization and does not leak info on private resources' do
    programme = FactoryBot.create(:programme)
    project = FactoryBot.create(:project, programme: programme)
    FactoryBot.create_list(:public_document, 3, projects: [project])
    private_document = FactoryBot.create(:private_document, created_at: 2.years.ago, projects: [project])
    private_document.annotate_with('awkward&id=1unsafe[]tag !', 'tag', private_document.contributor)
    disable_authorization_checks { private_document.save! }

    get :index, params: { filter: { programme: programme.id } }

    assert_equal 3, assigns(:documents).length
    assert_not_includes assigns(:documents), private_document
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

    assert_empty assigns(:documents)
    assert_equal 1, assigns(:available_filters)[:programme].length
    assert_equal 1, assigns(:active_filters)[:programme].length
    assert_equal 1, assigns(:available_filters)[:tag].length
    assert_equal 1, assigns(:active_filters)[:tag].length

    login_as(private_document.contributor)

    get :index, params: { filter: { programme: programme.id } }

    assert_equal 4, assigns(:documents).length
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

    assert_equal 1, assigns(:documents).length
    assert_includes assigns(:documents), private_document
  end

  test 'filtering with search terms' do
    programme = FactoryBot.create(:programme)
    project = FactoryBot.create(:project, programme: programme)
    FactoryBot.create_list(:public_document, 3, projects: [project])

    get :index, params: { filter: { programme: programme.id, query: 'hello' } }

    assert_empty assigns(:documents)
    assert_equal 1, assigns(:available_filters)[:programme].length
    assert_equal 1, assigns(:active_filters)[:programme].length
    assert_equal 1, assigns(:available_filters)[:query].count
    assert_equal 1, assigns(:active_filters)[:query].count

    assert_select '.filter-category', count: 2

    assert_select '.filter-category[data-filter-category="query"]' do
      assert_select '.filter-category-title', text: 'Query'
      assert_select '#filter-search-field[value=?]', 'hello'
      assert_select '.filter-option-field-clear', count: 1, href: documents_path(filter: { programme: programme.id })
    end

    assert_select '.active-filters' do
      assert_select ".filter-option[title='hello'].filter-option-active" do
        assert_select '[href=?]', documents_path(filter: { programme: programme.id })
        assert_select '.filter-option-label', text: 'hello'
      end
      assert_select ".filter-option[title='#{programme.title}'].filter-option-active" do
        assert_select '[href=?]', documents_path(filter: { query: 'hello' })
        assert_select '.filter-option-label', text: programme.title
      end
    end
  end

  test 'filtering by creation date' do
    programme = FactoryBot.create(:programme)
    project = FactoryBot.create(:project, programme: programme)
    FactoryBot.create_list(:public_document, 1, projects: [project], created_at: 1.hour.ago)
    FactoryBot.create_list(:public_document, 2, projects: [project], created_at: 2.days.ago) # 3
    FactoryBot.create_list(:public_document, 3, projects: [project], created_at: 2.weeks.ago) # 6
    FactoryBot.create_list(:public_document, 4, projects: [project], created_at: 2.months.ago) # 10
    FactoryBot.create_list(:public_document, 5, projects: [project], created_at: 2.years.ago) # 15
    FactoryBot.create_list(:public_document, 6, projects: [project], created_at: 10.years.ago) # 21

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
        assert_select '[href=?]', documents_path(filter: { created_at: 'P1M' })
        assert_select '.filter-option-label', text: programme.title
      end
      assert_select ".filter-option[title='in the last 1 month'].filter-option-active" do
        assert_select '[href=?]', documents_path(filter: { programme: programme.id })
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
        assert_select '[href=?]', documents_path(filter: { created_at: date })
        assert_select '.filter-option-label', text: programme.title
      end
      assert_select ".filter-option[title='since #{date}'].filter-option-active" do
        assert_select '[href=?]', documents_path(filter: { programme: programme.id })
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
        assert_select '[href=?]', documents_path(filter: { created_at: range })
        assert_select '.filter-option-label', text: programme.title
      end
      assert_select ".filter-option[title='between #{start_date} and #{end_date}'].filter-option-active" do
        assert_select '[href=?]', documents_path(filter: { programme: programme.id })
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
        assert_select '[href=?]', documents_path(filter: { created_at: 'P3D' })
        assert_select '.filter-option-label', text: programme.title
      end
      assert_select ".filter-option[title='in the last 3 days'].filter-option-active" do
        assert_select '[href=?]', documents_path(filter: { programme: programme.id })
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
        assert_select '[href=?]', documents_path(filter: { created_at: ['PT2H3M', range] })
        assert_select '.filter-option-label', text: programme.title
      end
      assert_select ".filter-option[title='in the last 2 hours and 3 minutes'].filter-option-active" do
        assert_select '[href=?]', documents_path(filter: { programme: programme.id, created_at: range })
        assert_select '.filter-option-label', text: "in the last 2 hours and 3 minutes"
      end
      assert_select ".filter-option[title='between #{start_date} and #{end_date}'].filter-option-active" do
        assert_select '[href=?]', documents_path(filter: { programme: programme.id, created_at: 'PT2H3M' })
        assert_select '.filter-option-label', text: "between #{start_date} and #{end_date}"
      end
    end
  end

  test 'filter and sort' do
    programme = FactoryBot.create(:programme)
    project = FactoryBot.create(:project, programme: programme)
    other_project = FactoryBot.create(:project, programme: programme)
    project_doc = FactoryBot.create(:public_document, created_at: 3.days.ago, projects: [project])
    old_project_doc = FactoryBot.create(:public_document, created_at: 10.years.ago, projects: [project])
    other_project_doc = FactoryBot.create(:public_document, created_at: 2.days.ago, projects: [other_project])

    get :index, params: { filter: { programme: programme.id }, order: 'created_at_asc' }
    assert_equal [old_project_doc, project_doc, other_project_doc], assigns(:documents).to_a

    get :index, params: { filter: { programme: programme.id }, order: 'created_at_desc' }
    assert_equal [other_project_doc, project_doc, old_project_doc], assigns(:documents).to_a

    get :index, params: { filter: { programme: programme.id, project: project.id }, order: 'created_at_asc' }
    assert_equal [old_project_doc, project_doc], assigns(:documents).to_a

    get :index, params: { filter: { programme: programme.id, project: project.id }, order: 'created_at_desc' }
    assert_equal [project_doc, old_project_doc], assigns(:documents).to_a
  end

  test 'sort by downloads' do
    person = FactoryBot.create(:person)
    d1 = FactoryBot.create(:document, title: 'document a', policy: FactoryBot.create(:publicly_viewable_policy))
    d2 = FactoryBot.create(:document, title: 'document b', policy: FactoryBot.create(:publicly_viewable_policy))
    d3 = FactoryBot.create(:document, title: 'document c', policy: FactoryBot.create(:publicly_viewable_policy))
    d4 = FactoryBot.create(:document, title: 'document d', policy: FactoryBot.create(:publicly_viewable_policy))
    d5 = FactoryBot.create(:document, title: 'document e', policy: FactoryBot.create(:publicly_viewable_policy))
    d6 = FactoryBot.create(:document, title: 'document f', policy: FactoryBot.create(:publicly_viewable_policy))
    FactoryBot.create(:activity_log, action: 'download', activity_loggable: d2, created_at: 10.minutes.ago, culprit: person.user)
    FactoryBot.create(:activity_log, action: 'download', activity_loggable: d2, created_at: 9.minutes.ago, culprit: person.user)
    FactoryBot.create(:activity_log, action: 'download', activity_loggable: d2, created_at: 8.minutes.ago, culprit: person.user)
    FactoryBot.create(:activity_log, action: 'download', activity_loggable: d3, created_at: 7.minutes.ago, culprit: person.user)
    FactoryBot.create(:activity_log, action: 'download', activity_loggable: d3, created_at: 6.minutes.ago, culprit: person.user)
    FactoryBot.create(:activity_log, action: 'download', activity_loggable: d6, created_at: 5.minutes.ago, culprit: person.user)
    FactoryBot.create(:activity_log, action: 'download', activity_loggable: d6, created_at: 4.minutes.ago, culprit: person.user)
    FactoryBot.create(:activity_log, action: 'download', activity_loggable: d5, created_at: 3.minutes.ago, culprit: person.user)

    d3.annotate_with('tag1', 'tag', d3.contributor)
    d4.annotate_with('tag1', 'tag', d4.contributor)
    d5.annotate_with('tag1', 'tag', d5.contributor)
    disable_authorization_checks do
      d3.save!
      d4.save!
      d5.save!
    end

    downloads_ordered = [d2, d3, d6, d5, d1, d4]
    downloads_ordered_tag1 = [d3, d5, d4]

    get :index
    assert_select '#index_sort_order' do
      assert_select 'option', 'Downloads (Descending)'
    end

    get :index, params: { order: 'downloads_desc' }
    assert_response :success
    assert_equal downloads_ordered, assigns(:documents).to_a

    get :index, params: { filter: { tag: 'tag1' }, order: 'downloads_desc' }
    assert_response :success
    assert_equal downloads_ordered_tag1, assigns(:documents).to_a
  end

  test 'sort by views' do
    d1 = FactoryBot.create(:document, title: 'document a', policy: FactoryBot.create(:publicly_viewable_policy))
    d2 = FactoryBot.create(:document, title: 'document b', policy: FactoryBot.create(:publicly_viewable_policy))
    d3 = FactoryBot.create(:document, title: 'document c', policy: FactoryBot.create(:publicly_viewable_policy))
    d4 = FactoryBot.create(:document, title: 'document d', policy: FactoryBot.create(:publicly_viewable_policy))
    d5 = FactoryBot.create(:document, title: 'document e', policy: FactoryBot.create(:publicly_viewable_policy))
    d6 = FactoryBot.create(:document, title: 'document f', policy: FactoryBot.create(:publicly_viewable_policy))
    FactoryBot.create(:activity_log, action: 'show', activity_loggable: d4, created_at: 10.minutes.ago)
    FactoryBot.create(:activity_log, action: 'show', activity_loggable: d4, created_at: 9.minutes.ago)
    FactoryBot.create(:activity_log, action: 'show', activity_loggable: d4, created_at: 8.minutes.ago)
    FactoryBot.create(:activity_log, action: 'show', activity_loggable: d3, created_at: 7.minutes.ago)
    FactoryBot.create(:activity_log, action: 'show', activity_loggable: d3, created_at: 6.minutes.ago)
    FactoryBot.create(:activity_log, action: 'show', activity_loggable: d6, created_at: 5.minutes.ago)
    FactoryBot.create(:activity_log, action: 'show', activity_loggable: d6, created_at: 4.minutes.ago)
    FactoryBot.create(:activity_log, action: 'show', activity_loggable: d5, created_at: 3.minutes.ago)

    d1.annotate_with('tag1', 'tag', d1.contributor)
    d3.annotate_with('tag1', 'tag', d3.contributor)
    d6.annotate_with('tag1', 'tag', d6.contributor)
    disable_authorization_checks do
      d1.save!
      d3.save!
      d6.save!
    end

    views_ordered = [d4, d3, d6, d5, d1, d2]
    views_ordered_tag1 = [d3, d6, d1]

    get :index
    assert_select '#index_sort_order' do
      assert_select 'option', 'Views (Descending)'
    end

    get :index, params: { order: 'views_desc' }
    assert_response :success
    assert_equal views_ordered, assigns(:documents).to_a

    get :index, params: { filter: { tag: 'tag1' }, order: 'views_desc' }
    assert_response :success
    assert_equal views_ordered_tag1, assigns(:documents).to_a
  end

  test 'filtering a scoped collection' do
    programme = FactoryBot.create(:programme)
    project1 = FactoryBot.create(:project, programme: programme)
    project2 = FactoryBot.create(:project, programme: programme)
    project3 = FactoryBot.create(:project, programme: programme)
    doc1 = FactoryBot.create(:public_document, projects: [project1])
    doc1.annotate_with('tag1', 'tag', doc1.contributor)
    doc2 = FactoryBot.create(:public_document, projects: [project2])
    doc2.annotate_with('tag2', 'tag', doc2.contributor)
    doc3 = FactoryBot.create(:public_document, projects: [project1, project2])
    doc3.annotate_with('tag3', 'tag', doc3.contributor)
    disable_authorization_checks do
      doc1.save!
      doc2.save!
      doc3.save!
    end

    get :index, params: { project_id: project1.id, order: 'created_at_asc' }
    assert_equal [doc1, doc3], assigns(:documents).to_a

    get :index, params: { project_id: project1.id, filter: { tag: 'tag1' }, order: 'created_at_asc' }
    assert_equal [doc1], assigns(:documents).to_a

    get :index, params: { project_id: project2.id, order: 'created_at_asc' }
    assert_equal [doc2, doc3], assigns(:documents).to_a

    get :index, params: { project_id: project2.id, filter: { tag: 'tag2' }, order: 'created_at_asc' }
    assert_equal [doc2], assigns(:documents).to_a

    get :index, params: { project_id: project2.id, filter: { tag: 'tag1' }, order: 'created_at_asc' }
    assert_equal [], assigns(:documents).to_a

    get :index, params: { project_id: project3.id, filter: { tag: 'tag1' }, order: 'created_at_asc' }
    assert_equal [], assigns(:documents).to_a
  end

  test 'attempting to filter empty collection does not error' do
    project = FactoryBot.create(:project)
    assert project.documents.none?

    get :index, params: { project_id: project.id, filter: { tag: 'something' } }
    assert_equal [], assigns(:documents).to_a

    assert_select '.active-filters' do
      assert_select '.active-filter-category-title', count: 1
      assert_select ".filter-option[title='something'].filter-option-active" do
        assert_select '[href=?]', project_documents_path(project_id: project.id)
        assert_select '.filter-option-label', text: 'something'
      end
    end
  end

  test 'should create with discussion link' do
    person = FactoryBot.create(:person)
    login_as(person)
    document =  {title: 'Document', project_ids: [person.projects.first.id], discussion_links_attributes:[{url: "http://www.slack.com/", label:'our slack'}]}
    assert_difference('AssetLink.discussion.count') do
      assert_difference('Document.count') do
        assert_difference('ContentBlob.count') do
          post :create, params: {document: document, content_blobs: [{ data: file_for_upload }], policy_attributes: { access_type: Policy::VISIBLE }}
        end
      end
    end
    document = assigns(:document)
    assert_equal 'http://www.slack.com/', document.discussion_links.first.url
    assert_equal 'our slack', document.discussion_links.first.label
    assert_equal AssetLink::DISCUSSION, document.discussion_links.first.link_type
  end

  test 'should show discussion link with label' do
    asset_link = FactoryBot.create(:discussion_link, label:'discuss-label')
    document = FactoryBot.create(:document, discussion_links: [asset_link], policy: FactoryBot.create(:public_policy, access_type: Policy::VISIBLE))
    assert_equal [asset_link],document.discussion_links
    get :show, params: { id: document }
    assert_response :success
    assert_select 'div.panel-heading', text: /Discussion Channel/, count: 1
    assert_select 'div.discussion-link', count:1 do
      assert_select 'a[href=?]',asset_link.url,text:'discuss-label'
    end
  end

  test 'should show discussion link without label' do
    asset_link = FactoryBot.create(:discussion_link)
    document = FactoryBot.create(:document, discussion_links: [asset_link], policy: FactoryBot.create(:public_policy, access_type: Policy::VISIBLE))
    assert_equal [asset_link],document.discussion_links
    get :show, params: { id: document }
    assert_response :success
    assert_select 'div.panel-heading', text: /Discussion Channel/, count: 1
    assert_select 'div.discussion-link', count:1 do
      assert_select 'a[href=?]',asset_link.url,text:asset_link.url
    end

    #blank rather than nil
    asset_link.update_column(:label,'')
    document.reload
    assert_equal [asset_link],document.discussion_links
    get :show, params: { id: document }
    assert_response :success
    assert_select 'div.panel-heading', text: /Discussion Channel/, count: 1
    assert_select 'div.discussion-link', count:1 do
      assert_select 'a[href=?]',asset_link.url,text:asset_link.url
    end
  end

  test 'should update document with new discussion link' do
    person = FactoryBot.create(:person)
    document = FactoryBot.create(:document, contributor: person)
    login_as(person)
    assert_nil document.discussion_links.first
    assert_difference('AssetLink.discussion.count') do
      assert_difference('ActivityLog.count') do
        put :update, params: { id: document.id, document: { discussion_links_attributes:[{url: "http://www.slack.com/", label:'our slack'}] } }
      end
    end
    assert_redirected_to document_path(document = assigns(:document))
    assert_equal 'http://www.slack.com/', document.discussion_links.first.url
    assert_equal 'our slack', document.discussion_links.first.label
  end

  test 'should update document with edited discussion link' do
    person = FactoryBot.create(:person)
    document = FactoryBot.create(:document, contributor: person, discussion_links:[FactoryBot.create(:discussion_link)])
    login_as(person)
    assert_equal 1,document.discussion_links.count
    assert_no_difference('AssetLink.discussion.count') do
      assert_difference('ActivityLog.count') do
        put :update, params: { id: document.id, document: { discussion_links_attributes:[{id:document.discussion_links.first.id, url: "http://www.wibble.com/"}] } }
      end
    end
    document = assigns(:document)
    assert_redirected_to document_path(document)
    assert_equal 1,document.discussion_links.count
    assert_equal 'http://www.wibble.com/', document.discussion_links.first.url
  end

  test 'should destroy related asset link' do
    person = FactoryBot.create(:person)
    login_as(person)
    asset_link = FactoryBot.create(:discussion_link)
    document = FactoryBot.create(:document, discussion_links: [asset_link], policy: FactoryBot.create(:public_policy, access_type: Policy::VISIBLE), contributor: person)
    refute_empty document.discussion_links
    assert_difference('AssetLink.discussion.count', -1) do
      put :update, params: { id: document.id, document: { discussion_links_attributes:[{id:asset_link.id, _destroy:'1'}] } }
    end
    document = assigns(:document)
    assert_redirected_to document_path(document)
    assert_empty document.discussion_links
  end

  test 'should return to project page after destroy' do
    person = FactoryBot.create(:person)
    project = FactoryBot.create(:project)
    document = FactoryBot.create(:document, contributor: person, project_ids: [project.id])
    login_as(person)
    assert_difference('Document.count', -1) do
      assert_no_difference('ContentBlob.count') do
        delete :destroy, params: { id: document, return_to: project_path(project)}
      end
    end
    assert_redirected_to project_path(project)
  end

  test "shouldn't return to unauthorised host" do
    person = FactoryBot.create(:person)
    project = FactoryBot.create(:project)
    document = FactoryBot.create(:document, contributor: person, project_ids: [project.id])
    login_as(person)
    assert_difference('Document.count', -1) do
      assert_no_difference('ContentBlob.count') do
        delete :destroy, params: { id: document, return_to: "https://www.google.co.uk/"}
      end
    end
    assert_redirected_to documents_path
  end

  test 'shows creators in order in author box' do
    person = FactoryBot.create(:person, first_name: 'Jessica', last_name: 'Three')
    document = FactoryBot.create(:public_document)
    disable_authorization_checks do
      document.assets_creators.create!(given_name: 'Julia', family_name: 'Two', pos: 2, affiliation: 'University of Sheffield', orcid: 'https://orcid.org/0000-0001-8172-8981')
      document.assets_creators.create!(creator: person, pos: 3)
      document.assets_creators.create!(given_name: 'Jill', family_name: 'One', pos: 1)
      document.assets_creators.create!(given_name: 'Jane', family_name: 'Four', pos: 4, affiliation: 'University of Edinburgh')
    end

    get :show, params: { id: document }

    assert_select '#author-box ul' do
      assert_select '.author-list-item:nth-child(1)', text: 'Jill One'

      assert_select '.author-list-item:nth-child(2)', text: 'Julia Two'
      assert_select '.author-list-item:nth-child(2)[title=?]', 'Julia Two, University of Sheffield'
      assert_select '.author-list-item:nth-child(2) a.orcid-link[href=?]', 'https://orcid.org/0000-0001-8172-8981'

      assert_select '.author-list-item:nth-child(3)', text: 'Jessica Three'
      assert_select '.author-list-item:nth-child(3) a[href=?]', person_path(person)

      assert_select '.author-list-item:nth-child(4)', text: 'Jane Four'
      assert_select '.author-list-item:nth-child(4)[title=?]', 'Jane Four, University of Edinburgh'
    end
  end

  test 'shows creators in order in resource list item' do
    person = FactoryBot.create(:person, first_name: 'Jessica', last_name: 'Three')
    document = FactoryBot.create(:public_document, other_creators: 'Joy Five')
    disable_authorization_checks do
      document.assets_creators.create!(given_name: 'Julia', family_name: 'Two', pos: 2, affiliation: 'University of Sheffield', orcid: 'https://orcid.org/0000-0001-8172-8981')
      document.assets_creators.create!(creator: person, pos: 3)
      document.assets_creators.create!(given_name: 'Jill', family_name: 'One', pos: 1)
      document.assets_creators.create!(given_name: 'Jane', family_name: 'Four', pos: 4, affiliation: 'University of Edinburgh')
    end

    get :index

    assert_select '.rli-person-list', text: 'Creators: Jill One, Julia Two, Jessica Three, Jane Four, Joy Five'
    assert_select '.rli-person-list' do
      assert_select ':nth-child(2)', text: 'Jill One'

      assert_select ':nth-child(3)', text: 'Julia Two'
      assert_select ':nth-child(3)[title=?]', 'Julia Two, University of Sheffield'
      assert_select ':nth-child(3)[href=?]', 'https://orcid.org/0000-0001-8172-8981'

      assert_select ':nth-child(4)', text: 'Jessica Three'
      assert_select ':nth-child(4)[href=?]', person_path(person)

      assert_select ':nth-child(5)', text: 'Jane Four'
      assert_select ':nth-child(5)[title=?]', 'Jane Four, University of Edinburgh'
    end
  end

  test 'sharing with programme only shows if enabled' do
    doc = FactoryBot.create :document
    login_as(doc.contributor)

    with_config_value :programmes_enabled, true do
      get :manage, params: { id: doc }
      assert_response :success

      assert_select 'a#add-programme-permission-button', text: /Share with a Programme/, count: 1
    end

    with_config_value :programmes_enabled, false do
      get :manage, params: { id: doc }
      assert_response :success

      assert_select 'a#add-programme-permission-button', text: /Share with a Programme/, count: 0
    end

  end

  private

  def valid_document
    { title: 'Test', project_ids: [projects(:sysmo_project).id] }
  end

  def valid_content_blob
    { data: fixture_file_upload('a_pdf_file.pdf'), data_url: '' }
  end
end
