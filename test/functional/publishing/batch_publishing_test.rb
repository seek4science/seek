require 'test_helper'

class BatchPublishingTest < ActionController::TestCase
  tests PeopleController

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    @user = users(:aaron)
    login_as(@user)
  end

  test 'should have the -Publish your assets- only on your own profile' do
    get :show, params: { id: User.current_user.person }
    assert_response :success
    assert_select 'a[href=?]', batch_publishing_preview_person_path, text: /Publish your assets/

    get :batch_publishing_preview, params: { id: User.current_user.person.id }
    assert_response :success
    assert_nil flash[:error]

    # not yourself
    a_person = FactoryBot.create(:person)
    get :show, params: { id: a_person }
    assert_response :success
    assert_select 'a', text: /Publish your assets/, count: 0

    get :batch_publishing_preview, params: { id: a_person.id }
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test 'get batch_publishing_preview' do
    # bundle of assets that can publish immediately
    publish_immediately_assets = create_publish_immediately_assets
    publish_immediately_assets.each do |a|
      assert a.can_publish?, 'The asset must be publishable for this test to succeed'
    end
    # bundle of assets that can not publish immediately but can send the publish request to gatekeepers
    gatekeeper_required_assets = create_gatekeeper_required_assets
    gatekeeper_required_assets.each do |a|
      assert a.can_publish?, 'The asset must not be publishable for this test to succeed'
      assert a.gatekeeper_required?, "This asset must require gatekeeper's approval for this test to succeed"
    end
    total_asset_count = (publish_immediately_assets + gatekeeper_required_assets).count

    get :batch_publishing_preview, params: { id: User.current_user.person.id }
    assert_response :success

    assert_select '.type_and_title', count: total_asset_count do
      publish_immediately_assets.each do |a|
        assert_select 'a[href=?]', eval("#{a.class.name.underscore}_path(#{a.id})"), text: /#{a.title}/
      end
      gatekeeper_required_assets.each do |a|
        assert_select 'a[href=?]', eval("#{a.class.name.underscore}_path(#{a.id})"), text: /#{a.title}/
      end
      assert_select '.type_and_title img[src*=?][title=?]', 'lock.png', 'Private', count: total_asset_count
    end

    assert_select '.parent-btn-checkbox', text: /Publish/, count: total_asset_count do
      publish_immediately_assets.each do |a|
        assert_select "input[type='checkbox'][id=?]", "publish_#{a.class.name}_#{a.id}"
      end
      gatekeeper_required_assets.each do |a|
        assert_select "input[type='checkbox'][id=?]", "publish_#{a.class.name}_#{a.id}"
      end
    end
  end

  test 'do not have not-publishable items in batch_publishing_preview' do
    published_item = FactoryBot.create(:data_file,
                             contributor: User.current_user.person,
                             policy: FactoryBot.create(:public_policy))
    assert !published_item.can_publish?, 'This data file must not be publishable for the test to succeed'

    get :batch_publishing_preview, params: { id: User.current_user.person.id }
    assert_response :success

    assert_select "input[type='checkbox'][id=?]", "publish_#{published_item.class.name}_#{published_item.id}",
                  count: 0
  end

  test 'do not have not_publishable_type item in batch_publishing_preview' do
    item = FactoryBot.create(:publication,
                   contributor: User.current_user.person,
                   policy: FactoryBot.create(:public_policy))
    refute item.can_publish?, 'This item must not be publishable for the test to be meaningful'

    get :batch_publishing_preview, params: { id: User.current_user.person.id }
    assert_response :success

    assert_select "input[type='checkbox'][id=?]", "publish_#{item.class.name}_#{item.id}",
                  count: 0
  end

  test 'do publish' do
    # bundle of assets that can publish immediately
    publish_immediately_assets = create_publish_immediately_assets
    publish_immediately_assets.each do |a|
      assert !a.is_published?
      assert a.can_publish?, 'The asset must be publishable for this test to succeed'
    end
    # bundle of assets that can not publish immediately but can send the publish request
    gatekeeper_required_assets = create_gatekeeper_required_assets
    gatekeeper_required_assets.each do |a|
      assert a.can_publish?, 'The asset must be publishable for this test to succeed'
    end

    total_assets = publish_immediately_assets + gatekeeper_required_assets

    params = { publish: {} }

    total_assets.each do |asset|
      params[:publish][asset.class.name] ||= {}
      params[:publish][asset.class.name][asset.id.to_s] = '1'
    end

    assert_difference('ResourcePublishLog.count', total_assets.count) do
      assert_enqueued_emails gatekeeper_required_assets.count do
        post :publish, params: params.merge(id: User.current_user.person.id)
      end
    end
    assert_response :redirect
    assert_nil flash[:error]
    assert_not_nil flash[:notice]

    publish_immediately_assets.each do |a|
      a.reload
      assert a.is_published?
    end
    gatekeeper_required_assets.each do |a|
      a.reload
      assert !a.is_published?
    end
  end

  test 'get publish redirected' do
    # This is useful because if you logout it redirects to root.
    # If you just published something, that will do a get request to *Controller#publish
    get :publish, params: { id: User.current_user.person.id }
    assert_response :redirect
  end

  # The following tests are for generating your asset list that you requested to make published are still waiting for approval
  test 'should have the -Your assets waiting for approval- button only on your profile' do
    # not yourself
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    me = FactoryBot.create(:person, group_memberships: [FactoryBot.create(:group_membership, work_group: gatekeeper.group_memberships.first.work_group)])
    another_person = FactoryBot.create(:person, group_memberships: [FactoryBot.create(:group_membership, work_group: gatekeeper.group_memberships.first.work_group)])

    login_as(me)

    get :show, params: { id: another_person }
    assert_response :success
    assert_select 'a', text: /Assets awaiting approval/, count: 0

    # yourself
    get :show, params: { id: User.current_user.person }
    assert_response :success
    assert_select 'a[href=?]', waiting_approval_assets_person_path, text: /Assets awaiting approval/
  end

  test 'authorization for waiting_approval_assets' do
    get :waiting_approval_assets, params: { id: User.current_user.person }
    assert_response :success
    assert_nil flash[:error]

    a_person = FactoryBot.create(:person)
    get :waiting_approval_assets, params: { id: a_person }
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test 'get waiting_approval_assets' do
    df, model, sop = waiting_approval_assets_for User.current_user
    not_requested_df = FactoryBot.create(:data_file, contributor: User.current_user.person)

    get :waiting_approval_assets, params: { id: User.current_user.person }

    assert_select '.type_and_title', count: 3 do
      assert_select 'a[href=?]', data_file_path(df)
      assert_select 'a[href=?]', model_path(model)
      assert_select 'a[href=?]', sop_path(sop)
    end

    assert_select '.request_info', count: 3 do
      assert_select 'a[href=?]', person_path(df.asset_gatekeepers.first), count: 3
    end

    assert_select 'a[href=?]', data_file_path(not_requested_df), count: 0
  end

  test 'authorization for cancel_publishing_request' do
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    gatekept_project = gatekeeper.projects.first
    a_person = FactoryBot.create(:person)
    a_person.add_to_project_and_institution(gatekept_project, FactoryBot.create(:institution))
    df = FactoryBot.create(:data_file, contributor: a_person, projects: [gatekept_project])
    df.resource_publish_logs.create(publish_state: ResourcePublishLog::WAITING_FOR_APPROVAL, user: a_person.user)
    another_person = FactoryBot.create(:person)
    another_person.add_to_project_and_institution(gatekept_project, FactoryBot.create(:institution))
    df2 = FactoryBot.create(:data_file, contributor: another_person, projects: [gatekept_project])
    df2.resource_publish_logs.create(publish_state: ResourcePublishLog::WAITING_FOR_APPROVAL, user: another_person.user)
    df2.policy.permissions << FactoryBot.create(:permission, contributor: a_person, access_type: Policy::MANAGING)

    # Another person cannot access cancel_publishing_request using someone else's id
    login_as(another_person)
    assert_enqueued_emails 0 do
      post :cancel_publishing_request, params: { id: a_person,
                                                asset_id: df.id,
                                                asset_class: df.class }
      assert_redirected_to :root
      assert_not_nil flash[:error]
    end

    # Another person cannot access cancel_publishing_request without manage rights
    login_as(another_person)
    assert_enqueued_emails 0 do
      post :cancel_publishing_request, params: { id: another_person,
                                                asset_id: df.id,
                                                asset_class: df.class }
      assert_redirected_to :root
      assert_not_nil flash[:error]
    end

    # A person who created publish request can cancel_publishing_request
    login_as(a_person)
    get :waiting_approval_assets, params: { id: a_person }
    assert_select '.type_and_title', count: 1 do
      assert_select 'a[href=?]', data_file_path(df)
    end
    assert_enqueued_emails 1 do
      post :cancel_publishing_request, params: { id: a_person,
                                                asset_id: df.id,
                                                asset_class: df.class }
      assert_redirected_to waiting_approval_assets_person_path(a_person)
      assert_nil flash[:error]
      assert_not_nil flash[:notice]
    end

    # A person with manage rights can cancel_publishing_request, even if not the one who requested
    get :waiting_approval_assets, params: { id: a_person }
    assert_select '.type_and_title', count: 0
    assert df2.can_manage?
    assert_enqueued_emails 1 do
      post :cancel_publishing_request, params: { id: a_person,
                                                 asset_id: df2.id,
                                                 asset_class: df2.class }
      assert_nil flash[:error]
      assert_not_nil flash[:notice]
    end
  end

  test 'cancel_publishing_request' do
    df, model, sop = waiting_approval_assets_for User.current_user
    sop.resource_publish_logs.create(publish_state: ResourcePublishLog::REJECTED, user: User.current_user)

    get :waiting_approval_assets, params: { id: User.current_user.person }

    assert_select '.cancel_publish_request', count: 3 do
      assert_select 'a[href=?]', cancel_publishing_request_person_path(User.current_user.person,asset_id: df.id, asset_class: df.class)
      assert_select 'a[href=?]', cancel_publishing_request_person_path(User.current_user.person,asset_id: model.id, asset_class: model.class)
      assert_select 'a[href=?]', cancel_publishing_request_person_path(User.current_user.person,asset_id: sop.id, asset_class: sop.class)
    end

    get :cancel_publishing_request, params: { id: User.current_user.person,
                                              asset_id: model.id,
                                              asset_class: model.class }
    assert_redirected_to waiting_approval_assets_person_path(User.current_user.person)
    assert_nil flash[:error]
    assert_equal "Cancelled request to publish for: #{model.title}", flash[:notice]
    assert_equal ResourcePublishLog::WAITING_FOR_APPROVAL, df.last_publishing_log.publish_state
    assert_equal ResourcePublishLog::UNPUBLISHED, model.last_publishing_log.publish_state
    assert_equal ResourcePublishLog::REJECTED, sop.last_publishing_log.publish_state
  end

  private

  def create_publish_immediately_assets
    publishable_types = Seek::Util.authorized_types.select { |c| c.first.try(:is_in_isa_publishable?) }
    publishable_types.collect do |klass|
      FactoryBot.create(klass.name.underscore.to_sym, contributor: User.current_user.person)
    end
  end

  def create_gatekeeper_required_assets
    publishable_types = Seek::Util.authorized_types.select { |c| c.first.try(:is_in_isa_publishable?) }
    publishable_types.collect do |klass|
      gatekeeper = FactoryBot.create(:asset_gatekeeper)
      gatekept_project = gatekeeper.projects.first
      @user.person.add_to_project_and_institution(gatekept_project, FactoryBot.create(:institution))
      FactoryBot.create(klass.name.underscore.to_sym, contributor: @user.person, projects: [gatekept_project])
    end
  end

  def waiting_approval_assets_for(user)
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    gatekept_project = gatekeeper.projects.first
    user.person.add_to_project_and_institution(gatekept_project, FactoryBot.create(:institution))

    df = FactoryBot.create(:data_file, contributor: user.person, projects: [gatekept_project])
    df.resource_publish_logs.create(publish_state: ResourcePublishLog::WAITING_FOR_APPROVAL, user: user)
    model = FactoryBot.create(:model, contributor: user.person, projects: [gatekept_project])
    model.resource_publish_logs.create(publish_state: ResourcePublishLog::WAITING_FOR_APPROVAL, user: user)
    sop = FactoryBot.create(:sop, contributor: user.person, projects: [gatekept_project])
    sop.resource_publish_logs.create(publish_state: ResourcePublishLog::WAITING_FOR_APPROVAL, user: user)
    [df, model, sop]
  end
end
