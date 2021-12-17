require 'test_helper'
require 'minitest/mock'

class PresentationsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  include SharingFormTestHelper
  include RestTestCases
  include GeneralAuthorizationTestCases

  def setup
    login_as Factory(:user)
    @project = User.current_user.person.projects.first
  end

  def rest_api_test_object
    @object = Factory :presentation, contributor: User.current_user.person
    @object.annotate_with 'tag1'
    @object
  end

  test 'index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:presentations)
  end

  test 'can create with valid url' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://somewhere.com/piccy.png'
    presentation_attrs = Factory.attributes_for(:presentation,
                                                project_ids: [@project.id]
                                               )

    assert_difference 'Presentation.count' do
      post :create, params: { presentation: presentation_attrs, content_blobs: [{ data_url: 'http://somewhere.com/piccy.png', data: nil }], sharing: valid_sharing }
    end
  end

  test 'can create with local file' do
    presentation_attrs = Factory.attributes_for(:presentation,
                                                contributor: User.current_user,
                                                project_ids: [@project.id])

    assert_difference 'ActivityLog.count' do
      assert_difference 'Presentation.count' do
        post :create, params: { presentation: presentation_attrs, content_blobs: [{ data: file_for_upload }], sharing: valid_sharing }
      end
    end
  end

  test 'can edit' do
    presentation = Factory :presentation, contributor: User.current_user.person

    get :edit, params: { id: presentation }
    assert_response :success
  end

  test 'can update' do
    presentation = Factory :presentation, contributor: User.current_user.person
    post :update, params: { id: presentation, presentation: { title: 'updated' } }
    assert_redirected_to presentation_path(presentation)
  end

  test 'should show presentation' do
    presentation = Factory :ppt_presentation, contributor: User.current_user.person
    assert_difference 'ActivityLog.count' do
      get :show, params: { id: presentation }
    end

    assert_response :success

    assert_select 'div.box_about_actor' do
      assert_select 'p > b', text: /Filename:/
      assert_select 'p', text: /ppt_presentation\.ppt/
      assert_select 'p > b', text: /Format:/
      assert_select 'p', text: /PowerPoint presentation/
      assert_select 'p > b', text: /Size:/
      assert_select 'p', text: /80.5 KB/
    end
  end

  test 'can upload new version with valid url' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://somewhere.com/piccy.png'
    presentation = Factory :presentation, contributor: User.current_user.person

    assert_difference 'presentation.version' do
      post :create_version, params: { id: presentation, presentation: {}, content_blobs: [{ data_url: 'http://somewhere.com/piccy.png' }] }

      presentation.reload
    end
    assert_redirected_to presentation_path(presentation)
  end

  test 'can upload new version with valid filepath' do
    # by default, valid data_url is provided by content_blob in Factory
    presentation = Factory :presentation, contributor: User.current_user.person
    presentation.content_blob.url = nil
    presentation.content_blob.data = file_for_upload
    presentation.reload

    new_file_path = file_for_upload
    assert_difference 'presentation.version' do
      post :create_version, params: { id: presentation, presentation: {}, content_blobs: [{ data: new_file_path }] }

      presentation.reload
    end
    assert_redirected_to presentation_path(presentation)
  end

  test 'cannot upload file with invalid url' do
    stub_request(:head, 'http://www.blah.de/images/logo.png').to_raise(SocketError)
    presentation_attrs = Factory.build(:presentation, contributor: User.current_user.person).attributes # .symbolize_keys(turn string key to symbol)

    assert_no_difference 'Presentation.count' do
      post :create, params: { presentation: presentation_attrs, content_blobs: [{ data_url: 'http://www.blah.de/images/logo.png' }] }
    end
    assert_not_nil flash[:error]
  end

  test 'cannot upload new version with invalid url' do
    stub_request(:any, 'http://www.blah.de/images/liver-illustration.png').to_raise(SocketError)
    presentation = Factory :presentation, contributor: User.current_user.person
    new_data_url = 'http://www.blah.de/images/liver-illustration.png'
    assert_no_difference 'presentation.version' do
      post :create_version, params: { id: presentation, presentation: {}, content_blobs: [{ data_url: new_data_url }] }

      presentation.reload
    end
    assert_not_nil flash[:error]
  end

  test 'can destroy' do
    presentation = Factory :presentation, contributor: User.current_user.person
    content_blob_id = presentation.content_blob.id
    assert_difference('Presentation.count', -1) do
      delete :destroy, params: { id: presentation }
    end
    assert_redirected_to presentations_path

    # data/url is still stored in content_blob
    assert_not_nil ContentBlob.find_by_id(content_blob_id)
  end

  test 'can subscribe' do
    presentation = Factory :presentation, contributor: User.current_user.person
    assert_difference 'presentation.subscriptions.count' do
      presentation.subscribed = true
      presentation.save
    end
  end

  test 'update tags with ajax' do
    p = Factory :person

    login_as p.user

    p2 = Factory :person
    presentation = Factory :presentation, contributor: p

    assert presentation.annotations.empty?, 'this presentation should have no tags for the test'

    golf = Factory :tag, annotatable: presentation, source: p2.user, value: 'golf'
    Factory :tag, annotatable: presentation, source: p2.user, value: 'sparrow'

    presentation.reload

    assert_equal %w(golf sparrow), presentation.annotations.collect { |a| a.value.text }.sort
    assert_equal [], presentation.annotations.select { |a| a.source == p.user }.collect { |a| a.value.text }.sort
    assert_equal %w(golf sparrow), presentation.annotations.select { |a| a.source == p2.user }.collect { |a| a.value.text }.sort

    post :update_annotations_ajax, xhr: true, params: { id: presentation, tag_list: "soup,#{golf.value.text}" }

    presentation.reload

    assert_equal %w(golf soup sparrow), presentation.annotations.collect { |a| a.value.text }.uniq.sort
    assert_equal %w(golf soup), presentation.annotations.select { |a| a.source == p.user }.collect { |a| a.value.text }.sort
    assert_equal %w(golf sparrow), presentation.annotations.select { |a| a.source == p2.user }.collect { |a| a.value.text }.sort
  end

  test 'should download Presentation from standard route' do
    pres = Factory :ppt_presentation, policy: Factory(:public_policy)
    login_as(pres.contributor.user)
    assert_difference('ActivityLog.count') do
      get :download, params: { id: pres.id }
    end
    assert_response :success
    al = ActivityLog.last
    assert_equal 'download', al.action
    assert_equal pres, al.activity_loggable
    assert_equal 'attachment; filename="ppt_presentation.ppt"', @response.header['Content-Disposition']
    assert_equal 'application/vnd.ms-powerpoint', @response.header['Content-Type']
    assert_equal '82432', @response.header['Content-Length']
  end

  test 'should set the other creators ' do
    user = Factory(:user)
    presentation = Factory(:presentation, contributor: user.person)
    login_as(user)
    assert presentation.can_manage?, 'The presentation must be manageable for this test to succeed'
    put :update, params: { id: presentation, presentation: { other_creators: 'marry queen' } }
    presentation.reload
    assert_equal 'marry queen', presentation.other_creators
  end

  test 'should show the other creators on the presentation index' do
    Factory(:presentation, policy: Factory(:public_policy), other_creators: 'another creator')
    get :index
    assert_select 'p.list_item_attribute', text: /: another creator/, count: 1
  end

  test 'should show the other creators in -uploader and creators- box' do
    presentation = Factory(:presentation, policy: Factory(:public_policy), other_creators: 'another creator')
    get :show, params: { id: presentation }
    assert_select '#author-box .additional-credit', text: 'another creator', count: 1
  end

  test 'should be able to view ms/open office ppt content' do
    Seek::Config.stub(:soffice_available?, true) do
      ms_ppt_presentation = Factory(:ppt_presentation, policy: Factory(:all_sysmo_downloadable_policy))
      assert ms_ppt_presentation.content_blob.is_content_viewable?
      get :show, params: { id: ms_ppt_presentation.id }
      assert_response :success
      assert_select 'a', text: /View content/, count: 1
      assert_select 'a.disabled', text: /View content/, count: 0

      openoffice_ppt_presentation = Factory(:odp_presentation, policy: Factory(:all_sysmo_downloadable_policy))
      assert openoffice_ppt_presentation.content_blob.is_content_viewable?
      get :show, params: { id: openoffice_ppt_presentation.id }
      assert_response :success
      assert_select 'a', text: /View content/, count: 1
      assert_select 'a.disabled', text: /View content/, count: 0
    end
  end

  test 'view content disabled for ms/open office ppt content if soffice not available and conversion required' do
    Seek::Config.stub(:soffice_available?, false) do
      ms_ppt_presentation = Factory(:ppt_presentation, policy: Factory(:all_sysmo_downloadable_policy))
      assert ms_ppt_presentation.content_blob.file_exists?
      refute ms_ppt_presentation.content_blob.file_exists?('pdf')
      get :show, params: { id: ms_ppt_presentation.id }
      assert_response :success
      assert_select 'a.disabled', text: /View content/, count: 1

      openoffice_ppt_presentation = Factory(:odp_presentation, policy: Factory(:all_sysmo_downloadable_policy))
      assert openoffice_ppt_presentation.content_blob.file_exists?
      refute openoffice_ppt_presentation.content_blob.file_exists?('pdf')
      get :show, params: { id: openoffice_ppt_presentation.id }
      assert_response :success
      assert_select 'a.disabled', text: /View content/, count: 1
    end
  end

  test 'should display the file icon according to version' do
    ms_ppt_presentation = Factory(:ppt_presentation, policy: Factory(:all_sysmo_downloadable_policy))
    get :show, params: { id: ms_ppt_presentation.id }
    assert_response :success
    assert_select 'img[src=?]', '/assets/file_icons/small/ppt.png'

    # new version
    pdf_presentation = Factory(:presentation_version, presentation: ms_ppt_presentation)
    content_blob = Factory(:pdf_content_blob, asset: ms_ppt_presentation, asset_version: 2)
    ms_ppt_presentation.reload
    assert_equal 2, ms_ppt_presentation.versions.count
    assert_not_nil ms_ppt_presentation.find_version(2).content_blob

    get :show, params: { id: ms_ppt_presentation.id, version: 2 }
    assert_response :success
    assert_select 'img[src=?]', '/assets/file_icons/small/pdf.png'
  end

  test 'filter by people, including creators, using nested routes' do
    assert_routing 'people/7/presentations', controller: 'presentations', action: 'index', person_id: '7'

    person1 = Factory(:person)
    person2 = Factory(:person)

    pres1 = Factory(:presentation, contributor: person1, policy: Factory(:public_policy))
    pres2 = Factory(:presentation, contributor: person2, policy: Factory(:public_policy))

    pres3 = Factory(:presentation, contributor: Factory(:person), creators: [person1], policy: Factory(:public_policy))
    pres4 = Factory(:presentation, contributor: Factory(:person), creators: [person2], policy: Factory(:public_policy))

    get :index, params: { person_id: person1.id }
    assert_response :success

    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', presentation_path(pres1), text: pres1.title
      assert_select 'a[href=?]', presentation_path(pres3), text: pres3.title

      assert_select 'a[href=?]', presentation_path(pres2), text: pres2.title, count: 0
      assert_select 'a[href=?]', presentation_path(pres4), text: pres4.title, count: 0
    end
  end

  test 'filter by publications using nested routes' do
    assert_routing 'publications/7/presentations', controller: 'presentations', action: 'index', publication_id: '7'

    pub1 = Factory(:publication)
    pub2 = Factory(:publication)

    pres1 = Factory(:presentation, policy: Factory(:public_policy), publications:[pub1])
    pres2 = Factory(:presentation, policy: Factory(:public_policy), publications:[pub2])

    get :index, params: { publication_id: pub1.id }
    assert_response :success

    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', presentation_path(pres1), text: pres1.title
      assert_select 'a[href=?]', presentation_path(pres2), text: pres2.title, count: 0
    end
  end

  test 'filter by workflow using nested routes' do
    assert_routing 'workflows/7/presentations', controller: 'presentations', action: 'index', workflow_id: '7'

    workflow = Factory(:workflow, policy: Factory(:public_policy))

    pres1 = Factory(:presentation, policy: Factory(:public_policy), workflows:[workflow])
    pres2 = Factory(:presentation, policy: Factory(:public_policy))

    get :index, params: { workflow_id: workflow.id }
    assert_response :success

    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', presentation_path(pres1), text: pres1.title
      assert_select 'a[href=?]', presentation_path(pres2), text: pres2.title, count: 0
    end
  end


  test 'should display null license text' do
    presentation = Factory :presentation, policy: Factory(:public_policy)

    get :show, params: { id: presentation }

    assert_select '.panel .panel-body span#null_license', text: I18n.t('null_license')
  end

  test 'should display license' do
    presentation = Factory :presentation, license: 'CC-BY-4.0', policy: Factory(:public_policy)

    get :show, params: { id: presentation }

    assert_select '.panel .panel-body a', text: 'Creative Commons Attribution 4.0'
  end

  test 'should display license for current version' do
    presentation = Factory :presentation, license: 'CC-BY-4.0', policy: Factory(:public_policy)
    presentationv = Factory :presentation_version_with_blob, presentation: presentation

    presentation.update_attributes license: 'CC0-1.0'

    get :show, params: { id: presentation, version: 1 }
    assert_response :success
    assert_select '.panel .panel-body a', text: 'Creative Commons Attribution 4.0'

    get :show, params: { id: presentation, version: presentationv.version }
    assert_response :success
    assert_select '.panel .panel-body a', text: 'CC0 1.0'
  end

  test 'should update license' do
    user = Factory(:person).user
    login_as(user)
    presentation = Factory :presentation, policy: Factory(:public_policy), contributor: user.person

    assert_nil presentation.license

    put :update, params: { id: presentation, presentation: { license: 'CC-BY-SA-4.0' } }

    assert_response :redirect

    get :show, params: { id: presentation }
    assert_select '.panel .panel-body a', text: 'Creative Commons Attribution Share-Alike 4.0'
    assert_equal 'CC-BY-SA-4.0', assigns(:presentation).license
  end

  test 'should update linked workflow' do
    user = Factory(:person).user
    login_as(user)
    presentation = Factory :presentation, policy: Factory(:public_policy), contributor: user.person
    workflow = Factory(:workflow, contributor: user.person)

    assert_empty presentation.workflows

    put :update, params: { id: presentation, presentation: { workflow_ids: [workflow.id] } }

    assert_response :redirect

    assert_equal [workflow], assigns(:presentation).workflows
  end

  test 'programme presentations through nested routing' do
    assert_routing 'programmes/2/presentations', controller: 'presentations', action: 'index', programme_id: '2'
    programme = Factory(:programme, projects: [@project])
    assert_equal [@project], programme.projects
    presentation = Factory(:presentation, policy: Factory(:public_policy), contributor:User.current_user.person)
    presentation2 = Factory(:presentation, policy: Factory(:public_policy))

    get :index, params: { programme_id: programme.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', presentation_path(presentation), text: presentation.title
      assert_select 'a[href=?]', presentation_path(presentation2), text: presentation2.title, count: 0
    end
  end

  test 'should return 406 when showing presentation as RDF' do
    presentation = Factory :ppt_presentation, contributor: User.current_user.person

    get :show, params: { id: presentation, format: :rdf }

    assert_response :not_acceptable
  end

  test 'events should be ordered by start date' do
    person = Factory(:person)
    login_as(person.user)
    event_july = Factory(:event, title:'July event', start_date:DateTime.parse('1 July 2020'), contributor:person)
    event_jan = Factory(:event, title:'Jan event', start_date:DateTime.parse('1 Jan 2020'), contributor:person)
    event_sep = Factory(:event, title:'September event', start_date:DateTime.parse('1 September 2020'), contributor:person)
    event_dec = Factory(:event, title:'December event', start_date:DateTime.parse('1 December 2020'), contributor:person)
    event_march = Factory(:event, title:'March event', start_date:DateTime.parse('1 March 2020'), contributor:person)

    get :new

    desired = [event_july,event_jan,event_sep,event_dec,event_march].sort_by(&:start_date).collect{|e| e.id.to_s}
    # first element is the blank, "select event ..."
    ids = assert_select('select#possible_presentation_event_ids option').collect{|el| el.attributes['value'].value}.drop(1)

    assert_equal desired, ids

  end

  test 'manage menu item appears according to permission' do
    check_manage_edit_menu_for_type('presentation')
  end

  test 'can access manage page with manage rights' do
    person = Factory(:person)
    presentation = Factory(:presentation, contributor:person)
    login_as(person)
    assert presentation.can_manage?
    get :manage, params: {id: presentation}
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
    person = Factory(:person)
    presentation = Factory(:presentation, policy:Factory(:private_policy, permissions:[Factory(:permission, contributor:person, access_type:Policy::EDITING)]))
    login_as(person)
    assert presentation.can_edit?
    refute presentation.can_manage?
    get :manage, params: {id:presentation}
    assert_redirected_to presentation
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

    presentation = Factory(:presentation, contributor:person, projects:[proj1], policy:Factory(:private_policy))

    login_as(person)
    assert presentation.can_manage?

    patch :manage_update, params: {id: presentation,
                                   presentation: {
                                       creator_ids: [other_creator.id],
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    assert_redirected_to presentation

    presentation.reload
    assert_equal [proj1,proj2],presentation.projects.sort_by(&:id)
    assert_equal [other_creator],presentation.creators
    assert_equal Policy::VISIBLE,presentation.policy.access_type
    assert_equal 1,presentation.policy.permissions.count
    assert_equal other_person,presentation.policy.permissions.first.contributor
    assert_equal Policy::MANAGING,presentation.policy.permissions.first.access_type

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

    presentation = Factory(:presentation, projects:[proj1], policy:Factory(:private_policy,
                                                                           permissions:[Factory(:permission,contributor:person, access_type:Policy::EDITING)]))

    login_as(person)
    refute presentation.can_manage?
    assert presentation.can_edit?

    assert_equal [proj1],presentation.projects
    assert_empty presentation.creators

    patch :manage_update, params: {id: presentation,
                                   presentation: {
                                       creator_ids: [other_creator.id],
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    refute_nil flash[:error]

    presentation.reload
    assert_equal [proj1],presentation.projects
    assert_empty presentation.creators
    assert_equal Policy::PRIVATE,presentation.policy.access_type
    assert_equal 1,presentation.policy.permissions.count
    assert_equal person,presentation.policy.permissions.first.contributor
    assert_equal Policy::EDITING,presentation.policy.permissions.first.access_type

  end

  test 'should create with discussion link' do
    person = Factory(:person)
    login_as(person)
    presentation =  {title: 'Presentation', project_ids: [person.projects.first.id], discussion_links_attributes:[{url: "http://www.slack.com/"}]}
    assert_difference('AssetLink.discussion.count') do
      assert_difference('Presentation.count') do
        assert_difference('ContentBlob.count') do
          post :create, params: {presentation: presentation, content_blobs: [{ data: file_for_upload }], policy_attributes: { access_type: Policy::VISIBLE }}
        end
      end
    end
    presentation = assigns(:presentation)
    assert_equal 'http://www.slack.com/', presentation.discussion_links.first.url
    assert_equal AssetLink::DISCUSSION, presentation.discussion_links.first.link_type
  end

  test 'should show discussion link' do
    asset_link = Factory(:discussion_link)
    presentation = Factory(:presentation, discussion_links: [asset_link], policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    get :show, params: { id: presentation }
    assert_response :success
    assert_select 'div.panel-heading', text: /Discussion Channel/, count: 1
  end

  test 'should update presentation with new discussion link' do
    person = Factory(:person)
    presentation = Factory(:presentation, contributor: person)
    login_as(person)
    assert_nil presentation.discussion_links.first
    assert_difference('AssetLink.discussion.count') do
      assert_difference('ActivityLog.count') do
        put :update, params: { id: presentation.id, presentation: { discussion_links_attributes:[{url: "http://www.slack.com/"}] }  }
      end
    end
    assert_redirected_to presentation_path(presentation = assigns(:presentation))
    assert_equal 'http://www.slack.com/', presentation.discussion_links.first.url
  end

  test 'should update sop with edited discussion link' do
    person = Factory(:person)
    presentation = Factory(:presentation, contributor: person, discussion_links:[Factory(:discussion_link)])
    login_as(person)
    assert_equal 1,presentation.discussion_links.count
    assert_no_difference('AssetLink.discussion.count') do
      assert_difference('ActivityLog.count') do
        put :update, params: { id: presentation.id, presentation: { discussion_links_attributes:[{id:presentation.discussion_links.first.id, url: "http://www.wibble.com/"}] } }
      end
    end
    presentation = assigns(:presentation)
    assert_redirected_to presentation_path(presentation)
    assert_equal 1,presentation.discussion_links.count
    assert_equal 'http://www.wibble.com/', presentation.discussion_links.first.url
  end

  test 'should destroy related asset link when the discussion link is removed ' do
    person = Factory(:person)
    login_as(person)
    asset_link = Factory(:discussion_link)
    presentation = Factory(:presentation , discussion_links: [asset_link], policy: Factory(:public_policy, access_type: Policy::VISIBLE), contributor: person)
    assert_difference('AssetLink.discussion.count', -1) do
      put :update, params: { id: presentation.id, presentation: { discussion_links_attributes:[{id:asset_link.id, _destroy:'1'}] } }
    end
    assert_redirected_to presentation_path(presentation = assigns(:presentation ))
    assert_empty presentation.discussion_links
  end

  def edit_max_object(presentation)
    add_tags_to_test_object(presentation)
    add_creator_to_test_object(presentation)
  end
end
