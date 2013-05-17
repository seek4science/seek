require 'test_helper'

class GatekeeperPublishTest < ActionController::TestCase

  tests DataFilesController

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:datafile_owner)
    @object=data_files(:picture)
  end


  test 'should not allow to decide publishing for non-gatekeeper' do
    login_as(:quentin)
    df = Factory(:data_file,:project_ids => people(:quentin_person).projects.collect(&:id))
    get :approve_or_reject_publish, :id=>df.id
    assert_redirected_to :root
    assert_not_nil flash[:error]

    post :gatekeeper_decide, :id => df.id, :gatekeeper_decision => 1
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test "gracefully handle approve_or_reject for deleted items" do
    gatekeeper = Factory(:gatekeeper)

    login_as(gatekeeper.user)
    get :approve_or_reject_publish, :id=>0
    assert_redirected_to :root
    assert_not_nil flash[:error]
    assert_equal "This resource is not found",flash[:error]
  end

  test 'gatekeeper should be able to decide publishing' do
    gatekeeper = Factory(:gatekeeper)
    df = Factory(:data_file,:project_ids => gatekeeper.projects.collect(&:id))
    df.resource_publish_logs.create(:publish_state=>ResourcePublishLog::WAITING_FOR_APPROVAL)

    login_as(gatekeeper.user)
    get :approve_or_reject_publish, :id=>df.id
    assert_response :success
    assert_nil flash[:error]

    post :gatekeeper_decide, :id => df.id, :gatekeeper_decision => 0
    assert_redirected_to data_file_path(df)
    assert_nil flash[:error]
    df.reload
    assert_not_equal Policy::EVERYONE, df.policy.sharing_scope

    post :gatekeeper_decide, :id => df.id, :gatekeeper_decision => 1
    assert_redirected_to data_file_path(df)
    assert_nil flash[:error]
    df.reload
    assert_equal Policy::EVERYONE, df.policy.sharing_scope
    assert_equal Policy::ACCESSIBLE, df.policy.access_type
  end

  test 'should not allow to decide publishing for gatekeeper from other projects' do
    gatekeeper = Factory(:gatekeeper)
    df = Factory(:data_file)
    df.resource_publish_logs.create(:publish_state=>ResourcePublishLog::WAITING_FOR_APPROVAL)

    assert (df.projects&gatekeeper.projects).empty?
    login_as(gatekeeper.user)
    get :approve_or_reject_publish, :id=>df.id
    assert_redirected_to :root
    assert_not_nil flash[:error]

    post :gatekeeper_decide, :id => df.id, :gatekeeper_decision => 1
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test 'do not allow to decide publishing if the asset is not in waiting_for_approval state' do
    gatekeeper = Factory(:gatekeeper)
    df = Factory(:data_file, :project_ids => gatekeeper.projects.collect(&:id))

    login_as(gatekeeper.user)
    post :gatekeeper_decide, :id => df.id, :gatekeeper_decision => 1

    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test 'allow to decide publishing if the asset is in waiting_for_approval state' do
    gatekeeper = Factory(:gatekeeper)
    df = Factory(:data_file, :project_ids => gatekeeper.projects.collect(&:id))
    df.resource_publish_logs.create(:publish_state=>ResourcePublishLog::WAITING_FOR_APPROVAL)

    login_as(gatekeeper.user)
    post :gatekeeper_decide, :id => df.id, :gatekeeper_decision => 1

    assert_nil flash[:error]
  end

  test 'gatekeeper approves' do
    gatekeeper = Factory(:gatekeeper)
    df = Factory(:data_file, :project_ids => gatekeeper.projects.collect(&:id))
    df.resource_publish_logs.create(:publish_state=>ResourcePublishLog::WAITING_FOR_APPROVAL,:culprit=>df.contributor)

    login_as(gatekeeper.user)
    #send feedback email to requester
    assert_emails 1 do
      post :gatekeeper_decide, :id => df.id, :gatekeeper_decision => 1
    end

    assert_redirected_to df
    df.reload
    assert df.can_download?(nil)
  end

  test 'gatekeeper reject' do
    gatekeeper = Factory(:gatekeeper)
    df = Factory(:data_file, :project_ids => gatekeeper.projects.collect(&:id))
    policy = df.policy
    df.resource_publish_logs.create(:publish_state=>ResourcePublishLog::WAITING_FOR_APPROVAL,:culprit=>df.contributor)

    login_as(gatekeeper.user)
    #send feedback email to requester
    assert_difference("ResourcePublishLog.count",1) do
      assert_emails 1 do
        post :gatekeeper_decide, :id => df.id, :gatekeeper_decision => 0, :extra_comment => 'not ready'
      end
    end

    assert_redirected_to df
    df.reload
    assert !df.can_download?(nil)
    assert_equal policy, df.policy

    log= ResourcePublishLog.last
    assert_equal ResourcePublishLog::REJECTED, log.publish_state
    assert_equal 'not ready', log.comment
  end
end