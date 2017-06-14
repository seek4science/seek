require 'test_helper'

class LogPublishingTest < ActionController::TestCase
  tests DataFilesController

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:datafile_owner)
    @gatekeeper = Factory(:asset_gatekeeper)
  end

  test 'log when creating the public item' do
    @controller = SopsController.new
    sop_params, blob = valid_sop
    sop_params[:project_ids] = [Factory(:project).id] # this project has no gatekeeper
    assert_difference ('ResourcePublishLog.count') do
      post :create, sop: sop_params, content_blobs: [blob], policy_attributes: public_sharing
    end
    publish_log = ResourcePublishLog.last
    assert_equal ResourcePublishLog::PUBLISHED, publish_log.publish_state.to_i
    sop = assigns(:sop)
    assert_equal sop, publish_log.resource
    assert_equal sop.contributor, publish_log.user
  end

  test 'log when creating item and request publish it' do
    sop, blob = valid_sop
    @controller = SopsController.new
    assert_difference ('ResourcePublishLog.count') do
      post :create, sop: sop, content_blobs: [blob], policy_attributes: { access_type: Policy::VISIBLE }
    end
    publish_log = ResourcePublishLog.last
    assert_equal ResourcePublishLog::WAITING_FOR_APPROVAL, publish_log.publish_state.to_i
    sop = assigns(:sop)
    assert_equal sop, publish_log.resource
    assert_equal sop.contributor, publish_log.user
  end

  test 'dont log when creating the non-public item' do
    @controller = SopsController.new
    sop, blob = valid_sop
    assert_no_difference ('ResourcePublishLog.count') do
      post :create, sop: sop, content_blobs: [blob]
    end

    assert_equal Policy::NO_ACCESS, assigns(:sop).policy.access_type
  end

  test 'log when updating an item from non-public to public' do
    @controller = SopsController.new
    owner = Factory(:person)
    login_as(owner.user)

    sop = Factory(:sop, contributor: owner.user)
    assert_equal Policy::NO_ACCESS, sop.policy.access_type
    assert sop.can_publish?

    assert_difference ('ResourcePublishLog.count') do
      put :update, id: sop.id, sop: { title: sop.title }, policy_attributes: public_sharing
    end
    publish_log = ResourcePublishLog.last
    assert_equal ResourcePublishLog::PUBLISHED, publish_log.publish_state.to_i
    sop = assigns(:sop)
    assert_equal sop, publish_log.resource
    assert_equal sop.contributor, publish_log.user
  end

  test 'log when sending the publish request approval during updating a non-public item' do
    @controller = SopsController.new
    owner = Factory(:person)
    login_as(owner.user)

    sop = Factory(:sop, project_ids: [@gatekeeper.projects.first.id], contributor: owner.user)
    assert_equal Policy::NO_ACCESS, sop.policy.access_type
    assert sop.can_publish?

    assert_difference ('ResourcePublishLog.count') do
      put :update, id: sop.id, sop: { title: sop.title }, policy_attributes: { access_type: Policy::VISIBLE }
    end
    publish_log = ResourcePublishLog.last
    assert_equal ResourcePublishLog::WAITING_FOR_APPROVAL, publish_log.publish_state.to_i
    sop = assigns(:sop)
    assert_equal sop, publish_log.resource
    assert_equal sop.contributor, publish_log.user
  end

  test 'dont log when updating an item with the not-related public sharing' do
    @controller = SopsController.new
    owner = Factory(:person)
    login_as(owner.user)
    sop = Factory(:sop, contributor: owner.user)
    assert_equal Policy::NO_ACCESS, sop.policy.access_type

    assert_no_difference ('ResourcePublishLog.count') do
      put :update, id: sop.id, sop: { title: sop.title }, policy_attributes: { access_type: Policy::NO_ACCESS }
    end
  end

  test 'log when un-publishing an item' do
    @controller = SopsController.new
    owner = Factory(:person)
    login_as(owner.user)

    sop = Factory(:sop, contributor: owner.user, policy: Factory(:public_policy))
    assert_not_equal Policy::NO_ACCESS, sop.policy.access_type

    # create a published log for the published sop
    ResourcePublishLog.create(resource: sop, user: User.current_user, publish_state: ResourcePublishLog::PUBLISHED)

    assert_difference ('ResourcePublishLog.count') do
      put :update, id: sop.id, sop: { title: sop.title }, policy_attributes: { access_type: Policy::NO_ACCESS }
    end
    publish_log = ResourcePublishLog.last
    assert_equal ResourcePublishLog::UNPUBLISHED, publish_log.publish_state.to_i
    sop = assigns(:sop)
    assert_equal sop, publish_log.resource
    assert_equal sop.contributor, publish_log.user
  end

  test 'log when approving publishing an item' do
    df = Factory(:data_file, project_ids: @gatekeeper.projects.collect(&:id))

    login_as(df.contributor)
    put :update, id: df.id, data_file: { title: df.title }, policy_attributes: { access_type: Policy::VISIBLE }

    logout

    login_as(@gatekeeper.user)
    @controller = PeopleController.new
    params = { gatekeeper_decide: {} }
    params[:gatekeeper_decide][df.class.name] ||= {}
    params[:gatekeeper_decide][df.class.name][df.id.to_s] ||= {}
    params[:gatekeeper_decide][df.class.name][df.id.to_s]['decision'] = 1

    assert_difference ('ResourcePublishLog.count') do
      post :gatekeeper_decide, params.merge(id: @gatekeeper.id)
    end

    publish_log = ResourcePublishLog.last
    assert_equal ResourcePublishLog::PUBLISHED, publish_log.publish_state.to_i
    assert_equal df, publish_log.resource
    assert_equal @gatekeeper.user, publish_log.user
  end

  test 'gatekeeper cannot approve an item from another project' do
    gatekeeper2 = Factory(:asset_gatekeeper)
    df = Factory(:data_file, project_ids: gatekeeper2.projects.collect(&:id))

    login_as(df.contributor)
    put :update, id: df.id, data_file: { title: df.title }, policy_attributes: { access_type: Policy::VISIBLE }

    logout

    publish_log = ResourcePublishLog.last
    assert_equal ResourcePublishLog::WAITING_FOR_APPROVAL, publish_log.publish_state.to_i

    login_as(@gatekeeper.user)
    @controller = PeopleController.new
    params = { gatekeeper_decide: {} }
    params[:gatekeeper_decide][df.class.name] ||= {}
    params[:gatekeeper_decide][df.class.name][df.id.to_s] ||= {}
    params[:gatekeeper_decide][df.class.name][df.id.to_s]['decision'] = 1

    assert_no_difference ('ResourcePublishLog.count') do
      post :gatekeeper_decide, params.merge(id: @gatekeeper.id)
    end

    publish_log2 = ResourcePublishLog.last
    assert_equal publish_log2, publish_log
  end

  test 'log when publish isa' do
    df = Factory :data_file,
                 contributor: users(:datafile_owner),
                 assays: [Factory(:assay)]

    assay = df.assays.first

    request_publishing_df = Factory(:data_file,
                                    project_ids: Factory(:asset_gatekeeper).projects.collect(&:id),
                                    contributor: users(:datafile_owner),
                                    assays: [assay])

    assert !df.is_published?, 'The datafile must be not be published for this test to succeed'
    assert df.can_publish?, 'The datafile must be publishable for this test to succeed'
    assert !request_publishing_df.is_published?, 'The datafile must be not be published for this test to succeed'
    assert request_publishing_df.can_publish?, 'The datafile must be publishable for this test to succeed'

    params = { publish: {} }
    params[:publish][df.class.name] ||= {}
    params[:publish][df.class.name][df.id.to_s] = '1'
    params[:publish][request_publishing_df.class.name] ||= {}
    params[:publish][request_publishing_df.class.name][request_publishing_df.id.to_s] = '1'

    assert_difference('ResourcePublishLog.count', 2) do
      post :publish, params.merge(id: df)
      a = 1
    end
    assert_response :redirect

    log_for_df = ResourcePublishLog.where('resource_type=? AND resource_id=?', 'DataFile', df.id).last
    assert_equal ResourcePublishLog::PUBLISHED, log_for_df.publish_state
    log_for_request_publishing_df = ResourcePublishLog.where('resource_type=? AND resource_id=?', 'DataFile', request_publishing_df.id).last
    assert_equal ResourcePublishLog::WAITING_FOR_APPROVAL, log_for_request_publishing_df.publish_state
  end

  private

  def valid_sop
    [{ title: 'Test', project_ids: [@gatekeeper.projects.first.id] }, { data: file_for_upload }]
  end

  def public_sharing
    { access_type: Policy::ACCESSIBLE }
  end
end
