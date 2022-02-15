require 'test_helper'
require 'minitest/mock'

class SopsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases
  include SharingFormTestHelper
  include RdfTestCases
  include HtmlHelper
  include GeneralAuthorizationTestCases

  def setup
    @user = users(:quentin)
    @project = @user.person.projects.first
    login_as(@user)
  end

  def rest_api_test_object
    @object = sops(:downloadable_sop)
  end

  test 'creators do not show in list item' do
    p1 = Factory :person
    p2 = Factory :person
    sop = Factory(:sop, title: 'ZZZZZ', creators: [p2], contributor: p1, policy: Factory(:public_policy, access_type: Policy::VISIBLE))

    get :index, params: { page: 'Z' }

    # check the test is behaving as expected:
    assert_equal p1, sop.contributor
    assert sop.creators.include?(p2)
    assert_select '.list_item_title a[href=?]', sop_path(sop), 'ZZZZZ', 'the data file for this test should appear as a list item'

    # check for avatars
    assert_select '.list_item_avatar' do
      assert_select 'a[href=?]', person_path(p2) do
        assert_select 'img'
      end
      assert_select 'a[href=?]', person_path(p1), count: 0
    end
  end

  test 'fail gracefullly when trying to access a missing sop' do
    get :show, params: { id: 99_999 }
    assert_response :not_found
  end

  test 'should not create sop with file url' do
    file_path = File.expand_path(__FILE__) # use the current file
    file_url = 'file://' + file_path
    uri = URI.parse(file_url)

    assert_no_difference('Sop.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, params: { sop: { title: 'Test' }, content_blobs: [{ data_url: uri.to_s }], policy_attributes: valid_sharing }
      end
    end
    assert_not_nil flash[:error]
  end

  def test_title
    get :index
    assert_select 'title', text: I18n.t('sop').pluralize, count: 1
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:sops)
  end

  test "shouldn't show hidden items in index" do
    login_as(:aaron)
    get :index, params: { page: 'all' }
    assert_response :success
    assert_equal assigns(:sops).sort_by(&:id), assigns(:sops).authorized_for('view', users(:aaron)).sort_by(&:id), "sops haven't been authorized properly"
  end

  test 'should not show private sop to logged out user' do
    sop = Factory :sop
    logout
    get :show, params: { id: sop }
    assert_response :forbidden
  end

  test 'should not show private sop to another user' do
    sop = Factory :sop, contributor: Factory(:person)
    get :show, params: { id: sop }
    assert_response :forbidden
  end

  test 'should get new' do
    get :new
    assert_response :success
    assert_select 'h1', text: "New #{I18n.t('sop')}"
  end

  test 'should correctly handle bad data url' do
    stub_request(:any, 'http://sdfsdfds.com/sdf.png').to_raise(SocketError)
    sop = { title: 'Test', project_ids: [@project.id] }
    blob = { data_url: 'http://sdfsdfds.com/sdf.png' }
    assert_no_difference('Sop.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, params: { sop: sop, content_blobs: [blob], policy_attributes: valid_sharing }
      end
    end
    assert_not_nil flash.now[:error]

    # not even a valid url
    sop = { title: 'Test', project_ids: [@project.id] }
    blob = { data_url: 's  df::sd:dfds.com/sdf.png' }
    assert_no_difference('Sop.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, params: { sop: sop, content_blobs: [blob], policy_attributes: valid_sharing }
      end
    end
    assert_not_nil flash.now[:error]
  end

  test 'should not create invalid sop' do
    sop = { title: 'Test', project_ids: [@project.id] }
    assert_no_difference('Sop.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, params: { sop: sop, content_blobs: [{}], policy_attributes: valid_sharing }
      end
    end
    assert_not_nil flash.now[:error]
  end

  test 'associates assay' do
    login_as(:owner_of_my_first_sop) # can edit assay_can_edit_by_my_first_sop_owner
    s = Factory(:sop, contributor:User.current_user.person)
    original_assay = Factory(:assay, contributor:User.current_user.person, assay_assets: [Factory(:assay_asset, asset:s)])

    assert_includes original_assay.sops, s

    new_assay = Factory(:assay, contributor:User.current_user.person)

    refute_includes new_assay.sops, s

    put :update, params: { id: s.id, sop: { title: s.title, assay_assets_attributes: [{ assay_id: new_assay.id }] } }

    assert_redirected_to sop_path(s)

    s.reload
    original_assay.reload
    new_assay.reload

    refute_includes original_assay.sops, s
    assert_includes new_assay.sops, s
  end

  test 'should create sop' do
    sop, blob = valid_sop
    assay = Factory(:assay, contributor: User.current_user.person)
    assert_difference('Sop.count') do
      assert_difference('ContentBlob.count') do
        post :create, params: { sop: sop.merge(assay_assets_attributes: [{ assay_id: assay.id }]), content_blobs: [blob], policy_attributes: valid_sharing }
      end
    end

    assert_redirected_to sop_path(assigns(:sop))

    assert assigns(:sop).content_blob.url.blank?
    assert !assigns(:sop).content_blob.data_io_object.read.nil?
    assert assigns(:sop).content_blob.file_exists?
    assert_equal 'file_picture.png', assigns(:sop).content_blob.original_filename
    assay.reload
    assert_includes assay.sops, assigns(:sop)
  end

  test 'should create sop with url' do
    sop, blob = valid_sop_with_url
    assert_difference('Sop.count') do
      assert_difference('ContentBlob.count') do
        post :create, params: { sop: sop, content_blobs: [blob], policy_attributes: valid_sharing }
      end
    end
    assert_redirected_to sop_path(assigns(:sop))
    assert_equal users(:quentin).person, assigns(:sop).contributor
    assert !assigns(:sop).content_blob.url.blank?
    assert assigns(:sop).content_blob.data_io_object.nil?
    assert !assigns(:sop).content_blob.file_exists?
    assert_equal 'sysmo-db-logo-grad2.png', assigns(:sop).content_blob.original_filename
    assert_equal 'image/png', assigns(:sop).content_blob.content_type
  end

  test 'should create sop and store with url and store flag' do
    sop_details, blob = valid_sop_with_url
    blob[:make_local_copy] = '1'
    assert_difference('Sop.count') do
      assert_difference('ContentBlob.count') do
        post :create, params: { sop: sop_details, content_blobs: [blob], policy_attributes: valid_sharing }
      end
    end
    assert_redirected_to sop_path(assigns(:sop))
    assert_equal users(:quentin).person, assigns(:sop).contributor
    assert !assigns(:sop).content_blob.url.blank?
    assert_equal 'sysmo-db-logo-grad2.png', assigns(:sop).content_blob.original_filename
    assert_equal 'image/png', assigns(:sop).content_blob.content_type
  end

  test 'should show sop' do
    login_as(:owner_of_my_first_sop)
    s = Factory :pdf_sop, policy: Factory(:public_policy)

    assert_difference('ActivityLog.count') do
      get :show, params: { id: s.id }
    end

    assert_response :success

    assert_select 'div.box_about_actor' do
      assert_select 'p > b', text: /Filename:/
      assert_select 'p', text: /a_pdf_file\.pdf/
      assert_select 'p > b', text: /Format:/
      assert_select 'p', text: /PDF document/
      assert_select 'p > b', text: /Size:/
      assert_select 'p', text: /8.62 KB/
    end

    al = ActivityLog.last
    assert_equal 'show', al.action
    assert_equal User.current_user, al.culprit
    assert_equal s, al.activity_loggable
    assert_equal 'Rails Testing', al.user_agent
  end

  test 'should get edit' do
    login_as(:owner_of_my_first_sop)
    get :edit, params: { id: sops(:my_first_sop) }
    assert_response :success
    assert_select 'h1', text: /Editing #{I18n.t('sop')}/
  end

  test 'publications excluded in form for sops' do
    login_as(:owner_of_my_first_sop)
    get :edit, params: { id: sops(:my_first_sop) }
    assert_response :success
    assert_select 'div#add_publications_form', false

    get :new
    assert_response :success
    assert_select 'div#add_publications_form', false
  end

  test 'should update sop' do
    login_as(person = Factory(:person))
    sop = Factory(:sop, contributor: person)
    assert_empty sop.policy.permissions
    put :update, params: { id: sop.id, sop: { title: 'Test2' }, policy_attributes: { access_type: Policy::ACCESSIBLE, permissions_attributes: project_permissions(sop.projects, Policy::ACCESSIBLE) } }
    sop = assigns(:sop)
    assert_redirected_to sop_path(sop)
    assert_equal 'Test2', sop.title
    assert_equal Policy::ACCESSIBLE, sop.policy.access_type
    assert_equal 1, sop.policy.permissions.count
  end

  test 'should destroy sop' do
    login_as(:owner_of_my_first_sop)
    assert_difference('ActivityLog.count') do
      assert_difference('Sop.count', -1) do
        assert_no_difference('ContentBlob.count') do
          delete :destroy, params: { id: sops(:my_first_sop) }

          assert flash[:notice].include?('deleted')
        end
      end
    end

    assert_redirected_to sops_path
  end

  test 'should not be able to edit exp conditions for downloadable only sop' do
    s = sops(:downloadable_sop)

    get :show, params: { id: s }
    assert_select 'a', text: /Edit experimental conditions/, count: 0
  end


  test 'should show request contact button' do
    s = Factory(:sop, contributor: Factory(:person), policy: Factory(:public_policy))
    get :show, params: { id: s }
    assert_response :success
    assert_select 'a.disabled', text: /Request Contact/, count: 0
    assert_select 'a#request_contact_button', text: /Request Contact/, count: 1
  end

  test 'should not show request contact button when there is no contributor or creator' do
    get :show, params: { id: sops(:sop_with_no_contributor), policy: Factory(:public_policy)}
    assert_response :success
    assert_select 'a.disabled', text: /Request Contact/, count: 0
    assert_select 'a#request_contact_button', text: /Request Contact/, count: 0
  end

  test 'should not show request contact button when the current user is the only contributor or creator' do
    s = Factory(:sop, contributor: @user.person)
    get :show, params: { id: s }
    assert_response :success
    assert_select 'a.disabled', text: /Request Contact/, count: 0
    assert_select 'a#request_contact_button', text: /Request Contact/, count: 0
  end

  test 'request contact' do
    s = Factory(:sop, contributor: Factory(:person), policy: Factory(:public_policy))
    assert_enqueued_emails(1) do
      assert_difference('ContactRequestMessageLog.count') do
        post :request_contact, format: :js, params: { id:s, details:'blah blah' }
      end
    end

    log = ContactRequestMessageLog.last
    assert_equal s, log.subject
    assert_equal User.current_user.person,log.sender
    assert log.contact_request?

  end

  def test_should_show_version
    s = Factory(:sop, contributor: @user.person)

    # !!!description cannot be changed in new version but revision comments and file name,etc

    # create new version
    post :create_version, params: { id: s, sop: { title: s.title }, content_blobs: [{ data: fixture_file_upload('files/little_file_v2.txt', 'text/plain') }] }
    assert_redirected_to sop_path(assigns(:sop))

    s = Sop.find(s.id)
    assert_equal 2, s.versions.size
    assert_equal 2, s.version
    assert_equal 1, s.versions[0].version
    assert_equal 2, s.versions[1].version

    get :show, params: { id: s }
    assert_select 'p', text: /little_file_v2.txt/, count: 1
    assert_select 'p', text: /sop.pdf/, count: 0

    get :show, params: { id: s, version: '2' }
    assert_select 'p', text: /little_file_v2.txt/, count: 1
    assert_select 'p', text: /sop.pdf/, count: 0

    get :show, params: { id: s, version: '1' }
    assert_select 'p', text: /little_file_v2.txt/, count: 0
    assert_select 'p', text: /sop.pdf/, count: 1
  end

  test 'should download SOP from standard route' do
    sop = Factory :doc_sop, policy: Factory(:public_policy)
    login_as(sop.contributor.user)
    assert_difference('ActivityLog.count') do
      get :download, params: { id: sop.id }
    end
    assert_response :success
    al = ActivityLog.last
    assert_equal 'download', al.action
    assert_equal sop, al.activity_loggable
    assert_equal "attachment; filename=\"ms_word_test.doc\"", @response.header['Content-Disposition']
    assert_equal 'application/msword', @response.header['Content-Type']
    assert_equal '9216', @response.header['Content-Length']
  end

  def test_should_create_new_version
    s = Factory(:sop, contributor: @user.person)

    assert_difference('Sop::Version.count', 1) do
      post :create_version, params: { id: s, sop: { title: s.title }, content_blobs: [{ data: picture_file }], revision_comments: 'This is a new revision' }
    end

    assert_redirected_to sop_path(s)
    assert assigns(:sop)
    assert_not_nil flash[:notice]
    assert_nil flash[:error]

    s = Sop.find(s.id)
    assert_equal 2, s.versions.size
    assert_equal 2, s.version
    assert_equal 'file_picture.png', s.content_blob.original_filename
    assert_equal 'file_picture.png', s.versions[1].content_blob.original_filename
    assert_equal 'sop.pdf', s.versions[0].content_blob.original_filename
    assert_equal 'This is a new revision', s.versions[1].revision_comments
  end

  def test_should_not_create_new_version_for_downloadable_only_sop
    s = sops(:downloadable_sop)
    current_version = s.version
    current_version_count = s.versions.size

    assert s.can_download?
    refute s.can_edit?

    assert_no_difference('Sop::Version.count') do
      post :create_version, params: { id: s, data: fixture_file_upload('files/file_picture.png'), revision_comments: 'This is a new revision' }
    end

    assert_redirected_to sop_path(s)
    assert_not_nil flash[:error]

    s = Sop.find(s.id)
    assert_equal current_version_count, s.versions.size
    assert_equal current_version, s.version
  end

  def test_should_duplicate_conditions_for_new_version
    s = Factory :sop, contributor: User.current_user.person
    condition1 = ExperimentalCondition.create(unit_id: units(:gram).id, measured_item_id: measured_items(:weight).id,
                                              start_value: 1, sop_id: s.id, sop_version: s.version)
    condition1.save!
    s.reload
    assert_equal 1, s.experimental_conditions.count
    assert_difference('Sop::Version.count', 1) do
      assert_difference('ExperimentalCondition.count', 1) do
        post :create_version, params: { id: s, sop: { title: s.title }, content_blobs: [{ data: picture_file }], revision_comments: 'This is a new revision' } # v2
      end
    end

    assert_equal 1, s.find_version(1).experimental_conditions.count
    assert_equal 1, s.find_version(2).experimental_conditions.count
    assert_not_equal s.find_version(1).experimental_conditions, s.find_version(2).experimental_conditions
  end

  def test_adding_new_conditions_to_different_versions
    s = Factory(:sop, contributor:User.current_user.person)
    assert s.can_edit?
    condition1 = ExperimentalCondition.create(unit_id: units(:gram).id, measured_item: measured_items(:weight),
                                              start_value: 1, sop_id: s.id, sop_version: s.version)
    assert_difference('Sop::Version.count', 1) do
      assert_difference('ExperimentalCondition.count', 1) do
        post :create_version, params: { id: s, sop: { title: s.title }, content_blobs: [{ data: picture_file }], revision_comments: 'This is a new revision' } # v2
      end
    end

    s.find_version(2).experimental_conditions.each(&:destroy)
    assert_equal condition1, s.find_version(1).experimental_conditions.first
    assert_equal 0, s.find_version(2).experimental_conditions.count

    condition2 = ExperimentalCondition.create(unit_id: units(:gram).id, measured_item: measured_items(:weight),
                                              start_value: 2, sop_id: s.id, sop_version: 2)

    assert_not_equal 0, s.find_version(2).experimental_conditions.count
    assert_equal condition2, s.find_version(2).experimental_conditions.first
    assert_not_equal condition2, s.find_version(1).experimental_conditions.first
    assert_equal condition1, s.find_version(1).experimental_conditions.first
  end

  def test_should_add_nofollow_to_links_in_show_page
    get :show, params: { id: sops(:sop_with_links_in_description) }
    assert_select 'div#description' do
      assert_select 'a[rel="nofollow"]'
    end
  end

  def test_can_display_sop_with_no_contributor
    get :show, params: { id: sops(:sop_with_no_contributor) }
    assert_response :success
  end


  def test_can_show_edit_for_sop_with_no_contributor
    get :edit, params: { id: sops(:sop_with_no_contributor) }
    assert_response :success
  end

  def test_editing_doesnt_change_contributor
    login_as(:model_owner) # this user is a member of sysmo, and can edit this sop
    sop = sops(:sop_with_no_contributor)
    put :update, params: { id: sop, sop: { title: 'blah blah blah' }, policy_attributes: valid_sharing }
    updated_sop = assigns(:sop)
    assert_redirected_to sop_path(updated_sop)
    assert_equal 'blah blah blah', updated_sop.title, 'Title should have been updated'
    assert_nil updated_sop.contributor, 'contributor should still be nil'
  end

  test 'filtering by assay' do
    assay = assays(:metabolomics_assay)
    get :index, params: { filter: { assay: assay.id } }
    assert_response :success
  end

  test 'filtering by study' do
    study = studies(:metabolomics_study)
    get :index, params: { filter: { study: study.id } }
    assert_response :success
  end

  test 'filtering by investigation' do
    inv = investigations(:metabolomics_investigation)
    get :index, params: { filter: { investigation: inv.id } }
    assert_response :success
  end

  test 'filtering by project' do
    project = projects(:sysmo_project)
    get :index, params: { filter: { project: project.id } }
    assert_response :success
  end

  test 'filtering by person' do
    login_as(:owner_of_my_first_sop)
    person = people(:person_for_owner_of_my_first_sop)
    p = projects(:sysmo_project)
    get :index, params: { filter: { contributor: person.id }, page: 'all' }
    assert_response :success
    sop  = sops(:downloadable_sop)
    sop2 = sops(:sop_with_fully_public_policy)
    assert_select 'div.list_items_container' do
      assert_select 'a', text: sop.title, count: 1
      assert_select 'a', text: sop2.title, count: 0
    end
  end

  test 'should not be able to update sharing without manage rights' do
    sop = Factory(:sop)
    sop.policy.permissions << Factory(:permission, contributor: @user.person, access_type: Policy::EDITING)

    assert sop.can_edit?(@user), 'sop should be editable but not manageable for this test'
    refute sop.can_manage?(@user), 'sop should be editable but not manageable for this test'
    assert_equal Policy::NO_ACCESS, sop.policy.access_type
    put :update, params: { id: sop, sop: { title: 'new title' }, policy_attributes: { access_type: Policy::EDITING } }

    assert_redirected_to sop_path(sop)
    sop.reload

    assert_equal 'new title', sop.title
    assert_equal Policy::NO_ACCESS, sop.policy.access_type, 'policy should not have been updated'
  end

  test 'owner should be able to update sharing' do
    user = Factory(:user)
    login_as(user)

    sop = Factory :sop, contributor: User.current_user.person, policy: Factory(:policy, access_type: Policy::EDITING)

    put :update, params: { id: sop, sop: { title: 'new title' }, policy_attributes: { access_type: Policy::NO_ACCESS } }
    assert_redirected_to sop_path(sop)
    sop.reload

    assert_equal 'new title', sop.title
    assert_equal Policy::NO_ACCESS, sop.policy.access_type, 'policy should have been updated'
  end

  test 'do publish' do
    login_as(:owner_of_my_first_sop)
    sop = sops(:sop_with_project_without_gatekeeper)
    assert sop.can_manage?, 'The sop must be manageable for this test to succeed'
    post :publish, params: { id: sop }
    assert_response :redirect
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
  end

  test 'do not isa_publish if not can_manage?' do
    sop = sops(:sop_with_project_without_gatekeeper)
    assert !sop.can_manage?, 'The sop must not be manageable for this test to succeed'
    post :publish, params: { id: sop }
    assert_redirected_to :root
    assert_not_nil flash[:error]
    assert_nil flash[:notice]
  end

  test 'the gatekeeper should have right to view the item when an item is requested to be published' do
    gatekeeper = Factory(:asset_gatekeeper)
    @user.person.add_to_project_and_institution(gatekeeper.projects.first, Factory(:institution))
    post :create, params: { sop: { title: 'text sop', project_ids: gatekeeper.projects.collect(&:id) }, content_blobs: [{ data: picture_file }], policy_attributes: { access_type: Policy::NO_ACCESS } }
    sop = assigns(:sop)

    login_as(gatekeeper)
    refute sop.can_view?

    login_as(sop.contributor)
    post :publish, params: { id: sop }
    sop = assigns(:sop)

    login_as(gatekeeper)
    assert sop.can_view?
  end

  test "should show 'None' for other contributors if no contributors" do
    get :index
    assert_response :success
    no_other_creator_sops = assigns(:sops).select { |s| s.creators.empty? && s.other_creators.blank? }
    assert_select 'p.list_item_attribute', text: /#{I18n.t('creator').pluralize.capitalize}: None/, count: no_other_creator_sops.count
  end

  test 'should set the policy to projects_policy if the item is requested to be published, when creating new sop' do
    as_not_virtualliver do
      gatekeeper = Factory(:asset_gatekeeper)
      @user.person.add_to_project_and_institution(gatekeeper.projects.first, Factory(:institution))
      post :create, params: { sop: { title: 'test', project_ids: gatekeeper.projects.collect(&:id) }, content_blobs: [{ data: picture_file }], policy_attributes: { access_type: Policy::VISIBLE } }
      sop = assigns(:sop)
      assert_redirected_to (sop)
      policy = sop.policy
      assert_equal Policy::NO_ACCESS, policy.access_type
      assert_equal 1, policy.permissions.count
      assert_equal gatekeeper.projects.first, policy.permissions.first.contributor
      assert_equal Policy::ACCESSIBLE, policy.permissions.first.access_type
    end
  end

  test 'should not change the policy if the item is requested to be published, when managing sop' do
    gatekeeper = Factory(:asset_gatekeeper)
    policy = Factory(:policy, access_type: Policy::NO_ACCESS, permissions: [Factory(:permission)])
    sop = Factory(:sop, project_ids: gatekeeper.projects.collect(&:id), policy: policy)
    login_as(sop.contributor)
    assert sop.can_manage?
    put :update, params: { id: sop.id, sop: { title: sop.title }, policy_attributes: { access_type: Policy::VISIBLE } }
    sop = assigns(:sop)
    assert_redirected_to(sop)
    updated_policy = sop.policy
    assert_equal policy, updated_policy
    assert_equal policy.permissions, updated_policy.permissions
  end

  test 'should be able to view pdf content' do
    sop = Factory(:sop, policy: Factory(:all_sysmo_downloadable_policy))
    assert sop.content_blob.is_content_viewable?
    get :show, params: { id: sop.id }
    assert_response :success
    assert_select 'a', text: /View content/, count: 1
    assert_select 'a.disabled', text: /View content/, count: 0
  end

  test 'should be able to view ms/open office word content' do
    Seek::Config.stub(:soffice_available?, true) do
      ms_word_sop = Factory(:doc_sop, policy: Factory(:all_sysmo_downloadable_policy))
      content_blob = ms_word_sop.content_blob
      pdf_filepath = content_blob.filepath('pdf')
      FileUtils.rm pdf_filepath if File.exist?(pdf_filepath)
      assert content_blob.is_content_viewable?
      get :show, params: { id: ms_word_sop.id }
      assert_response :success
      assert_select 'a', text: /View content/, count: 1
      assert_select 'a.disabled', text: /View content/, count: 0

      openoffice_word_sop = Factory(:odt_sop, policy: Factory(:all_sysmo_downloadable_policy))
      assert openoffice_word_sop.content_blob.is_content_viewable?
      get :show, params: { id: openoffice_word_sop.id }
      assert_response :success
      assert_select 'a', text: /View content/, count: 1
      assert_select 'a.disabled', text: /View content/, count: 0
    end
  end

  test 'should disappear view content button for the document needing pdf conversion, when pdf_conversion_enabled is false' do
    tmp = Seek::Config.pdf_conversion_enabled
    Seek::Config.pdf_conversion_enabled = false

    ms_word_sop = Factory(:doc_sop, policy: Factory(:all_sysmo_downloadable_policy))
    content_blob = ms_word_sop.content_blob
    pdf_filepath = content_blob.filepath('pdf')
    FileUtils.rm pdf_filepath if File.exist?(pdf_filepath)
    assert !content_blob.is_content_viewable?
    get :show, params: { id: ms_word_sop.id }
    assert_response :success
    assert_select 'a.disabled', text: /View content/, count: 1

    Seek::Config.pdf_conversion_enabled = tmp
  end

  test 'duplicated logs are NOT created by uploading new version' do
    sop, blob = valid_sop
    assert_difference('ActivityLog.count', 1) do
      assert_difference('Sop.count', 1) do
        post :create, params: { sop: sop, content_blobs: [blob], policy_attributes: valid_sharing }
      end
    end
    al1 = ActivityLog.last
    s = assigns(:sop)
    assert_difference('ActivityLog.count', 1) do
      assert_difference('Sop::Version.count', 1) do
        post :create_version, params: { id: s, sop: { title: s.title }, content_blobs: [{ data: picture_file }], revision_comments: 'This is a new revision' }
      end
    end
    al2 = ActivityLog.last
    assert_equal al1.activity_loggable, al2.activity_loggable
    assert_equal al1.culprit, al2.culprit
    assert_equal 'create', al1.action
    assert_equal 'update', al2.action
  end

  test 'should not create duplication sop_versions_projects when uploading new version' do
    sop = Factory(:sop)
    login_as(sop.contributor)
    post :create_version, params: { id: sop, sop: { title: sop.title }, content_blobs: [{ data: picture_file }], revision_comments: 'This is a new revision' }

    sop.reload
    assert_equal 2, sop.versions.count
    assert_equal 1, sop.latest_version.projects.count
  end

  test 'should not create duplication sop_versions_projects when uploading sop' do
    sop, blob = valid_sop
    post :create, params: { sop: sop, content_blobs: [blob], policy_attributes: valid_sharing }

    sop = assigns(:sop)
    assert_equal 1, sop.versions.count
    assert_equal 1, sop.latest_version.projects.count
  end

  test 'should destroy all versions related when destroying sop' do
    sop = Factory(:sop)
    assert_equal 1, sop.versions.count
    sop_version = sop.latest_version
    assert_equal 1, sop_version.projects.count
    project_sop_version = sop_version.projects.first

    login_as(sop.contributor)
    delete :destroy, params: { id: sop }
    assert_nil Sop::Version.find_by_id(sop_version.id)
    sql = "select * from projects_sop_versions where project_id = #{project_sop_version.id} and version_id = #{sop_version.id}"
    assert ActiveRecord::Base.connection.select_all(sql).empty?
  end

  test 'send publish approval request' do
    gatekeeper = Factory(:asset_gatekeeper)
    sop = Factory(:sop, project_ids: gatekeeper.projects.collect(&:id))

    # request publish
    login_as(sop.contributor)
    assert sop.can_publish?
    assert_enqueued_emails 1 do
      put :update, params: { sop: { title: sop.title }, id: sop.id, policy_attributes: { access_type: Policy::ACCESSIBLE } }
    end
  end

  test 'dont send publish approval request if can_publish' do
    gatekeeper = Factory(:asset_gatekeeper)
    sop = Factory(:sop, contributor: gatekeeper, project_ids: gatekeeper.projects.collect(&:id))

    # request publish
    login_as(sop.contributor)
    assert !sop.is_published?
    assert sop.can_publish?
    assert_no_enqueued_emails do
      put :update, params: { sop: { title: sop.title }, id: sop.id, policy_attributes: { access_type: Policy::ACCESSIBLE } }
    end
  end

  test 'dont send publish approval request again if it was already sent by this person' do
    gatekeeper = Factory(:asset_gatekeeper)
    sop = Factory(:sop, project_ids: gatekeeper.projects.collect(&:id))

    # request publish
    login_as(sop.contributor)
    assert sop.can_publish?
    # send the first time
    assert_enqueued_emails 1 do
      put :update, params: { sop: { title: sop.title }, id: sop.id, policy_attributes: { access_type: Policy::ACCESSIBLE } }
    end
    # dont send again
    assert_no_enqueued_emails do
      put :update, params: { sop: { title: sop.title }, id: sop.id, policy_attributes: { access_type: Policy::ACCESSIBLE } }
    end
  end

  test 'dont send publish approval request if item was already public' do
    gatekeeper = Factory(:asset_gatekeeper)
    sop = Factory(:sop, project_ids: gatekeeper.projects.collect(&:id), policy: Factory(:public_policy))
    login_as(sop.contributor)

    assert sop.can_view?(nil)

    assert_no_enqueued_emails do
      put :update, params: { sop: { title: sop.title }, id: sop.id, policy_attributes: { access_type: Policy::ACCESSIBLE } }
    end

    assert_empty ResourcePublishLog.requested_approval_assets_for(gatekeeper)
  end

  test 'dont send publish approval request if item is only being made visible' do
    gatekeeper = Factory(:asset_gatekeeper)
    sop = Factory(:sop, project_ids: gatekeeper.projects.collect(&:id), policy: Factory(:private_policy))
    login_as(sop.contributor)

    refute sop.can_view?(nil)

    assert_no_enqueued_emails do
      put :update, params: { sop: { title: sop.title }, id: sop.id, policy_attributes: { access_type: Policy::VISIBLE } }
    end

    assert_empty ResourcePublishLog.requested_approval_assets_for(gatekeeper)
  end

  test 'send publish approval request if elevating permissions from VISIBLE -> ACCESSIBLE' do
    gatekeeper = Factory(:asset_gatekeeper)
    sop = Factory(:sop, project_ids: gatekeeper.projects.collect(&:id), policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    login_as(sop.contributor)

    refute sop.is_published?
    assert sop.can_view?(nil)
    refute sop.can_download?(nil)

    assert_enqueued_emails 1 do
      put :update, params: { sop: { title: sop.title }, id: sop.id, policy_attributes: { access_type: Policy::ACCESSIBLE } }
    end

    refute sop.is_published?
    assert sop.can_view?(nil)
    refute sop.can_download?(nil)

    assert_includes ResourcePublishLog.requested_approval_assets_for(gatekeeper), sop
  end

  test 'should not loose permissions when managing a sop' do
    policy = Factory(:private_policy)
    a_person = Factory(:person)
    permission = Factory(:permission, contributor: a_person, access_type: Policy::MANAGING)
    policy.permissions = [permission]
    policy.save
    sop = Factory :sop, contributor: User.current_user.person, policy: policy
    assert sop.can_manage?

    put :update, params: { id: sop.id, sop: { title: sop.title }, policy_attributes: { access_type: Policy::NO_ACCESS,
                             permissions_attributes: { '1' => { contributor_type: 'Person',
                                                                contributor_id: a_person.id,
                                                                access_type: Policy::MANAGING } }
        } }

    assert_redirected_to sop
    assert_equal 1, sop.reload.policy.permissions.count
  end

  test 'should not lose project assignment when an asset is managed by a person from different project' do
    sop = Factory(:sop)
    sop.policy.permissions << Factory(:permission, contributor: User.current_user.person, access_type: Policy::MANAGING)
    assert sop.can_manage?
    assert_not_equal sop.projects.first, User.current_user.person.projects.first

    get :manage, params: { id: sop }
    assert_response :success

    selected = JSON.parse(select_node_contents('#project-selector-selected-json'))
    assert_equal selected.first['id'], sop.projects.first.id
  end

  test 'should show tags box according to config' do
    sop = Factory(:sop, policy: Factory(:public_policy))
    get :show, params: { id: sop.id }
    assert_response :success
    assert_select 'div#tags_box', count: 1
    with_config_value :tagging_enabled, false do
      get :show, params: { id: sop.id }
      assert_response :success
      assert_select 'div#tags_box', count: 0
    end
  end

  test 'title for index should be SOPs' do
    get :index
    assert_response :success
    assert_select 'h1', text: 'SOPs'
  end

  test 'should display null license text' do
    sop = Factory :sop, policy: Factory(:public_policy)

    get :show, params: { id: sop }

    assert_select '.panel .panel-body span#null_license', text: I18n.t('null_license')
  end

  test 'should display license' do
    sop = Factory :sop, license: 'CC-BY-4.0', policy: Factory(:public_policy)

    get :show, params: { id: sop }

    assert_select '.panel .panel-body a', text: 'Creative Commons Attribution 4.0'
  end

  test 'should display license for current version' do
    sop = Factory :sop, license: 'CC-BY-4.0', policy: Factory(:public_policy)
    sopv = Factory :sop_version_with_blob, sop: sop

    sop.update_attributes license: 'CC0-1.0'

    get :show, params: { id: sop, version: 1 }
    assert_response :success
    assert_select '.panel .panel-body a', text: 'Creative Commons Attribution 4.0'

    get :show, params: { id: sop, version: sopv.version }
    assert_response :success
    assert_select '.panel .panel-body a', text: 'CC0 1.0'
  end

  test 'should update license' do
    sop = Factory(:sop, contributor: @user.person, license: nil)

    assert_nil sop.license

    put :update, params: { id: sop, sop: { license: 'CC-BY-SA-4.0' } }

    assert_response :redirect

    get :show, params: { id: sop }
    assert_select '.panel .panel-body a', text: 'Creative Commons Attribution Share-Alike 4.0'
    assert_equal 'CC-BY-SA-4.0', assigns(:sop).license
  end

  test 'programme sops through nested routing' do
    assert_routing 'programmes/2/sops', { controller: 'sops', action: 'index', programme_id: '2' }
    programme = Factory(:programme)
    sop = Factory(:sop, projects: programme.projects, policy: Factory(:public_policy))
    sop2 = Factory(:sop, policy: Factory(:public_policy))

    get :index, params: { programme_id: programme.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', sop_path(sop), text: sop.title
      assert_select 'a[href=?]', sop_path(sop2), text: sop2.title, count: 0
    end
  end

  test 'permission popup setting set in sharing form' do
    sop = Factory :sop, contributor: User.current_user.person
    with_config_value :permissions_popup, Seek::Config::PERMISSION_POPUP_ON_CHANGE do
      get :manage, params: { id: sop }
    end
    assert_select '#preview-permission-link-script', text: /var permissionPopupSetting = "on_change"/, count: 1

    with_config_value :permissions_popup, Seek::Config::PERMISSION_POPUP_ALWAYS do
      get :manage, params: { id: sop }
    end
    assert_select '#preview-permission-link-script', text: /var permissionPopupSetting = "always"/, count: 1

    with_config_value :permissions_popup, Seek::Config::PERMISSION_POPUP_NEVER do
      get :manage, params: { id: sop }
    end
    assert_select '#preview-permission-link-script', text: /var permissionPopupSetting = "never"/, count: 1
  end

  test 'can get citation for sop with DOI' do
    doi_citation_mock
    sop = Factory(:sop, policy: Factory(:public_policy))

    login_as(sop.contributor)

    get :show, params: { id: sop }
    assert_response :success
    assert_select '#citation', text: /Bacall, F/, count:0

    sop.latest_version.update_attribute(:doi,'doi:10.1.1.1/xxx')

    get :show, params: { id: sop }
    assert_response :success
    assert_select '#citation', text: /Bacall, F/, count:1
  end

  def edit_max_object(sop)
    add_tags_to_test_object(sop)
    add_creator_to_test_object(sop)
  end

  test 'shows how to get doi for private sop' do
    sop = Factory(:sop, policy: Factory(:private_policy))

    login_as(sop.contributor)

    get :show, params: { id: sop }

    assert_response :success
    assert_select '#citation-instructions a[href=?]', mint_doi_confirm_sop_path(sop, version: sop.version), count: 0
    assert_select '#citation-instructions a[href=?]', check_related_items_sop_path(sop)
  end

  test 'shows how to get doi for time-locked sop' do
    sop = Factory(:sop, policy: Factory(:private_policy))

    login_as(sop.contributor)

    with_config_value(:time_lock_doi_for, 10) do
      get :show, params: { id: sop }

      assert_response :success
      assert_select '#citation-instructions a[href=?]', mint_doi_confirm_sop_path(sop, version: sop.version), count: 0
      assert_select '#citation-instructions', text: /SOPs must be older than 10 days/
    end
  end

  test 'shows how to get doi for eligible sop' do
    sop = Factory(:sop, policy: Factory(:public_policy))

    login_as(sop.contributor)

    get :show, params: { id: sop }

    assert_response :success
    assert_select '#citation-instructions a[href=?]', mint_doi_confirm_sop_path(sop, version: sop.version), count: 1
  end

  test 'does not show how to get a doi if no manage permission' do
    sop = Factory(:sop, policy: Factory(:publicly_viewable_policy))
    person = Factory(:person)
    refute sop.can_manage?(person.user)

    login_as(person)

    get :show, params: { id: sop }

    assert_response :success
    assert_select '#citation-instructions', count: 0
  end

  test 'content blob filename precedence should take user input first' do
    stub_request(:any, 'http://example.com/url_filename.txt')
        .to_return(body: 'hi', headers: { 'Content-Disposition' => 'attachment; filename="server_filename.txt"' })
    sop = { title: 'Test', project_ids: [@project.id] }
    blob = { data_url: 'http://example.com/url_filename.txt', original_filename: 'user_filename.txt' }

    assert_difference('Sop.count') do
      assert_difference('ContentBlob.count') do
        post :create, params: { sop: sop, content_blobs: [blob], policy_attributes: valid_sharing }
      end
    end

    assert_equal 'user_filename.txt', assigns(:sop).content_blob.original_filename
  end

  test 'content blob filename precedence should take server filename second' do
    stub_request(:any, 'http://example.com/url_filename.txt')
        .to_return(body: 'hi', headers: { 'Content-Disposition' => 'attachment; filename="server_filename.txt"' })
    sop = { title: 'Test', project_ids: [@project.id] }
    blob = { data_url: 'http://example.com/url_filename.txt' }

    assert_difference('Sop.count') do
      assert_difference('ContentBlob.count') do
        post :create, params: { sop: sop, content_blobs: [blob], policy_attributes: valid_sharing }
      end
    end

    assert_equal 'server_filename.txt', assigns(:sop).content_blob.original_filename
  end

  test 'content blob filename precedence should take URL filename last' do
    stub_request(:any, 'http://example.com/url_filename.txt').to_return(body: 'hi')
    sop = { title: 'Test', project_ids: [@project.id] }
    blob = { data_url: 'http://example.com/url_filename.txt' }

    assert_difference('Sop.count') do
      assert_difference('ContentBlob.count') do
        post :create, params: { sop: sop, content_blobs: [blob], policy_attributes: valid_sharing }
      end
    end

    assert_equal 'url_filename.txt', assigns(:sop).content_blob.original_filename
  end

  test 'should show sop as RDF' do
    sop = Factory(:sop, policy: Factory(:publicly_viewable_policy))

    get :show, params: { id: sop, format: :rdf }

    assert_response :success
  end

  test 'when updating, assay linked to must be editable' do
    person = Factory(:person)
    login_as(person)
    sop = Factory(:sop,contributor:person,projects:person.projects)
    assert sop.can_edit?
    another_person = Factory(:person)
    another_person.add_to_project_and_institution(person.projects.first,person.institutions.first)
    another_person.save!

    investigation = Factory(:investigation,contributor:person,projects:person.projects)

    study = Factory(:study, contributor:person, investigation:investigation)

    good_assay = Factory(:assay,study_id:study.id,contributor:another_person,policy:Factory(:editing_public_policy))
    bad_assay = Factory(:assay,study_id:study.id,contributor:another_person,policy:Factory(:publicly_viewable_policy))

    assert good_assay.can_edit?
    refute bad_assay.can_edit?

    assert_no_difference('AssayAsset.count') do
      put :update, params: { id: sop.id, sop: { title: sop.title, assay_assets_attributes: [{ assay_id: bad_assay.id }] } }
    end
    # FIXME: currently just skips the bad assay, but ideally should respond with an error status
    # assert_response :unprocessable_entity

    sop.reload
    assert_empty sop.assays

    assert_difference('AssayAsset.count') do
      put :update, params: { id: sop.id, sop: { title: sop.title, assay_assets_attributes: [{ assay_id: good_assay.id }] } }
    end
    sop.reload
    assert_equal [good_assay], sop.assays

  end

  test 'when creating, assay linked to must be editable' do
    person = @user.person

    another_person = Factory(:person)
    another_person.add_to_project_and_institution(person.projects.first,person.institutions.first)
    another_person.save!

    investigation = Factory(:investigation,contributor:person,projects:person.projects)

    study = Factory(:study, contributor:person, investigation:investigation)

    good_assay = Factory(:assay,study_id:study.id,contributor:another_person,policy:Factory(:editing_public_policy))
    bad_assay = Factory(:assay,study_id:study.id,contributor:another_person,policy:Factory(:publicly_viewable_policy))

    assert good_assay.can_edit?
    refute bad_assay.can_edit?

    sop, blob = valid_sop

    assert_no_difference('AssayAsset.count') do
      post :create, params: { sop: sop.merge(assay_assets_attributes: [{ assay_id: bad_assay.id }]), content_blobs: [blob], policy_attributes: valid_sharing }
    end
    # FIXME: currently just skips the bad assay, but ideally should respond with an error status
    #assert_response :unprocessable_entity

    sop, blob = valid_sop

    assert_difference('Sop.count') do
      assert_difference('AssayAsset.count') do
        post :create, params: { sop: sop.merge(assay_assets_attributes: [{ assay_id: good_assay.id }]), content_blobs: [blob], policy_attributes: valid_sharing }
      end
    end
    sop = assigns(:sop)
    assert_equal [good_assay],sop.assays
  end

  test 'should not allow sharing with a project that the contributor is not a member of' do
    sop = Factory(:sop)
    another_project = Factory(:project)
    login_as(sop.contributor)
    assert sop.can_manage?

    put :update, params: { id: sop.id, sop: { title: sop.title, project_ids: sop.project_ids + [another_project.id] } }

    refute assigns(:sop).errors.empty?
  end

  test 'should only validate newly added projects' do
    sop = Factory(:sop)
    another_project = Factory(:project)
    disable_authorization_checks { sop.projects << another_project }

    login_as(sop.contributor)
    assert sop.can_manage?
    assert_equal 2, sop.projects.length

    put :update, params: { id: sop.id, sop: { title: sop.title, project_ids: sop.reload.project_ids } }

    assert_redirected_to(sop)
    assert assigns(:sop).errors.empty?
  end

  test 'should allow association of projects even if the original contributor was not a member' do
    sop = Factory(:sop)
    another_manager = Factory(:person)
    another_project = another_manager.projects.first
    another_manager.add_to_project_and_institution(sop.projects.first, Factory(:institution))
    sop.policy.permissions.create!(contributor: another_manager, access_type: Policy::MANAGING)

    login_as(another_manager)
    assert sop.can_manage?
    assert_not_includes another_project.people, sop.contributor
    assert_equal 1, sop.projects.length

    put :update, params: { id: sop.id, sop: { title: sop.title, project_ids: (sop.project_ids + [another_project.id]) } }

    assert_redirected_to(sop)
    assert assigns(:sop).errors.empty?
  end

  test 'should not allow contributing to a project that user has left' do
    person = Factory(:person_in_multiple_projects)
    active_project = person.projects.first
    former_project = person.projects.last
    login_as(person)

    sop, blob = valid_sop
    assert_difference('Sop.count') do
      post :create, params: { sop: sop.merge(project_ids: [active_project.id, former_project.id]), content_blobs: [blob], policy_attributes: valid_sharing }
    end

    gm = person.group_memberships.detect { |gm| gm.project == former_project }
    gm.has_left = true
    gm.save!
    assert_not_includes person.current_projects.to_a, former_project
    login_as(person.reload)

    sop, blob = valid_sop
    assert_no_difference('Sop.count') do
      post :create, params: { sop: sop.merge(project_ids: [former_project.id]), content_blobs: [blob], policy_attributes: valid_sharing }
    end

    refute assigns(:sop).errors.empty?
  end

  test 'should not create new version if person has left the project' do
    project = Factory(:project)
    sop = Factory(:sop, projects: [project], policy: Factory(:publicly_viewable_policy, permissions: [Factory(:manage_permission, contributor: project)]))
    person = Factory(:person, project: project)
    gm = person.group_memberships.detect { |gm| gm.project == project }
    gm.has_left = true
    gm.save!

    login_as(person)
    assert_no_difference('Sop::Version.count', 1) do
      post :create_version, params: { id: sop.id, sop: { title: "haha!" }, content_blobs: [{ data: file_for_upload }], revision_comments: 'This is a new revision' }
    end
  end

  test 'should not include former projects in project selector' do
    person = Factory(:person_in_multiple_projects)
    active_project = person.projects.first
    former_project = person.projects.last
    gm = person.group_memberships.detect { |gm| gm.project == former_project }
    gm.has_left = true
    gm.save!

    login_as(person)

    get :new
    assert_response :success

    project_ids = JSON.parse(select_node_contents('#project-selector-possibilities-json')).map { |p| p['id'] }

    assert_includes project_ids, active_project.id
    refute_includes project_ids, former_project.id
  end

  test 'authlookup item queued if creators changed' do
    sop = Factory(:sop)
    login_as(sop.contributor)
    creator = Factory(:person)

    AuthLookupUpdateQueue.destroy_all

    with_config_value(:auth_lookup_enabled, true) do
      assert_difference('AuthLookupUpdateQueue.count', 1) do
        put :update, params: {id: sop.id, sop: {title: 'fish', creator_ids: [creator.id.to_s]}}
        assert_redirected_to sop
        assert_equal 'fish', assigns(:sop).title
        assert_equal [creator], assigns(:sop).creators
      end

      AuthLookupUpdateQueue.destroy_all

      # no job if no change to creators
      assert_no_difference('AuthLookupUpdateQueue.count') do
        put :update, params: {id: sop.id, sop: {title: 'horse', creator_ids: [creator.id.to_s]}}
        assert_redirected_to sop
        assert_equal 'horse', assigns(:sop).title
        assert_equal [creator], assigns(:sop).creators
      end

      AuthLookupUpdateQueue.destroy_all

      # job if creator removed
      assert_difference('AuthLookupUpdateQueue.count', 1) do
        put :update, params: {id: sop.id, sop: {title: 'fish', creator_ids: ['']}}
        assert_redirected_to sop
        assert_equal 'fish', assigns(:sop).title
        assert_equal [], assigns(:sop).creators
      end
    end

  end

  test 'should destroy sop and redirect to my items page' do
    person = people(:person_for_owner_of_my_first_sop)
    login_as(person)
    assert_difference('ActivityLog.count') do
      assert_difference('Sop.count', -1) do
        assert_no_difference('ContentBlob.count') do
          delete :destroy, params: { id: sops(:my_first_sop), return_to: 'my_items' }

          assert flash[:notice].include?('deleted')
        end
      end
    end

    assert_redirected_to items_person_path(person)
  end

  test 'manage menu item appears according to permission' do
    check_manage_edit_menu_for_type('sop')
  end

  test 'can access manage page with manage rights' do
    person = Factory(:person)
    sop = Factory(:sop, contributor:person)
    login_as(person)
    assert sop.can_manage?
    get :manage, params: {id: sop}
    assert_response :success

    # check the project form exists, studies and assays don't have this
    assert_select 'div#add_projects_form', count:1

    # check sharing form exists
    assert_select 'div#sharing_form', count:1

    # should be a temporary sharing link
    assert_select 'div#temporary_links', count:1

    assert_select 'div#author-form', count:1

    # this is to check the SOP is all upper case in the sharing form
    assert_select 'div.alert-info', text: /the #{I18n.t('sop')}/
  end

  test 'cannot access manage page with edit rights' do
    person = Factory(:person)
    sop = Factory(:sop, policy:Factory(:private_policy, permissions:[Factory(:permission, contributor:person, access_type:Policy::EDITING)]))
    login_as(person)
    assert sop.can_edit?
    refute sop.can_manage?
    get :manage, params: {id:sop}
    assert_redirected_to sop
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

    sop = Factory(:sop, contributor:person, projects:[proj1], policy:Factory(:private_policy))

    login_as(person)
    assert sop.can_manage?

    patch :manage_update, params: {id: sop,
                                   sop: {
                                       creator_ids: [other_creator.id],
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    assert_redirected_to sop

    sop.reload
    assert_equal [proj1,proj2],sop.projects.sort_by(&:id)
    assert_equal [other_creator],sop.creators
    assert_equal Policy::VISIBLE,sop.policy.access_type
    assert_equal 1,sop.policy.permissions.count
    assert_equal other_person,sop.policy.permissions.first.contributor
    assert_equal Policy::MANAGING,sop.policy.permissions.first.access_type

    assert_equal 'SOP was successfully updated.',flash[:notice]

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

    sop = Factory(:sop, projects:[proj1], policy:Factory(:private_policy,
                                                                     permissions:[Factory(:permission,contributor:person, access_type:Policy::EDITING)]))

    login_as(person)
    refute sop.can_manage?
    assert sop.can_edit?

    assert_equal [proj1],sop.projects
    assert_empty sop.creators

    patch :manage_update, params: {id: sop,
                                   sop: {
                                       creator_ids: [other_creator.id],
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    refute_nil flash[:error]

    sop.reload
    assert_equal [proj1],sop.projects
    assert_empty sop.creators
    assert_equal Policy::PRIVATE,sop.policy.access_type
    assert_equal 1,sop.policy.permissions.count
    assert_equal person,sop.policy.permissions.first.contributor
    assert_equal Policy::EDITING,sop.policy.permissions.first.access_type

  end

  test 'sort by update by default on index' do
    s1 = Factory(:sop, title: 'AAABSop', updated_at: 10.minutes.from_now, policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    s2 = Factory(:sop, title: 'AAAASop', updated_at: 9.minutes.from_now, policy: Factory(:public_policy, access_type: Policy::VISIBLE))

    get :index

    assert_equal '1', assigns(:page)
    assert_equal [:updated_at_desc], assigns(:order)
    assert_equal s1.id, assigns(:sops)[0].id
    assert_equal s2.id, assigns(:sops)[1].id
  end

  test 'sort by title by default on A page' do
    s1 = Factory(:sop, title: 'AAABSop', updated_at: 10.minutes.from_now, policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    s2 = Factory(:sop, title: 'AAAASop', updated_at: 9.minutes.from_now, policy: Factory(:public_policy, access_type: Policy::VISIBLE))

    get :index, params: { page: 'A' }

    assert_equal 'A', assigns(:page)
    assert_equal [:title_asc], assigns(:order)
    assert_equal s2.id, assigns(:sops)[0].id
    assert_equal s1.id, assigns(:sops)[1].id
  end

  test 'custom sorting on top page' do
    s1 = Factory(:sop, title: 'ZZZZZSop', updated_at: 10.minutes.from_now, policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    s2 = Factory(:sop, title: 'ZZZZXSop', updated_at: 9.minutes.from_now, policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    s3 = Factory(:sop, title: 'ZZZZYSop', updated_at: 8.minutes.from_now, policy: Factory(:public_policy, access_type: Policy::VISIBLE))

    get :index, params: { order: 'title_desc' }

    assert_equal '1', assigns(:page)
    assert_equal [:title_desc], assigns(:order)
    assert_equal s1.id, assigns(:sops)[0].id
    assert_equal s3.id, assigns(:sops)[1].id
    assert_equal s2.id, assigns(:sops)[2].id
  end

  test 'custom sorting on G page' do
    s1 = Factory(:sop, title: 'GZSop', created_at: 2.years.ago, policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    s2 = Factory(:sop, title: 'GXSop', created_at: 1.years.ago, policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    s3 = Factory(:sop, title: 'GYSop', created_at: 10.years.ago, policy: Factory(:public_policy, access_type: Policy::VISIBLE))

    get :index, params: { page: 'G', order: 'created_at_asc' }

    assert_equal 'G', assigns(:page)
    assert_equal [:created_at_asc], assigns(:order)
    assert_equal s3.id, assigns(:sops)[0].id
    assert_equal s1.id, assigns(:sops)[1].id
    assert_equal s2.id, assigns(:sops)[2].id
  end

  test 'sorting on numeric paging' do
    Sop.delete_all

    s1 = Factory(:sop, title: 'GZSop', created_at: 2.years.ago, updated_at: 1.week.ago,
                 policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    s2 = Factory(:sop, title: 'GXSop', created_at: 1.years.ago, updated_at: 2.weeks.ago,
                 policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    s3 = Factory(:sop, title: 'GYSop', created_at: 10.years.ago, updated_at: 3.weeks.ago,
                 policy: Factory(:public_policy, access_type: Policy::VISIBLE))

    with_config_value(:results_per_page_default, 2) do
      get :index, params: { page: 1, order: 'created_at_desc'}
      assert_equal [:created_at_desc], assigns(:order)
      assert_equal 2, assigns(:sops).length
      assert_equal [s2, s1], assigns(:sops).to_a
      assert_equal '1', assigns(:page)

      get :index, params: { page: 2, order: 'created_at_desc' }
      assert_equal [:created_at_desc], assigns(:order)
      assert_equal 1, assigns(:sops).length
      assert_includes assigns(:sops), s3
      assert_equal '2', assigns(:page)

      get :index, params: { page: 1, order: 'title_asc' }
      assert_equal [:title_asc], assigns(:order)
      assert_equal 2, assigns(:sops).length
      assert_equal [s2, s3], assigns(:sops).to_a
      assert_equal '1', assigns(:page)

      get :index, params: { page: 2, order: 'title_asc' }
      assert_equal [:title_asc], assigns(:order)
      assert_equal 1, assigns(:sops).length
      assert_includes assigns(:sops), s1
      assert_equal '2', assigns(:page)

      get :index, params: { order: 'fish' }
      assert_equal [:updated_at_desc], assigns(:order)
      assert_equal 2, assigns(:sops).length
      assert_equal [s1, s2], assigns(:sops).to_a
      assert_equal '1', assigns(:page)

      get :index, params: { page: 2, order: 'fish' }
      assert_equal [:updated_at_desc], assigns(:order)
      assert_equal 1, assigns(:sops).length
      assert_includes assigns(:sops), s3
      assert_equal '2', assigns(:page)
    end
  end

  test 'JSON-API multiple sorting' do
    s1 = Factory(:sop, title: 'ZZSop', created_at: 2.years.ago, policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    s2 = Factory(:sop, title: 'ZXSop', created_at: 1.years.ago, policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    s3 = Factory(:sop, title: 'ZXSop', created_at: 10.years.ago, policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    s4 = Factory(:sop, title: 'ZYSop', created_at: 10.years.ago, policy: Factory(:public_policy, access_type: Policy::VISIBLE))

    get :index, params: { page: 'Z', sort: 'title,-created_at' }

    assert_equal 'Z', assigns(:page)
    assert_equal [:title_asc, :created_at_desc], assigns(:order)
    assert_equal s2.id, assigns(:sops)[0].id
    assert_equal s3.id, assigns(:sops)[1].id
    assert_equal s4.id, assigns(:sops)[2].id
    assert_equal s1.id, assigns(:sops)[3].id
  end

  test 'should create with discussion link' do
    person = Factory(:person)
    login_as(person)
    sop =  {title: 'SOP', project_ids: [person.projects.first.id], discussion_links_attributes:[{url: "http://www.slack.com/"}]}
    assert_difference('AssetLink.discussion.count') do
      assert_difference('Sop.count') do
        assert_difference('ContentBlob.count') do
          post :create, params: {sop: sop, content_blobs: [{ data: file_for_upload }], policy_attributes: { access_type: Policy::VISIBLE }}
        end
      end
    end
    sop = assigns(:sop)
    assert_equal 'http://www.slack.com/', sop.discussion_links.first.url
    assert_equal AssetLink::DISCUSSION, sop.discussion_links.first.link_type
  end


  test 'should show discussion link' do
    asset_link = Factory(:discussion_link)
    sop = Factory(:sop, discussion_links: [asset_link], policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    get :show, params: { id: sop }
    assert_response :success
    assert_select 'div.panel-heading', text: /Discussion Channel/, count: 1
  end


  test 'should update sop with new discussion link' do
    person = Factory(:person)
    sop = Factory(:sop, contributor: person)
    login_as(person)
    assert_nil sop.discussion_links.first
    assert_difference('AssetLink.discussion.count') do
      assert_difference('ActivityLog.count') do
        put :update, params: { id: sop.id, sop: { discussion_links_attributes:[{url: "http://www.slack.com/"}] } }
      end
    end
    assert_redirected_to sop_path(assigns(:sop))
    assert_equal 'http://www.slack.com/', sop.discussion_links.first.url
  end

  test 'should update sop with edited discussion link' do
    person = Factory(:person)
    sop = Factory(:sop, contributor: person, discussion_links:[Factory(:discussion_link)])
    login_as(person)
    assert_equal 1,sop.discussion_links.count
    assert_no_difference('AssetLink.discussion.count') do
      assert_difference('ActivityLog.count') do
        put :update, params: { id: sop.id, sop: { discussion_links_attributes:[{id:sop.discussion_links.first.id, url: "http://www.wibble.com/",link_type: AssetLink::DISCUSSION}] } }
      end
    end
    sop = assigns(:sop)
    assert_redirected_to sop_path(sop)
    assert_equal 1,sop.discussion_links.count
    assert_equal 'http://www.wibble.com/', sop.discussion_links.first.url
  end

  test 'should destroy related assetlink when the discussion link is removed ' do
    person = Factory(:person)
    login_as(person)
    asset_link = Factory(:discussion_link)
    sop = Factory(:sop, discussion_links: [asset_link], policy: Factory(:public_policy, access_type: Policy::VISIBLE), contributor: person)
    assert_difference('AssetLink.discussion.count', -1) do
      put :update, params: { id: sop.id, sop: { discussion_links_attributes:[{id:asset_link.id, _destroy:'1'}] } }
    end
    assert_redirected_to sop_path(sop = assigns(:sop))
    assert_empty sop.discussion_links
  end

  test 'should immediately update auth for anon user' do
    with_config_value(:auth_lookup_enabled, true) do
      login_as(person = Factory(:person))
      sop = Factory(:sop, contributor: person, policy: Factory(:private_policy))
      AuthLookupUpdateQueue.destroy_all
      refute sop.can_view?(nil)

      put :update, params: { id: sop.id, sop: { title: 'Test2' }, policy_attributes: { access_type: Policy::ACCESSIBLE } }

      sop = assigns(:sop)
      assert_equal Policy::ACCESSIBLE, sop.policy.access_type
      assert sop.can_view?(nil)
    end
  end

  test 'can edit version revision comments' do
    sop = Factory(:sop)
    login_as(sop.contributor)
    disable_authorization_checks do
      sop.save_as_new_version('something')
    end

    assert_not_equal 'modified', sop.find_version(2).revision_comments

    post :edit_version, params: { id: sop.id, version: 2, revision_comments: 'modified' }
    assert_redirected_to sop

    assert_equal 'modified', sop.find_version(2).reload.revision_comments
  end

  test 'can edit version visibility' do
    sop = Factory(:sop)
    login_as(sop.contributor)
    disable_authorization_checks do
      sop.save_as_new_version('new v')
    end

    assert_not_equal :registered_users, sop.find_version(1).visibility

    post :edit_version, params: { id: sop.id, version: 1, visibility: 'registered_users' }
    assert_redirected_to sop

    assert_equal :registered_users, sop.find_version(1).reload.visibility
  end

  test 'cannot edit version visibility if doi minted' do
    sop = Factory(:sop)
    login_as(sop.contributor)
    disable_authorization_checks do
      sop.save_as_new_version('yep')
      sop.find_version(1).update_column(:doi, '10.5072/wtf')
    end

    assert_equal :public, sop.find_version(1).visibility

    post :edit_version, params: { id: sop.id, version: 1, visibility: 'private' }
    assert_redirected_to sop

    assert_equal :public, sop.find_version(1).reload.visibility, 'Should not have changed visibility - DOI present'
  end

  test 'cannot edit version visibility if latest version' do
    sop = Factory(:sop)
    login_as(sop.contributor)
    disable_authorization_checks do
      sop.save_as_new_version('fhsdkjhfgjlk')
    end

    assert_equal :public, sop.find_version(2).visibility

    post :edit_version, params: { id: sop.id, version: 2, visibility: 'private' }
    assert_redirected_to sop

    assert_equal :public, sop.find_version(2).reload.visibility, 'Should not have changed visibility - latest version'
  end

  test 'can add assets_creators via API' do
    sop = Factory(:sop)
    person = Factory(:person, first_name: 'Jane', last_name: 'Smith')
    login_as(sop.contributor)
    assert_difference('AssetsCreator.count', 2) do
      disable_authorization_checks do
        sop.api_assets_creators = [
          {
            given_name: "Joe",
            family_name: "Bloggs",
            affiliation: "School of Rock",
            orcid: "https://orcid.org/0000-0002-5111-7263"
          },
          {
            given_name: nil,
            family_name: nil,
            affiliation: nil,
            orcid: nil,
            creator_id: person.id
          }
        ]
        assert sop.save
      end
    end
  end

  test 'can update assets_creators via API' do
    person = Factory(:person, first_name: 'Jane', last_name: 'Smith')
    person2 = Factory(:person, first_name: 'Sally', last_name: 'Smith')
    sop = Factory(:sop)
    ac1 = nil
    ac2 = nil
    ac3 = nil
    disable_authorization_checks do
      ac1 = sop.assets_creators.create(creator_id: person)
      ac2 = sop.assets_creators.create(family_name: 'Smith', given_name: 'Bob')
      ac3 = sop.assets_creators.create(family_name: 'Smith', given_name: 'Fred')
    end
    login_as(sop.contributor)
    assert_difference('AssetsCreator.count', 1) do
      disable_authorization_checks do
        sop.api_assets_creators = [
          {
            given_name: "Joe",
            family_name: "Bloggs"
          },
          {
            given_name: "Bob",
            family_name: "Smith"
          },
          {
            given_name: nil,
            family_name: nil,
            affiliation: nil,
            orcid: nil,
            creator_id: person.id
          },
          {
            given_name: nil,
            family_name: nil,
            affiliation: nil,
            orcid: nil,
            creator_id: person2.id
          }
        ]
        assert sop.save
        sop.reload
        assert_equal 4, sop.assets_creators.count
        assert_includes sop.assets_creators, ac1
        assert_includes sop.assets_creators, ac2
        assert ac3.destroyed?
        names = sop.assets_creators.map(&:name)
        assert_includes names, 'Joe Bloggs'
        assert_includes names, 'Bob Smith'
        assert_includes names, 'Sally Smith'
        assert_includes names, 'Jane Smith'
      end
    end
  end

  test 'can adjust assets_creators positions in API without creating/deleting records' do
    person = Factory(:person, first_name: 'Jane', last_name: 'Smith')
    sop = Factory(:sop)
    ac1 = nil
    ac2 = nil
    disable_authorization_checks do
      ac2 = sop.assets_creators.create(pos: 1, family_name: 'Smith', given_name: 'Bob')
      ac1 = sop.assets_creators.create(pos: 2, creator_id: person)
    end
    login_as(sop.contributor)
    assert_no_difference('AssetsCreator.count') do
      disable_authorization_checks do
        sop.api_assets_creators = [
          {
            pos: 2,
            given_name: "Bob",
            family_name: "Smith"
          },
          {
            pos: 1,
            given_name: nil,
            family_name: nil,
            affiliation: nil,
            orcid: nil,
            creator_id: person.id
          }
        ]
        assert sop.save
        sop.reload
        assert_equal 2, sop.assets_creators.count
        assert_includes sop.assets_creator_ids, ac1.id
        assert_includes sop.assets_creator_ids, ac2.id
        names = sop.assets_creators.map(&:name)
        assert_includes names, 'Bob Smith'
        assert_includes names, 'Jane Smith'
      end
    end
  end

  private

  def doi_citation_mock
    stub_request(:get, /(https?:\/\/)?(dx\.)?doi\.org\/.+/)
        .with(headers: { 'Accept' => 'application/vnd.citationstyles.csl+json' })
        .to_return(body: File.new("#{Rails.root}/test/fixtures/files/mocking/doi_metadata.json"), status: 200)

    stub_request(:get, 'https://doi.org/10.5072/test')
        .with(headers: { 'Accept' => 'application/vnd.citationstyles.csl+json' })
        .to_return(body: File.new("#{Rails.root}/test/fixtures/files/mocking/doi_metadata.json"), status: 200)

    stub_request(:get, 'https://doi.org/10.5072/broken')
        .with(headers: { 'Accept' => 'application/vnd.citationstyles.csl+json' })
        .to_return(body: File.new("#{Rails.root}/test/fixtures/files/mocking/broken_doi_metadata_response.html"), status: 200)
  end

  def picture_file(options = {})
    options.reverse_merge!({ filename: 'file_picture.png',
                             content_type: 'image/png',
                             tempfile_fixture: 'files/file_picture.png' })
    fixture_file_upload(options[:tempfile_fixture], options[:content_type])
  end

  def valid_sop_with_url
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://www.sysmo-db.org/images/sysmo-db-logo-grad2.png'
    [{ title: 'Test', project_ids: [@project.id] }, { data_url: 'http://www.sysmo-db.org/images/sysmo-db-logo-grad2.png' }]
  end

  def valid_sop
    [{ title: 'Test', project_ids: [@project.id] }, { data: picture_file, data_url: '' }]
  end
end
