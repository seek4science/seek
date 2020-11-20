require 'test_helper'
require 'minitest/mock'

class NodesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  include SharingFormTestHelper
  include GeneralAuthorizationTestCases

  def setup
    login_as Factory(:user)
    @project = User.current_user.person.projects.first
  end

  test 'should return 406 when requesting RDF' do
    node = Factory :node, contributor: User.current_user.person
    assert node.can_view?

    get :show, params: { id: node, format: :rdf }

    assert_response :not_acceptable
  end

  test 'index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:nodes)
  end

  test 'can create with valid url' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://somewhere.com/piccy.png'
    node_attrs = Factory.attributes_for(:node, project_ids: [@project.id])

    assert_difference 'Node.count' do
      post :create, params: { node: node_attrs, content_blobs: [{ data_url: 'http://somewhere.com/piccy.png', data: nil }], sharing: valid_sharing }
    end
  end

  test 'can create with local file' do
    node_attrs = Factory.attributes_for(:node,
                                        contributor: User.current_user,
                                        project_ids: [@project.id])

    assert_difference 'Node.count' do
      assert_difference 'ActivityLog.count' do
        post :create, params: { node: node_attrs, content_blobs: [{ data: file_for_upload }], sharing: valid_sharing }
      end
    end
  end

  test 'can edit' do
    node = Factory :node, contributor: User.current_user.person

    get :edit, params: { id: node }
    assert_response :success
  end

  test 'can update' do
    node = Factory :node, contributor: User.current_user.person
    post :update, params: { id: node, node: { title: 'updated' } }
    assert_redirected_to node_path(node)
  end

  test 'can upload new version with valid url' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://somewhere.com/piccy.png'
    node = Factory :node, contributor: User.current_user.person

    assert_difference 'node.version' do
      post :create_version, params: { id: node, node: {}, content_blobs: [{ data_url: 'http://somewhere.com/piccy.png' }] }

      node.reload
    end
    assert_redirected_to node_path(node)
  end

  test 'can upload new version with valid filepath' do
    # by default, valid data_url is provided by content_blob in Factory
    node = Factory :node, contributor: User.current_user.person
    node.content_blob.url = nil
    node.content_blob.data = file_for_upload
    node.reload

    new_file_path = file_for_upload
    assert_difference 'node.version' do
      post :create_version, params: { id: node, node: {}, content_blobs: [{ data: new_file_path }] }

      node.reload
    end
    assert_redirected_to node_path(node)
  end

  test 'cannot upload file with invalid url' do
    stub_request(:head, 'http://www.blah.de/images/logo.png').to_raise(SocketError)
    node_attrs = Factory.build(:node, contributor: User.current_user.person).attributes # .symbolize_keys(turn string key to symbol)

    assert_no_difference 'Node.count' do
      post :create, params: { node: node_attrs, content_blobs: [{ data_url: 'http://www.blah.de/images/logo.png' }] }
    end
    assert_not_nil flash[:error]
  end

  test 'cannot upload new version with invalid url' do
    stub_request(:any, 'http://www.blah.de/images/liver-illustration.png').to_raise(SocketError)
    node = Factory :node, contributor: User.current_user.person
    new_data_url = 'http://www.blah.de/images/liver-illustration.png'
    assert_no_difference 'node.version' do
      post :create_version, params: { id: node, node: {}, content_blobs: [{ data_url: new_data_url }] }

      node.reload
    end
    assert_not_nil flash[:error]
  end

  test 'can destroy' do
    node = Factory :node, contributor: User.current_user.person
    content_blob_id = node.content_blob.id
    assert_difference('Node.count', -1) do
      delete :destroy, params: { id: node }
    end
    assert_redirected_to nodes_path

    # data/url is still stored in content_blob
    assert_not_nil ContentBlob.find_by_id(content_blob_id)
  end

  test 'can subscribe' do
    node = Factory :node, contributor: User.current_user.person
    assert_difference 'node.subscriptions.count' do
      node.subscribed = true
      node.save
    end
  end

  test 'update tags with ajax' do
    p = Factory :person

    login_as p.user

    p2 = Factory :person
    node = Factory :node, contributor: p

    assert node.annotations.empty?, 'this node should have no tags for the test'

    golf = Factory :tag, annotatable: node, source: p2.user, value: 'golf'
    Factory :tag, annotatable: node, source: p2.user, value: 'sparrow'

    node.reload

    assert_equal %w(golf sparrow), node.annotations.collect { |a| a.value.text }.sort
    assert_equal [], node.annotations.select { |a| a.source == p.user }.collect { |a| a.value.text }.sort
    assert_equal %w(golf sparrow), node.annotations.select { |a| a.source == p2.user }.collect { |a| a.value.text }.sort

    post :update_annotations_ajax, xhr: true, params: { id: node, tag_list: "soup,#{golf.value.text}" }

    node.reload

    assert_equal %w(golf soup sparrow), node.annotations.collect { |a| a.value.text }.uniq.sort
    assert_equal %w(golf soup), node.annotations.select { |a| a.source == p.user }.collect { |a| a.value.text }.sort
    assert_equal %w(golf sparrow), node.annotations.select { |a| a.source == p2.user }.collect { |a| a.value.text }.sort
  end

  test 'should set the other creators ' do
    user = Factory(:user)
    node = Factory(:node, contributor: user.person)
    login_as(user)
    assert node.can_manage?, 'The node must be manageable for this test to succeed'
    put :update, params: { id: node, node: { other_creators: 'marry queen' } }
    node.reload
    assert_equal 'marry queen', node.other_creators
  end

  test 'should show the other creators on the node index' do
    Factory(:node, policy: Factory(:public_policy), other_creators: 'another creator')
    get :index
    assert_select 'p.list_item_attribute', text: /: another creator/, count: 1
  end

  test 'should show the other creators in -uploader and creators- box' do
    node = Factory(:node, policy: Factory(:public_policy), other_creators: 'another creator')
    get :show, params: { id: node }
    assert_select 'li.author-list-item', text: 'another creator', count: 1
  end

  test 'filter by people, including creators, using nested routes' do
    assert_routing 'people/7/nodes', controller: 'nodes', action: 'index', person_id: '7'

    person1 = Factory(:person)
    person2 = Factory(:person)

    pres1 = Factory(:node, contributor: person1, policy: Factory(:public_policy))
    pres2 = Factory(:node, contributor: person2, policy: Factory(:public_policy))

    pres3 = Factory(:node, contributor: Factory(:person), creators: [person1], policy: Factory(:public_policy))
    pres4 = Factory(:node, contributor: Factory(:person), creators: [person2], policy: Factory(:public_policy))

    get :index, params: { person_id: person1.id }
    assert_response :success

    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', node_path(pres1), text: pres1.title
      assert_select 'a[href=?]', node_path(pres3), text: pres3.title

      assert_select 'a[href=?]', node_path(pres2), text: pres2.title, count: 0
      assert_select 'a[href=?]', node_path(pres4), text: pres4.title, count: 0
    end
  end

  test 'should display null license text' do
    node = Factory :node, policy: Factory(:public_policy)

    get :show, params: { id: node }

    assert_select '.panel .panel-body span#null_license', text: I18n.t('null_license')
  end

  test 'should display license' do
    node = Factory :node, license: 'CC-BY-4.0', policy: Factory(:public_policy)

    get :show, params: { id: node }

    assert_select '.panel .panel-body a', text: 'Creative Commons Attribution 4.0'
  end

  test 'should display license for current version' do
    node = Factory :node, license: 'CC-BY-4.0', policy: Factory(:public_policy)
    nodev = Factory :node_version_with_blob, node: node

    node.update_attributes license: 'CC0-1.0'

    get :show, params: { id: node, version: 1 }
    assert_response :success
    assert_select '.panel .panel-body a', text: 'Creative Commons Attribution 4.0'

    get :show, params: { id: node, version: nodev.version }
    assert_response :success
    assert_select '.panel .panel-body a', text: 'CC0 1.0'
  end

  test 'should update license' do
    user = Factory(:person).user
    login_as(user)
    node = Factory :node, policy: Factory(:public_policy), contributor: user.person

    assert_nil node.license

    put :update, params: { id: node, node: { license: 'CC-BY-SA-4.0' } }

    assert_response :redirect

    get :show, params: { id: node }
    assert_select '.panel .panel-body a', text: 'Creative Commons Attribution Share-Alike 4.0'
    assert_equal 'CC-BY-SA-4.0', assigns(:node).license
  end

  test 'programme nodes through nested routing' do
    assert_routing 'programmes/2/nodes', controller: 'nodes', action: 'index', programme_id: '2'
    programme = Factory(:programme, projects: [@project])
    assert_equal [@project], programme.projects
    node = Factory(:node, policy: Factory(:public_policy), contributor:User.current_user.person)
    node2 = Factory(:node, policy: Factory(:public_policy))

    get :index, params: { programme_id: programme.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', node_path(node), text: node.title
      assert_select 'a[href=?]', node_path(node2), text: node2.title, count: 0
    end
  end

  test 'manage menu item appears according to permission' do
    check_manage_edit_menu_for_type('node')
  end

  test 'can access manage page with manage rights' do
    person = Factory(:person)
    node = Factory(:node, contributor:person)
    login_as(person)
    assert node.can_manage?
    get :manage, params: {id: node}
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
    node = Factory(:node, policy:Factory(:private_policy, permissions:[Factory(:permission, contributor:person, access_type:Policy::EDITING)]))
    login_as(person)
    assert node.can_edit?
    refute node.can_manage?
    get :manage, params: {id:node}
    assert_redirected_to node
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

    node = Factory(:node, contributor:person, projects:[proj1], policy:Factory(:private_policy))

    login_as(person)
    assert node.can_manage?

    patch :manage_update, params: {id: node,
                                   node: {
                                       creator_ids: [other_creator.id],
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    assert_redirected_to node

    node.reload
    assert_equal [proj1,proj2],node.projects.sort_by(&:id)
    assert_equal [other_creator],node.creators
    assert_equal Policy::VISIBLE,node.policy.access_type
    assert_equal 1,node.policy.permissions.count
    assert_equal other_person,node.policy.permissions.first.contributor
    assert_equal Policy::MANAGING,node.policy.permissions.first.access_type

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

    node = Factory(:node, projects:[proj1], policy:Factory(:private_policy,
                                                                   permissions:[Factory(:permission,contributor:person, access_type:Policy::EDITING)]))

    login_as(person)
    refute node.can_manage?
    assert node.can_edit?

    assert_equal [proj1],node.projects
    assert_empty node.creators

    patch :manage_update, params: {id: node,
                                   node: {
                                       creator_ids: [other_creator.id],
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    refute_nil flash[:error]

    node.reload
    assert_equal [proj1],node.projects
    assert_empty node.creators
    assert_equal Policy::PRIVATE,node.policy.access_type
    assert_equal 1,node.policy.permissions.count
    assert_equal person,node.policy.permissions.first.contributor
    assert_equal Policy::EDITING,node.policy.permissions.first.access_type

  end

  test 'should create with discussion link' do
    person = Factory(:person)
    login_as(person)
    node =  {title: 'Node', project_ids: [person.projects.first.id], discussion_links_attributes:[{url: "http://www.slack.com/"}]}
    assert_difference('AssetLink.discussion.count') do
      assert_difference('Node.count') do
        assert_difference('ContentBlob.count') do
          post :create, params: {node: node, content_blobs: [{ data: file_for_upload }], policy_attributes: { access_type: Policy::VISIBLE }}
        end
      end
    end
    node = assigns(:node)
    assert_equal 'http://www.slack.com/', node.discussion_links.first.url
    assert_equal AssetLink::DISCUSSION, node.discussion_links.first.link_type
  end

  test 'should show discussion link' do
    asset_link = Factory(:discussion_link)
    node = Factory(:node, discussion_links: [asset_link], policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    get :show, params: { id: node }
    assert_response :success
    assert_select 'div.panel-heading', text: /Discussion Channel/, count: 1
  end

  test 'should update node with discussion link' do
    person = Factory(:person)
    node = Factory(:node, contributor: person)
    login_as(person)
    assert_nil node.discussion_links.first
    assert_difference('AssetLink.discussion.count') do
      assert_difference('ActivityLog.count') do
        put :update, params: { id: node.id, node: { discussion_links_attributes:[{url: "http://www.slack.com/"}] } }
      end
    end
    assert_redirected_to node_path(assigns(:node))
    assert_equal 'http://www.slack.com/', node.discussion_links.first.url
  end

  test 'should destroy related assetlink when the discussion link is removed ' do
    person = Factory(:person)
    login_as(person)
    asset_link = Factory(:discussion_link)
    node = Factory(:node, discussion_links: [asset_link], policy: Factory(:public_policy, access_type: Policy::VISIBLE), contributor: person)
     assert_difference('AssetLink.discussion.count', -1) do
      put :update, params: { id: node.id, node: { discussion_links_attributes:[{id:asset_link.id, _destroy:'1'}] } }
    end
    assert_redirected_to node_path(node = assigns(:node))
    assert_empty node.discussion_links
  end

  def edit_max_object(node)
    add_tags_to_test_object(node)
    add_creator_to_test_object(node)
  end

end
