require 'test_helper'
require 'minitest/mock'

class DocumentsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases
  include SharingFormTestHelper
  include MockHelper
  include HtmlHelper
  include GeneralAuthorizationTestCases

  def test_json_content
    login_as(Factory(:user))
    super
  end

  def rest_api_test_object
    @object = Factory(:public_document)
  end

  def edit_max_object(document)
    add_tags_to_test_object(document)
    add_creator_to_test_object(document)
  end

  test 'should return 406 when requesting RDF' do
    login_as(Factory(:user))
    doc = Factory :document, contributor: User.current_user.person
    assert doc.can_view?

    get :show, params: { id: doc, format: :rdf }

    assert_response :not_acceptable
  end

  test 'should get index' do
    FactoryGirl.create_list(:public_document, 3)

    get :index

    assert_response :success
    assert assigns(:documents).any?
  end

  test "shouldn't show hidden items in index" do
    visible_doc = Factory(:public_document)
    hidden_doc = Factory(:private_document)

    get :index, params: { page: 'all' }

    assert_response :success
    assert_includes assigns(:documents), visible_doc
    assert_not_includes assigns(:documents), hidden_doc
  end

  test 'should show' do
    visible_doc = Factory(:public_document)

    get :show, params: { id: visible_doc }

    assert_response :success
  end

  test 'should not show hidden document' do
    hidden_doc = Factory(:private_document)

    get :show, params: { id: hidden_doc }

    assert_response :forbidden
  end

  test 'should get new' do
    login_as(Factory(:person))

    get :new
    assert_response :success
    assert_select 'h1', text: "New #{I18n.t('document')}"
  end

  test 'should get edit' do
    login_as(Factory(:person))

    get :new
    assert_response :success
    assert_select 'h1', text: "New #{I18n.t('document')}"
  end

  test 'should create document' do
    person = Factory(:person)
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

  test 'should create and link to event' do
    person = Factory(:person)
    login_as(person)
    event = Factory(:event,contributor:person)
    event2 = Factory(:event,contributor:person)
    assert_difference('Document.count') do
      post :create, params: { document: { title: 'Document', project_ids: [person.projects.first.id],event_ids:[event.id.to_s,event2.id.to_s]}, content_blobs: [valid_content_blob], policy_attributes: valid_sharing }
    end

    assert (doc = assigns(:document))
    assert_redirected_to document_path(doc)

    assert_equal [event,event2].sort,doc.events.sort

  end

  test 'should not create event with link to none visible event' do
    person = Factory(:person)
    login_as(person)

    event = Factory(:event)
    refute event.can_view?

    assert_no_difference('Document.count') do
      post :create, params: { document: { title: 'Document', project_ids: [person.projects.first.id],event_ids:[event.id.to_s]}, content_blobs: [valid_content_blob], policy_attributes: valid_sharing }
    end

  end

  test 'should update document' do
    person = Factory(:person)
    document = Factory(:document, contributor: person)
    assay = Factory(:assay, contributor: person)
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
    person = Factory(:person)
    document = Factory(:document, contributor: person)
    assert_empty document.events

    login_as(person)

    event = Factory(:event,contributor:person)

    assert_difference('ActivityLog.count') do
      put :update, params: { id: document.id, document: { title: 'Different title', project_ids: [person.projects.first.id],
                                                event_ids:['',event.id.to_s] } }
    end

    assert (doc = assigns(:document))
    assert_redirected_to document_path(doc)
    assert_equal [event],doc.events
  end

  test 'should destroy document' do
    person = Factory(:person)
    document = Factory(:document, contributor: person)
    login_as(person)

    assert_difference('Document.count', -1) do
      assert_no_difference('ContentBlob.count') do
        delete :destroy, params: { id: document }
      end
    end

    assert_redirected_to documents_path
  end

  test 'should be able to view pdf content' do
    doc = Factory(:public_document)
    assert doc.content_blob.is_content_viewable?
    get :show, params: { id: doc.id }
    assert_response :success
    assert_select 'a', text: /View content/, count: 1
  end

  test "assay documents through nested routing" do
    assert_routing 'assays/2/documents', controller: 'documents', action: 'index', assay_id: '2'
    person = Factory(:person)
    login_as(person)
    assay = Factory(:assay, contributor:person)
    document = Factory(:document,assays:[assay],contributor:person)
    document2 = Factory(:document,contributor:person)


    get :index, params: { assay_id: assay.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', document_path(document), text: document.title
      assert_select 'a[href=?]', document_path(document2), text: document2.title, count: 0
    end
  end

  test "studies documents through nested routing" do
    assert_routing 'studies/2/documents', controller: 'documents', action: 'index', study_id: '2'
    person = Factory(:person)
    login_as(person)
    assay = Factory(:assay, contributor:person)
    document = Factory(:document,assays:[assay],contributor:person)
    document2 = Factory(:document,contributor:person)


    get :index, params: { study_id: assay.study.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', document_path(document), text: document.title
      assert_select 'a[href=?]', document_path(document2), text: document2.title, count: 0
    end
  end

  test "investigation documents through nested routing" do
    assert_routing 'investigations/2/documents', controller: 'documents', action: 'index', investigation_id: '2'
    person = Factory(:person)
    login_as(person)
    assay = Factory(:assay, contributor:person)
    document = Factory(:document,assays:[assay],contributor:person)
    document2 = Factory(:document,contributor:person)


    get :index, params: { investigation_id: assay.study.investigation.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', document_path(document), text: document.title
      assert_select 'a[href=?]', document_path(document2), text: document2.title, count: 0
    end
  end

  test "people documents through nested routing" do
    assert_routing 'people/2/documents', controller: 'documents', action: 'index', person_id: '2'
    person = Factory(:person)
    login_as(person)
    assay = Factory(:assay, contributor:person)
    document = Factory(:document,assays:[assay],contributor:person)
    document2 = Factory(:document,policy: Factory(:public_policy),contributor:Factory(:person))


    get :index, params: { person_id: person.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', document_path(document), text: document.title
      assert_select 'a[href=?]', document_path(document2), text: document2.title, count: 0
    end
  end

  test "project documents through nested routing" do
    assert_routing 'projects/2/documents', controller: 'documents', action: 'index', project_id: '2'
    person = Factory(:person)
    login_as(person)
    assay = Factory(:assay, contributor:person)
    document = Factory(:document,assays:[assay],contributor:person)
    document2 = Factory(:document,policy: Factory(:public_policy),contributor:Factory(:person))


    get :index, params: { project_id: person.projects.first.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', document_path(document), text: document.title
      assert_select 'a[href=?]', document_path(document2), text: document2.title, count: 0
    end
  end

  test 'manage menu item appears according to permission' do
    check_manage_edit_menu_for_type('document')
  end

  test 'can access manage page with manage rights' do
    person = Factory(:person)
    document = Factory(:document, contributor:person)
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

    assert_select 'div#author_form', count:1
  end

  test 'cannot access manage page with edit rights' do
    person = Factory(:person)
    document = Factory(:document, policy:Factory(:private_policy, permissions:[Factory(:permission, contributor:person, access_type:Policy::EDITING)]))
    login_as(person)
    assert document.can_edit?
    refute document.can_manage?
    get :manage, params: {id:document}
    assert_redirected_to document
    refute_nil flash[:error]
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

    document = Factory(:document, contributor:person, projects:[proj1], policy:Factory(:private_policy))

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
    proj1=Factory(:project)
    proj2=Factory(:project)
    person = Factory(:person, project:proj1)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!

    other_person = Factory(:person)

    other_creator = Factory(:person,project:proj1)
    other_creator.add_to_project_and_institution(proj2,other_creator.institutions.first)
    other_creator.save!

    document = Factory(:document, projects:[proj1], policy:Factory(:private_policy,
                                                         permissions:[Factory(:permission,contributor:person, access_type:Policy::EDITING)]))

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

  private

  def valid_document
    { title: 'Test', project_ids: [projects(:sysmo_project).id] }
  end

  def valid_content_blob
    { data: fixture_file_upload('files/a_pdf_file.pdf'), data_url: '' }
  end
end
