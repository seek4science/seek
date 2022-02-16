require 'test_helper'
require 'minitest/mock'

class WorkflowsControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  include SharingFormTestHelper
  include GeneralAuthorizationTestCases

  def setup
    login_as Factory(:user)
    @project = User.current_user.person.projects.first
  end

  test 'should return 406 when requesting RDF' do
    wf = Factory :workflow, contributor: User.current_user.person
    assert wf.can_view?

    get :show, params: { id: wf, format: :rdf }

    assert_response :not_acceptable
  end

  test 'index' do
    Factory(:public_workflow, test_status: :all_passing)
    Factory(:public_workflow, test_status: :all_failing)
    Factory(:public_workflow, test_status: :some_passing)
    get :index
    assert_response :success
    assert_not_nil assigns(:workflows)
  end

  test 'can create with valid url' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://somewhere.com/piccy.png'
    workflow_attrs = Factory.attributes_for(:workflow, project_ids: [@project.id])

    assert_difference 'Workflow.count' do
      post :create, params: { workflow: workflow_attrs, content_blobs: [{ data_url: 'http://somewhere.com/piccy.png', data: nil }], sharing: valid_sharing }
    end
  end

  test 'can create with local file' do
    workflow_attrs = Factory.attributes_for(:workflow,
                                            contributor: User.current_user.person,
                                            project_ids: [@project.id])

    assert_difference 'Workflow.count' do
      assert_difference 'ActivityLog.count' do
        post :create, params: { workflow: workflow_attrs, content_blobs: [{ data: file_for_upload }], sharing: valid_sharing }
      end
    end
  end

  test 'can edit' do
    workflow = Factory :workflow, contributor: User.current_user.person

    get :edit, params: { id: workflow }
    assert_response :success
  end

  test 'can update' do
    workflow = Factory :workflow, contributor: User.current_user.person
    post :update, params: { id: workflow, workflow: { title: 'updated' } }
    assert_redirected_to workflow_path(workflow)
  end

  test 'can upload new version with valid url' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://somewhere.com/piccy.png'
    workflow = Factory :workflow, contributor: User.current_user.person

    assert_difference 'workflow.version' do
      post :create_version, params: { id: workflow, workflow: {}, content_blobs: [{ data_url: 'http://somewhere.com/piccy.png' }] }

      workflow.reload
    end
    assert_redirected_to workflow_path(workflow)
  end

  test 'can upload new version with valid filepath' do
    # by default, valid data_url is provided by content_blob in Factory
    workflow = Factory :workflow, contributor: User.current_user.person
    workflow.content_blob.url = nil
    workflow.content_blob.data = file_for_upload
    workflow.reload

    new_file_path = file_for_upload
    assert_difference 'workflow.version' do
      post :create_version, params: { id: workflow, workflow: {}, content_blobs: [{ data: new_file_path }] }

      workflow.reload
    end
    assert_redirected_to workflow_path(workflow)
  end

  test 'cannot upload file with invalid url' do
    stub_request(:head, 'http://www.blah.de/images/logo.png').to_raise(SocketError)
    workflow_attrs = Factory.build(:workflow, contributor: User.current_user.person).attributes # .symbolize_keys(turn string key to symbol)

    assert_no_difference 'Workflow.count' do
      post :create, params: { workflow: workflow_attrs, content_blobs: [{ data_url: 'http://www.blah.de/images/logo.png' }] }
    end
    assert_not_nil flash[:error]
  end

  test 'cannot upload new version with invalid url' do
    stub_request(:any, 'http://www.blah.de/images/liver-illustration.png').to_raise(SocketError)
    workflow = Factory :workflow, contributor: User.current_user.person
    new_data_url = 'http://www.blah.de/images/liver-illustration.png'
    assert_no_difference 'workflow.version' do
      post :create_version, params: { id: workflow, workflow: {}, content_blobs: [{ data_url: new_data_url }] }

      workflow.reload
    end
    assert_not_nil flash[:error]
  end

  test 'can destroy' do
    workflow = Factory :workflow, contributor: User.current_user.person
    content_blob_id = workflow.content_blob.id
    assert_difference('Workflow.count', -1) do
      delete :destroy, params: { id: workflow }
    end
    assert_redirected_to workflows_path

    # data/url is still stored in content_blob
    assert_not_nil ContentBlob.find_by_id(content_blob_id)
  end

  test 'can subscribe' do
    workflow = Factory :workflow, contributor: User.current_user.person
    assert_difference 'workflow.subscriptions.count' do
      workflow.subscribed = true
      workflow.save
    end
  end

  test 'update tags with ajax' do
    p = Factory :person

    login_as p.user

    p2 = Factory :person
    workflow = Factory :workflow, contributor: p

    assert workflow.annotations.empty?, 'this workflow should have no tags for the test'

    golf = Factory :tag, annotatable: workflow, source: p2.user, value: 'golf'
    Factory :tag, annotatable: workflow, source: p2.user, value: 'sparrow'

    workflow.reload

    assert_equal %w(golf sparrow), workflow.annotations.collect { |a| a.value.text }.sort
    assert_equal [], workflow.annotations.select { |a| a.source == p.user }.collect { |a| a.value.text }.sort
    assert_equal %w(golf sparrow), workflow.annotations.select { |a| a.source == p2.user }.collect { |a| a.value.text }.sort

    post :update_annotations_ajax, xhr: true, params: { id: workflow, tag_list: "soup,#{golf.value.text}" }

    workflow.reload

    assert_equal %w(golf soup sparrow), workflow.annotations.collect { |a| a.value.text }.uniq.sort
    assert_equal %w(golf soup), workflow.annotations.select { |a| a.source == p.user }.collect { |a| a.value.text }.sort
    assert_equal %w(golf sparrow), workflow.annotations.select { |a| a.source == p2.user }.collect { |a| a.value.text }.sort
  end

  test 'should set the other creators ' do
    user = Factory(:user)
    workflow = Factory(:workflow, contributor: user.person)
    login_as(user)
    assert workflow.can_manage?, 'The workflow must be manageable for this test to succeed'
    put :update, params: { id: workflow, workflow: { other_creators: 'marry queen' } }
    workflow.reload
    assert_equal 'marry queen', workflow.other_creators
  end

  test 'should show the other creators on the workflow index' do
    Factory(:workflow, policy: Factory(:public_policy), other_creators: 'another creator')
    get :index
    assert_select 'p.list_item_attribute', text: /: another creator/, count: 1
  end

  test 'should show the other creators in -uploader and creators- box' do
    workflow = Factory(:workflow, policy: Factory(:public_policy), other_creators: 'another creator')
    get :show, params: { id: workflow }
    assert_select '#author-box .additional-credit', text: 'another creator', count: 1
  end

  test 'filter by people, including creators, using nested routes' do
    assert_routing 'people/7/workflows', controller: 'workflows', action: 'index', person_id: '7'

    person1 = Factory(:person)
    person2 = Factory(:person)

    pres1 = Factory(:workflow, contributor: person1, policy: Factory(:public_policy))
    pres2 = Factory(:workflow, contributor: person2, policy: Factory(:public_policy))

    pres3 = Factory(:workflow, contributor: Factory(:person), creators: [person1], policy: Factory(:public_policy))
    pres4 = Factory(:workflow, contributor: Factory(:person), creators: [person2], policy: Factory(:public_policy))

    get :index, params: { person_id: person1.id }
    assert_response :success

    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', workflow_path(pres1), text: pres1.title
      assert_select 'a[href=?]', workflow_path(pres3), text: pres3.title

      assert_select 'a[href=?]', workflow_path(pres2), text: pres2.title, count: 0
      assert_select 'a[href=?]', workflow_path(pres4), text: pres4.title, count: 0
    end
  end

  test 'should display null license text' do
    workflow = Factory :workflow, policy: Factory(:public_policy)

    get :show, params: { id: workflow }

    assert_select '.panel .panel-body span#null_license', text: I18n.t('null_license')
  end

  test 'should display license' do
    workflow = Factory :workflow, license: 'CC-BY-4.0', policy: Factory(:public_policy)

    get :show, params: { id: workflow }

    assert_select '.panel .panel-body a', text: 'Creative Commons Attribution 4.0'
  end

  test 'should display license for current version' do
    workflow = Factory :workflow, license: 'CC-BY-4.0', policy: Factory(:public_policy)
    workflowv = Factory :workflow_version_with_blob, workflow: workflow

    workflow.update_attributes license: 'CC0-1.0'

    get :show, params: { id: workflow, version: 1 }
    assert_response :success
    assert_select '.panel .panel-body a', text: 'Creative Commons Attribution 4.0'

    get :show, params: { id: workflow, version: workflowv.version }
    assert_response :success
    assert_select '.panel .panel-body a', text: 'CC0 1.0'
  end

  test 'should update license' do
    user = Factory(:person).user
    login_as(user)
    workflow = Factory :workflow, policy: Factory(:public_policy), contributor: user.person

    assert_nil workflow.license

    put :update, params: { id: workflow, workflow: { license: 'CC-BY-SA-4.0' } }

    assert_response :redirect

    get :show, params: { id: workflow }
    assert_select '.panel .panel-body a', text: 'Creative Commons Attribution Share-Alike 4.0'
    assert_equal 'CC-BY-SA-4.0', assigns(:workflow).license
  end

  test 'programme workflows through nested routing' do
    assert_routing 'programmes/2/workflows', controller: 'workflows', action: 'index', programme_id: '2'
    programme = Factory(:programme, projects: [@project])
    assert_equal [@project], programme.projects
    workflow = Factory(:workflow, policy: Factory(:public_policy), contributor:User.current_user.person)
    workflow2 = Factory(:workflow, policy: Factory(:public_policy))

    get :index, params: { programme_id: programme.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', workflow_path(workflow), text: workflow.title
      assert_select 'a[href=?]', workflow_path(workflow2), text: workflow2.title, count: 0
    end
  end

  test 'manage menu item appears according to permission' do
    check_manage_edit_menu_for_type('workflow')
  end

  test 'can access manage page with manage rights' do
    person = Factory(:person)
    workflow = Factory(:workflow, contributor:person)
    login_as(person)
    assert workflow.can_manage?
    get :manage, params: {id: workflow}
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
    workflow = Factory(:workflow, policy:Factory(:private_policy, permissions:[Factory(:permission, contributor:person, access_type:Policy::EDITING)]))
    login_as(person)
    assert workflow.can_edit?
    refute workflow.can_manage?
    get :manage, params: {id:workflow}
    assert_redirected_to workflow
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

    workflow = Factory(:workflow, contributor:person, projects:[proj1], policy:Factory(:private_policy))

    login_as(person)
    assert workflow.can_manage?

    patch :manage_update, params: {id: workflow,
                                   workflow: {
                                       creator_ids: [other_creator.id],
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    assert_redirected_to workflow

    workflow.reload
    assert_equal [proj1,proj2],workflow.projects.sort_by(&:id)
    assert_equal [other_creator],workflow.creators
    assert_equal Policy::VISIBLE,workflow.policy.access_type
    assert_equal 1,workflow.policy.permissions.count
    assert_equal other_person,workflow.policy.permissions.first.contributor
    assert_equal Policy::MANAGING,workflow.policy.permissions.first.access_type

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

    workflow = Factory(:workflow, projects:[proj1], policy:Factory(:private_policy,
                                                                   permissions:[Factory(:permission,contributor:person, access_type:Policy::EDITING)]))

    login_as(person)
    refute workflow.can_manage?
    assert workflow.can_edit?

    assert_equal [proj1],workflow.projects
    assert_empty workflow.creators

    patch :manage_update, params: {id: workflow,
                                   workflow: {
                                       creator_ids: [other_creator.id],
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    refute_nil flash[:error]

    workflow.reload
    assert_equal [proj1],workflow.projects
    assert_empty workflow.creators
    assert_equal Policy::PRIVATE,workflow.policy.access_type
    assert_equal 1,workflow.policy.permissions.count
    assert_equal person,workflow.policy.permissions.first.contributor
    assert_equal Policy::EDITING,workflow.policy.permissions.first.access_type
  end

  test 'create content blob' do
    cwl = Factory(:cwl_workflow_class)
    person = Factory(:person)
    login_as(person)
    assert_difference('ContentBlob.count') do
      post :create_content_blob, params: {
          content_blobs: [{ data: fixture_file_upload('files/workflows/rp2-to-rp2path-packed.cwl', 'application/x-yaml') }],
          workflow_class_id: cwl.id }
    end
    assert_response :success
    assert wf = assigns(:workflow)
    refute_nil wf.content_blob
    assert_equal wf.content_blob.id, session[:uploaded_content_blob_id]
    assert_equal cwl, wf.workflow_class
  end

  test 'create content blob requires login' do
    cwl = Factory(:cwl_workflow_class)

    logout
    assert_no_difference('ContentBlob.count') do
      post :create_content_blob, params: {
          content_blobs: [{ data: fixture_file_upload('files/workflows/rp2-to-rp2path-packed.cwl', 'application/x-yaml') }],
          workflow_class_id: cwl.id }
    end
    assert_response :redirect
  end

  test 'create RO-Crate with local content' do
    cwl = Factory(:cwl_workflow_class)
    person = Factory(:person)
    login_as(person)
    assert_difference('ContentBlob.count') do
      post :create_ro_crate, params: {
          ro_crate: {
              workflow: { data: fixture_file_upload('files/checksums.txt') },
                          diagram: { data: fixture_file_upload('files/file_picture.png') },
              abstract_cwl: { data: fixture_file_upload('files/workflows/rp2-to-rp2path-packed.cwl') }
          },
          workflow_class_id: cwl.id
      }
    end
    assert_response :success
    assert wf = assigns(:workflow)
    refute_nil wf.content_blob
    assert_equal wf.content_blob.id, session[:uploaded_content_blob_id]
    assert_equal cwl, wf.workflow_class
    assert_equal 'new-workflow.basic.crate.zip', wf.content_blob.original_filename
  end

  test 'extract metadata' do
    cwl = Factory(:cwl_workflow_class)
    blob = Factory(:cwl_packed_content_blob)
    session[:uploaded_content_blob_id] = blob.id.to_s
    post :metadata_extraction_ajax, params: { content_blob_id: blob.id.to_s, format: 'js', workflow_class_id: cwl.id }
    assert_response :success
    assert_equal 12, session[:metadata][:internals][:inputs].length
  end

  test 'extract metadata from remote should perform inline and cancel remote content fetch job' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/workflows/rp2-to-rp2path-packed.cwl", 'https://www.abc.com/workflow.cwl'
    cwl = Factory(:cwl_workflow_class)
    blob = Factory(:url_cwl_content_blob)
    blob.remote_content_fetch_task.start
    session[:uploaded_content_blob_id] = blob.id.to_s
    post :metadata_extraction_ajax, params: { content_blob_id: blob.id.to_s, format: 'js', workflow_class_id: cwl.id }
    assert blob.reload.remote_content_fetch_task.cancelled?
    assert_response :success
    assert_equal 12, session[:metadata][:internals][:inputs].length
  end

  test 'missing diagram and no CWL viewer available returns 404' do
    wf = Factory(:cwl_workflow)
    login_as(wf.contributor)
    refute wf.diagram_exists?
    refute wf.can_render_diagram?

    get :diagram, params: { id: wf.id }

    assert_response :not_found
  end

  test 'cannot see diagram of private workflow' do
    wf = Factory(:cwl_workflow)
    refute wf.can_view?

    get :diagram, params: { id: wf.id }

    assert_response :redirect
    assert flash[:error].include?('You are not authorized')
  end

  test 'generates diagram if CWL viewer available' do
    with_config_value(:cwl_viewer_url, 'http://localhost:8080/cwl_viewer') do
      wf = Factory(:cwl_workflow)
      login_as(wf.contributor)
      refute wf.diagram_exists?
      assert wf.can_render_diagram?

      VCR.use_cassette('workflows/cwl_viewer_cwl_workflow_diagram') do
        get :diagram, params: { id: wf.id }
      end

      assert_response :success
      assert_equal 'image/svg+xml', response.headers['Content-Type']
      assert wf.diagram_exists?
    end
  end

  test 'picks diagram from RO-Crate' do
    wf = Factory(:existing_galaxy_ro_crate_workflow)
    login_as(wf.contributor)
    refute wf.diagram_exists?
    assert wf.can_render_diagram?

    get :diagram, params: { id: wf.id }

    assert_response :success
    assert_equal 'image/png', response.headers['Content-Type']
    assert wf.diagram_exists?
  end

  test 'generates diagram from CWL workflow in RO-Crate' do
    with_config_value(:cwl_viewer_url, 'http://localhost:8080/cwl_viewer') do
      wf = Factory(:just_cwl_ro_crate_workflow)
      login_as(wf.contributor)
      refute wf.diagram_exists?
      assert_nil wf.ro_crate.main_workflow_diagram
      assert wf.can_render_diagram?

      VCR.use_cassette('workflows/cwl_viewer_cwl_workflow_from_crate_diagram') do
        get :diagram, params: { id: wf.id }
      end

      assert_response :success
      assert_equal 'image/svg+xml', response.headers['Content-Type']
      assert wf.diagram_exists?
    end
  end

  test 'generates diagram from abstract CWL in RO-Crate' do
    with_config_value(:cwl_viewer_url, 'http://localhost:8080/cwl_viewer') do
      wf = Factory(:generated_galaxy_no_diagram_ro_crate_workflow)
      login_as(wf.contributor)
      refute wf.diagram_exists?
      assert wf.can_render_diagram?

      VCR.use_cassette('workflows/cwl_viewer_galaxy_workflow_abstract_cwl_diagram') do
        get :diagram, params: { id: wf.id }
      end

      assert_response :success
      assert_equal 'image/svg+xml', response.headers['Content-Type']
      assert wf.diagram_exists?
    end
  end

  test 'handles error when generating diagram from CWL' do
    with_config_value(:cwl_viewer_url, 'http://localhost:8080/cwl_viewer') do
      wf = Factory(:generated_galaxy_no_diagram_ro_crate_workflow)
      login_as(wf.contributor)
      refute wf.diagram_exists?
      assert wf.can_render_diagram?

      VCR.use_cassette('workflows/cwl_viewer_error') do
        get :diagram, params: { id: wf.id }
      end

      assert_response :not_found
      refute wf.diagram_exists?
    end
  end

  test 'does not render diagram if not in RO-Crate' do
    wf = Factory(:nf_core_ro_crate_workflow)
    login_as(wf.contributor)
    refute wf.diagram_exists?
    refute wf.can_render_diagram?

    get :diagram, params: { id: wf.id }

    assert_response :not_found
    refute wf.diagram_exists?
  end

  test 'should be able to handle spaces in filenames' do
    cwl = Factory(:cwl_workflow_class)
    person = Factory(:person)
    login_as(person)
    assert_difference('ContentBlob.count') do
      post :create_ro_crate, params: {
          ro_crate: {
              workflow: { data: fixture_file_upload('files/file with spaces in name.txt') },
              diagram: { data: fixture_file_upload('files/file_picture.png') },
              abstract_cwl: { data: fixture_file_upload('files/workflows/rp2-to-rp2path-packed.cwl') }
          },
          workflow_class_id: cwl.id
      }
    end
    assert_response :success
    assert wf = assigns(:workflow)
    workflow_crate = ROCrate::WorkflowCrateReader.read_zip(wf.content_blob.path)
    crate_workflow = workflow_crate.main_workflow
    assert crate_workflow
    assert_equal 'file%20with%20spaces%20in%20name.txt', crate_workflow.id
  end

  test 'downloads valid generated RO-Crate' do
    workflow = Factory(:generated_galaxy_ro_crate_workflow, policy: Factory(:public_policy))

    get :ro_crate, params: { id: workflow.id }

    assert_response :success
    assert @response.header['Content-Length'].present?
    assert @response.header['Content-Length'].to_i > 5000 # Length is variable because the crate contains variable data
    Dir.mktmpdir do |dir|
      crate = ROCrate::WorkflowCrateReader.read_zip(response.stream.to_path, target_dir: dir)
      assert crate.main_workflow
    end
  end

  test 'downloads valid existing RO-Crate' do
    workflow = Factory(:existing_galaxy_ro_crate_workflow, policy: Factory(:public_policy))

    get :ro_crate, params: { id: workflow.id }

    assert_response :success
    assert @response.header['Content-Length'].present?
    assert @response.header['Content-Length'].to_i > 5000 # Length is variable because the crate contains variable data
    Dir.mktmpdir do |dir|
      crate = ROCrate::WorkflowCrateReader.read_zip(response.stream.to_path, target_dir: dir)
      assert crate.main_workflow
    end
  end

  test 'downloads valid RO-Crate for single workflow file' do
    workflow = Factory(:cwl_packed_workflow, policy: Factory(:public_policy))

    get :ro_crate, params: { id: workflow.id }

    assert_response :success
    assert @response.header['Content-Length'].present?
    assert @response.header['Content-Length'].to_i > 2000 # Length is variable because the crate contains variable data
    Dir.mktmpdir do |dir|
      crate = ROCrate::WorkflowCrateReader.read_zip(response.stream.to_path, target_dir: dir)
      assert crate.main_workflow
    end
  end

  test 'downloads RO-Crate with metadata for correct version' do
    workflow = Factory(:cwl_workflow, title: 'V1 title', description: 'V1 description',
                       license: 'MIT', other_creators: 'Jane Smith, John Smith', policy: Factory(:public_policy))
    disable_authorization_checks do
      workflow.save_as_new_version
      workflow.update_attributes(title: 'V2 title', description: 'V2 description', workflow_class_id: Factory(:galaxy_workflow_class).id)
      Factory(:generated_galaxy_ro_crate, asset: workflow, asset_version: 2)
    end

    get :ro_crate, params: { id: workflow.id, version: 1 }

    assert_response :success
    assert @response.header['Content-Length'].present?
    assert @response.header['Content-Length'].to_i > 500
    Dir.mktmpdir do |dir|
      crate = ROCrate::WorkflowCrateReader.read_zip(response.stream.to_path, target_dir: dir)
      assert crate.main_workflow
      assert_equal 'V1 title', crate.main_workflow['name']
      assert_equal 'V1 description', crate.main_workflow['description']
      assert_equal 'Common Workflow Language', crate.main_workflow.programming_language['name']
      assert crate.main_workflow.source.read.include?('cwlVersion')
    end

    get :ro_crate, params: { id: workflow.id, version: 2 }

    assert_response :success
    assert @response.header['Content-Length'].present?
    assert @response.header['Content-Length'].to_i > 500
    Dir.mktmpdir do |dir|
      crate = ROCrate::WorkflowCrateReader.read_zip(response.stream.to_path, target_dir: dir)
      assert crate.main_workflow
      assert_equal 'V2 title', crate.main_workflow['name']
      assert_equal 'V2 description', crate.main_workflow['description']
      assert_equal 'Galaxy', crate.main_workflow.programming_language['name']
      assert crate.main_workflow.source.read.include?('a_galaxy_workflow')
    end
  end

  test 'create RO-Crate even with with duplicated filenames' do
    cwl = Factory(:cwl_workflow_class)
    person = Factory(:person)
    login_as(person)
    assert_difference('ContentBlob.count') do
      post :create_ro_crate, params: {
          ro_crate: {
              workflow: { data: fixture_file_upload('files/workflows/rp2-to-rp2path-packed.cwl') },
                          diagram: { data: fixture_file_upload('files/file_picture.png') },
              abstract_cwl: { data: fixture_file_upload('files/workflows/rp2-to-rp2path-packed.cwl') }
          },
          workflow_class_id: cwl.id
      }
    end
    assert_response :success
    workflow_crate = ROCrate::WorkflowCrateReader.read_zip(assigns(:workflow).content_blob.path)
    crate_workflow = workflow_crate.main_workflow
    crate_cwl = workflow_crate.main_workflow_cwl
    assert_not_equal crate_workflow.id, crate_cwl.id
  end

  test 'should create with discussion link' do
    person = Factory(:person)
    login_as(person)
    blob = Factory(:content_blob)
    session[:uploaded_content_blob_id] = blob.id
    workflow =  {title: 'workflow', project_ids: [person.projects.first.id], discussion_links_attributes:[{url: "http://www.slack.com/", label:'our slack'}]}
    assert_difference('AssetLink.discussion.count') do
      assert_difference('Workflow.count') do
          post :create_metadata, params: {workflow: workflow, content_blob_id: blob.id.to_s, policy_attributes: { access_type: Policy::VISIBLE }}
      end
    end
    workflow = assigns(:workflow)
    assert_equal 'http://www.slack.com/', workflow.discussion_links.first.url
    assert_equal 'our slack',workflow.discussion_links.first.label
    assert_equal AssetLink::DISCUSSION, workflow.discussion_links.first.link_type
  end

  test 'should show discussion link without label' do
    asset_link = Factory(:discussion_link)
    workflow = Factory(:workflow, discussion_links: [asset_link], policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    assert_equal [asset_link],workflow.discussion_links
    get :show, params: { id: workflow }
    assert_response :success
    assert_select 'div.panel-heading', text: /Discussion Channel/, count: 1
    assert_select 'div.discussion-link', count:1 do
      assert_select 'a[href=?]',asset_link.url,text:asset_link.url
    end

    #blank rather than nil
    asset_link.update_column(:label,'')
    workflow.reload
    assert_equal [asset_link],workflow.discussion_links
    get :show, params: { id: workflow }
    assert_response :success
    assert_select 'div.panel-heading', text: /Discussion Channel/, count: 1
    assert_select 'div.discussion-link', count:1 do
      assert_select 'a[href=?]',asset_link.url,text:asset_link.url
    end
  end


  test 'should show discussion link with label' do
    asset_link = Factory(:discussion_link, label:'discuss-label')
    workflow = Factory(:workflow, discussion_links: [asset_link], policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    get :show, params: { id: workflow }
    assert_response :success
    assert_select 'div.panel-heading', text: /Discussion Channel/, count: 1
    assert_select 'div.discussion-link', count:1 do
      assert_select 'a[href=?]',asset_link.url,text:'discuss-label'
    end
  end

  test 'should update workflow with new discussion link' do
    person = Factory(:person)
    workflow = Factory(:workflow, contributor: person)
    login_as(person)
    assert_nil workflow.discussion_links.first
    assert_difference('AssetLink.discussion.count') do
      assert_difference('ActivityLog.count') do
        put :update, params: { id: workflow.id, workflow: { discussion_links_attributes:[{url: "http://www.slack.com/", label:'our slack'}] } }
      end
    end
    assert_redirected_to workflow_path(workflow = assigns(:workflow))
    assert_equal 'http://www.slack.com/', workflow.discussion_links.first.url
    assert_equal 'our slack',workflow.discussion_links.first.label
  end

  test 'should update workflow with edited discussion link' do
    person = Factory(:person)
    workflow = Factory(:workflow, contributor: person, discussion_links:[Factory(:discussion_link)])
    login_as(person)
    assert_equal 1,workflow.discussion_links.count
    assert_no_difference('AssetLink.discussion.count') do
      assert_difference('ActivityLog.count') do
        put :update, params: { id: workflow.id, workflow: { discussion_links_attributes:[{id:workflow.discussion_links.first.id, url: "http://www.wibble.com/"}] } }
      end
    end
    workflow = assigns(:workflow)
    assert_redirected_to workflow_path(workflow)
    assert_equal 1,workflow.discussion_links.count
    assert_equal 'http://www.wibble.com/', workflow.discussion_links.first.url
  end

  test 'should destroy related assetlink when the discussion link is removed ' do
    person = Factory(:person)
    login_as(person)
    asset_link = Factory(:discussion_link)
    workflow = Factory(:workflow, discussion_links: [asset_link], policy: Factory(:public_policy, access_type: Policy::VISIBLE), contributor: person)
    refute_empty workflow.discussion_links
    assert_difference('AssetLink.discussion.count', -1) do
      put :update, params: { id: workflow.id, workflow: { discussion_links_attributes:[{id:asset_link.id, _destroy:'1'}] } }
    end
    assert_redirected_to workflow_path(workflow = assigns(:workflow))
    assert_empty workflow.discussion_links
  end

  test 'should be able to handle remote files when creating RO-Crate' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/file with spaces in name.txt", 'https://raw.githubusercontent.com/bob/workflow/master/workflow.txt'
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'https://raw.githubusercontent.com/bob/workflow/master/diagram.png'
    mock_remote_file "#{Rails.root}/test/fixtures/files/workflows/rp2-to-rp2path-packed.cwl", 'https://raw.githubusercontent.com/bob/workflow/master/abstract.cwl'

    cwl = Factory(:cwl_workflow_class)
    person = Factory(:person)
    login_as(person)
    assert_difference('ContentBlob.count') do
      post :create_ro_crate, params: {
          ro_crate: {
              workflow: { data_url: 'https://github.com/bob/workflow/blob/master/workflow.txt' },
                          diagram: { data_url: 'https://github.com/bob/workflow/blob/master/diagram.png' },
              abstract_cwl: { data_url: 'https://github.com/bob/workflow/blob/master/abstract.cwl' }
          },
          workflow_class_id: cwl.id
      }
    end
    assert_response :success
    assert wf = assigns(:workflow)
    workflow_crate = ROCrate::WorkflowCrateReader.read_zip(wf.content_blob.path)
    crate_workflow = workflow_crate.main_workflow
    assert crate_workflow
    assert_equal 'workflow.txt', crate_workflow.id
  end

  test 'create new version of a workflow' do
    person = Factory(:person)
    login_as(person)
    workflow = Factory(:workflow, contributor: person)
    blob = Factory(:nf_core_ro_crate)
    session[:uploaded_content_blob_id] = blob.id
    workflow_params =  { title: 'workflow', project_ids: [person.projects.first.id] }
    assert_equal 1, workflow.version
    old_blob = workflow.content_blob

    assert_no_difference('ContentBlob.count') do
      assert_difference('Workflow::Version.count') do
        post :create_version_metadata, params: { id: workflow.id, workflow: workflow_params, content_blob_id: blob.id.to_s }
      end
    end

    workflow = assigns(:workflow)
    assert_equal 2, workflow.version
    assert_equal old_blob, workflow.versions.first.content_blob
    assert_equal blob, workflow.versions.last.content_blob
  end

  test 'should be able to handle remote files in existing RO-Crate' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/file with spaces in name.txt", 'https://raw.githubusercontent.com/bob/workflow/master/workflow.txt'
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'https://raw.githubusercontent.com/bob/workflow/master/diagram.png'
    mock_remote_file "#{Rails.root}/test/fixtures/files/workflows/rp2-to-rp2path-packed.cwl", 'https://raw.githubusercontent.com/bob/workflow/master/abstract.cwl'

    galaxy = Factory(:galaxy_workflow_class)
    blob = Factory(:fully_remote_ro_crate)
    session[:uploaded_content_blob_id] = blob.id.to_s
    post :metadata_extraction_ajax, params: { content_blob_id: blob.id.to_s, format: 'js', workflow_class_id: galaxy.id }
    assert_response :success
    assert_equal 12, session[:metadata][:internals][:inputs].length
  end

  test 'filter by test status' do
    w1, w2, w3 = nil
    disable_authorization_checks do
      w1 = Factory(:public_workflow)
      w1.save_as_new_version
      w1.update_test_status(:all_failing, 1)
      w1.update_test_status(:all_passing, 2)
      w2 = Factory(:public_workflow)
      w2.update_test_status(:all_failing)
      w3 = Factory(:public_workflow)
      w3.update_test_status(:some_passing)
    end

    get :index, params: { filter: { tests: Workflow::TEST_STATUS_INV[:all_passing] } }
    assert_response :success
    assert_includes assigns(:workflows), w1

    get :index, params: { filter: { tests: Workflow::TEST_STATUS_INV[:all_failing] } }
    assert_response :success
    assert_includes assigns(:workflows), w2

    get :index, params: { filter: { tests: Workflow::TEST_STATUS_INV[:some_passing] } }
    assert_response :success
    assert_includes assigns(:workflows), w3
  end

  test 'should update workflow class ' do
    g = Factory(:galaxy_workflow_class)
    user = Factory(:user)
    workflow = Factory(:cwl_workflow, contributor: user.person)
    login_as(user)
    assert workflow.can_manage?

    assert_equal 'Common Workflow Language', workflow.workflow_class_title

    put :update, params: { id: workflow.id, workflow: { workflow_class_id: g.id } }

    assert_equal 'Galaxy', assigns(:workflow).workflow_class_title
    assert_equal g.id, assigns(:workflow).workflow_class_id
  end

  test '404 response code for show and ro-crate if workflow not found' do
    id = 999
    assert_nil Workflow.find_by_id(id)

    get :show, params: {id: id}
    assert_response :not_found

    get :ro_crate, params: {id: id}
    assert_response :not_found
  end

  test 'json response code for missing version' do
    user = Factory(:user)
    workflow = Factory(:cwl_workflow, contributor: user.person)
    login_as(user)

    version = 999
    assert_nil workflow.find_version(999)

    get :show, params: {id: workflow.id, version: version}, format: :json
    assert_response :not_found

    get :ro_crate, params: {id: workflow.id, version: version}, format: :json
    assert_response :not_found

    workflow = Factory(:cwl_workflow, contributor: Factory(:person))
    refute workflow.can_view?

    get :show, params: {id: workflow.id, version: version}, format: :json
    assert_response :forbidden

    get :ro_crate, params: {id: workflow.id, version: version}, format: :json
    assert_response :forbidden

  end

  test 'should update workflow edam annotations ' do
    Factory(:edam_topics_controlled_vocab)
    Factory(:edam_operations_controlled_vocab)

    user = Factory(:user)
    workflow = Factory(:cwl_workflow, contributor: user.person)
    login_as(user)
    assert workflow.can_manage?

    assert_equal 'Common Workflow Language', workflow.workflow_class_title

    put :update, params: { id: workflow.id, workflow: { edam_topics: 'Chemistry, Sample collections',edam_operations:'Clustering, Expression correlation analysis' } }

    assert_equal ['http://edamontology.org/topic_3314','http://edamontology.org/topic_3277'], assigns(:workflow).edam_topics
    assert_equal ['http://edamontology.org/operation_3432','http://edamontology.org/operation_3463'], assigns(:workflow).edam_operations

  end

  test 'show edam annotations if set' do
    Factory(:edam_topics_controlled_vocab)
    Factory(:edam_operations_controlled_vocab)

    user = Factory(:user)
    workflow = Factory(:cwl_workflow, contributor: user.person)
    login_as(user)

    get :show, params: {id: workflow.id}
    assert_response :success
    assert_select 'div.panel div.panel-heading',text:/EDAM Properties/i, count:0

    workflow.edam_topics = "Chemistry"
    workflow.save!

    assert workflow.edam_annotations?

    get :show, params: {id: workflow.id}
    assert_response :success

    assert_select 'div.panel div.panel-heading',text:/EDAM Properties/i, count:1
    assert_select 'div.panel div.panel-body div strong',text:/Topics/, count:1
    assert_select 'div.panel div.panel-body a[href=?]','https://edamontology.github.io/edam-browser/#topic_3314',text:/Chemistry/, count:1
  end

  test 'should create with presentation and document links' do
    person = Factory(:person)
    presentation = Factory(:presentation, contributor: person)
    document = Factory(:document, contributor:person)
    login_as(person)
    blob = Factory(:content_blob)
    session[:uploaded_content_blob_id] = blob.id
    workflow =  {title: 'workflow', project_ids: [person.projects.first.id], presentation_ids:[presentation.id], document_ids:[document.id]}

    assert_difference('Workflow.count') do
      post :create_metadata, params: {workflow: workflow, content_blob_id: blob.id.to_s, policy_attributes: { access_type: Policy::VISIBLE }}
    end

    workflow = assigns(:workflow)

    assert_equal [presentation], workflow.presentations
    assert_equal [document], workflow.documents
  end

  test 'should update workflow with presentation and document link' do
    person = Factory(:person)
    workflow = Factory(:workflow, contributor: person)
    presentation = Factory(:presentation, contributor: person)
    document = Factory(:document, contributor:person)
    login_as(person)
    assert_empty workflow.presentations
    assert_empty workflow.documents

    assert_difference('ActivityLog.count') do
      put :update, params: { id: workflow.id, workflow: { presentation_ids: [presentation.id], document_ids:[document.id]} }
    end

    assert_redirected_to workflow_path(workflow = assigns(:workflow))
    assert_equal [presentation], workflow.presentations
    assert_equal [document], workflow.documents
  end

  test 'should create with data file links' do
    person = Factory(:person)
    presentation = Factory(:presentation, contributor: person)
    data_file = Factory(:data_file, contributor:person)
    login_as(person)
    blob = Factory(:content_blob)
    session[:uploaded_content_blob_id] = blob.id
    workflow =  {title: 'workflow', project_ids: [person.projects.first.id], data_file_ids:[data_file.id] }

    assert_difference('Workflow.count') do
      post :create_metadata, params: {workflow: workflow, content_blob_id: blob.id.to_s, policy_attributes: { access_type: Policy::VISIBLE }}
    end

    workflow = assigns(:workflow)

    assert_equal [data_file], workflow.data_files
  end

  test 'should update workflow with data file link' do
    person = Factory(:person)
    workflow = Factory(:workflow, contributor: person)
    data_file = Factory(:data_file, contributor:person)
    relationship = Factory(:test_data_workflow_data_file_relationship)
    login_as(person)
    assert_empty workflow.data_files

    assert_difference('ActivityLog.count') do
      assert_difference('WorkflowDataFile.count') do
        put :update, params: { id: workflow.id, workflow: {
          workflow_data_files_attributes: ['',{data_file_id: data_file.id, workflow_data_file_relationship_id:relationship.id}]
        } }
      end
    end

    assert_redirected_to workflow_path(workflow = assigns(:workflow))
    assert_equal [data_file], workflow.data_files
    assert_equal 1,workflow.workflow_data_files.count
    assert_equal [relationship.id], workflow.workflow_data_files.pluck(:workflow_data_file_relationship_id)

    # doesn't duplicate
    assert_difference('ActivityLog.count') do
      assert_no_difference('WorkflowDataFile.count') do
        put :update, params: { id: workflow.id, workflow: {
          workflow_data_files_attributes: ['',{data_file_id: data_file.id, workflow_data_file_relationship_id:relationship.id}]
        } }
      end
    end
    assert_redirected_to workflow_path(workflow = assigns(:workflow))
    assert_equal [data_file], workflow.data_files
    assert_equal 1,workflow.workflow_data_files.count
    assert_equal [relationship.id], workflow.workflow_data_files.pluck(:workflow_data_file_relationship_id)

    #removes
    assert_difference('ActivityLog.count') do
      assert_difference('WorkflowDataFile.count', -1) do
        put :update, params: { id: workflow.id, workflow: {
          workflow_data_files_attributes: ['']
        } }
      end
    end
    assert_redirected_to workflow_path(workflow = assigns(:workflow))
    assert_equal [], workflow.data_files
    assert_equal 0,workflow.workflow_data_files.count
    assert_equal [], workflow.workflow_data_files.pluck(:workflow_data_file_relationship_id)
  end

  test 'presentation workflows through nested routing' do
    assert_routing 'presentations/2/workflows', controller: 'workflows', action: 'index', presentation_id: '2'
    presentation = Factory(:presentation, contributor: User.current_user.person)
    workflow = Factory(:workflow, policy: Factory(:public_policy), presentations:[presentation], contributor:User.current_user.person)
    workflow2 = Factory(:workflow, policy: Factory(:public_policy), contributor:User.current_user.person)

    get :index, params: { presentation_id: presentation.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', workflow_path(workflow), text: workflow.title
      assert_select 'a[href=?]', workflow_path(workflow2), text: workflow2.title, count: 0
    end
  end

  test 'document workflows through nested routing' do
    assert_routing 'documents/2/workflows', controller: 'workflows', action: 'index', document_id: '2'
    document = Factory(:document, contributor: User.current_user.person)
    workflow = Factory(:workflow, policy: Factory(:public_policy), documents:[document], contributor:User.current_user.person)
    workflow2 = Factory(:workflow, policy: Factory(:public_policy), contributor:User.current_user.person)

    get :index, params: { document_id: document.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', workflow_path(workflow), text: workflow.title
      assert_select 'a[href=?]', workflow_path(workflow2), text: workflow2.title, count: 0
    end
  end

  test 'data_file workflows through nested routing' do
    assert_routing 'data_files/2/workflows', controller: 'workflows', action: 'index', data_file_id: '2'
    data_file = Factory(:data_file, contributor: User.current_user.person)
    workflow = Factory(:workflow, policy: Factory(:public_policy), data_files:[data_file], contributor: User.current_user.person)
    workflow2 = Factory(:workflow, policy: Factory(:public_policy), contributor: User.current_user.person)

    get :index, params: { data_file_id: data_file.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', workflow_path(workflow), text: workflow.title
      assert_select 'a[href=?]', workflow_path(workflow2), text: workflow2.title, count: 0
    end
  end

  def edit_max_object(workflow)
    add_tags_to_test_object(workflow)
    add_creator_to_test_object(workflow)
  end
end
