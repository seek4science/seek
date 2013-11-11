require 'test_helper'

class LogPublishingTest < ActionController::TestCase

  tests DataFilesController

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:datafile_owner)
    @object=data_files(:picture)
  end

  test 'log when creating the public item' do
    @controller = SopsController.new()
    sop_params = valid_sop
    sop_params[:project_ids] = [projects(:three).id] #this project has no gatekeeper
    assert_difference ('ResourcePublishLog.count') do
      post :create, :sop => sop_params, :sharing => public_sharing
    end
    publish_log = ResourcePublishLog.last
    assert_equal ResourcePublishLog::PUBLISHED, publish_log.publish_state.to_i
    sop = assigns(:sop)
    assert_equal sop, publish_log.resource
    assert_equal sop.contributor, publish_log.culprit
  end

  test 'log when creating item and request publish it' do
    @controller = SopsController.new()
    assert_difference ('ResourcePublishLog.count') do
      post :create, :sop => valid_sop, :sharing => {:sharing_scope => Policy::EVERYONE, "access_type_#{Policy::EVERYONE}" => Policy::VISIBLE}
    end
    publish_log = ResourcePublishLog.last
    assert_equal ResourcePublishLog::WAITING_FOR_APPROVAL, publish_log.publish_state.to_i
    sop = assigns(:sop)
    assert_equal sop, publish_log.resource
    assert_equal sop.contributor, publish_log.culprit
  end

  test 'dont log when creating the non-public item' do
    @controller = SopsController.new()
    assert_no_difference ('ResourcePublishLog.count') do
      post :create, :sop => valid_sop
    end

    assert_not_equal Policy::EVERYONE, assigns(:sop).policy.sharing_scope
  end

  test 'log when updating an item from non-public to public' do
    @controller = SopsController.new()
    login_as(:owner_of_my_first_sop)

    sop = sops(:sop_with_project_without_gatekeeper)
    assert_not_equal Policy::EVERYONE, sop.policy.sharing_scope
    assert sop.can_publish?

    assert_difference ('ResourcePublishLog.count') do
      put :update, :id => sop.id, :sharing => public_sharing
    end
    publish_log = ResourcePublishLog.last
    assert_equal ResourcePublishLog::PUBLISHED, publish_log.publish_state.to_i
    sop = assigns(:sop)
    assert_equal sop, publish_log.resource
    assert_equal sop.contributor, publish_log.culprit
  end

  test 'log when sending the publish request approval during updating a non-public item' do
    @controller = SopsController.new()
    login_as(:owner_of_my_first_sop)

    sop = sops(:my_first_sop)
    assert_not_equal Policy::EVERYONE, sop.policy.sharing_scope
    assert sop.can_publish?

    assert_difference ('ResourcePublishLog.count') do
      put :update, :id => sop.id, :sharing => {:sharing_scope => Policy::EVERYONE, "access_type_#{Policy::EVERYONE}" => Policy::VISIBLE}
    end
    publish_log = ResourcePublishLog.last
    assert_equal ResourcePublishLog::WAITING_FOR_APPROVAL, publish_log.publish_state.to_i
    sop = assigns(:sop)
    assert_equal sop, publish_log.resource
    assert_equal sop.contributor, publish_log.culprit
  end

  test 'dont log when updating an item with the not-related public sharing' do
    @controller = SopsController.new()
    login_as(:owner_of_my_first_sop)
    sop = sops(:my_first_sop)
    assert_not_equal Policy::EVERYONE, sop.policy.sharing_scope

    assert_no_difference ('ResourcePublishLog.count') do
      put :update, :id => sop.id, :sharing => {:sharing_scope => Policy::PRIVATE, "access_type_#{Policy::PRIVATE}" => Policy::NO_ACCESS}
    end
  end

  test 'log when un-publishing an item' do
    @controller = SopsController.new()
    login_as(:owner_of_fully_public_policy)

    sop = sops(:sop_with_fully_public_policy)
    assert_equal Policy::EVERYONE, sop.policy.sharing_scope

    #create a published log for the published sop
    ResourcePublishLog.create(:resource => sop, :culprit => User.current_user, :publish_state => ResourcePublishLog::PUBLISHED)

    assert_difference ('ResourcePublishLog.count') do
      put :update, :id => sop.id, :sharing => {:sharing_scope => Policy::PRIVATE, "access_type_#{Policy::PRIVATE}" => Policy::NO_ACCESS}
    end
    publish_log = ResourcePublishLog.last
    assert_equal ResourcePublishLog::UNPUBLISHED, publish_log.publish_state.to_i
    sop = assigns(:sop)
    assert_equal sop, publish_log.resource
    assert_equal sop.contributor, publish_log.culprit
  end

  test 'log when approving publishing an item' do
    gatekeeper = Factory(:gatekeeper)
    df = Factory(:data_file, :project_ids => gatekeeper.projects.collect(&:id))

    login_as(df.contributor)
    put :update, :id => df.id, :sharing => {:sharing_scope => Policy::EVERYONE, "access_type_#{Policy::EVERYONE}" => Policy::VISIBLE}

    logout

    login_as(gatekeeper.user)
    assert_difference ('ResourcePublishLog.count') do
      post :gatekeeper_decide, :id => df.id, :gatekeeper_decision => 1
    end

    publish_log = ResourcePublishLog.last
    assert_equal ResourcePublishLog::PUBLISHED, publish_log.publish_state.to_i
    df = assigns(:data_file)
    assert_equal df, publish_log.resource
    assert_equal gatekeeper.user, publish_log.culprit
  end

  test 'log when publish isa' do
    df=Factory :data_file,
               :contributor=>users(:datafile_owner),
               :assays => [Factory(:assay)]

    assay=df.assays.first

    request_publishing_df = Factory(:data_file,
                                    :project_ids => Factory(:gatekeeper).projects.collect(&:id),
                                    :contributor => users(:datafile_owner),
                                    :assays => [assay])

    assert !df.is_published? ,"The datafile must be not be published for this test to succeed"
    assert df.can_publish?,"The datafile must be publishable for this test to succeed"
    assert !request_publishing_df.is_published?,"The datafile must be not be published for this test to succeed"
    assert request_publishing_df.can_publish?,"The datafile must be publishable for this test to succeed"

    params={:publish=>{}}
    params[:publish][df.class.name]||={}
    params[:publish][df.class.name][df.id.to_s]="1"
    params[:publish][request_publishing_df.class.name]||={}
    params[:publish][request_publishing_df.class.name][request_publishing_df.id.to_s]="1"

    assert_difference("ResourcePublishLog.count", 2) do
      post :publish,params.merge(:id=>df)
      a=1
    end
    assert_response :redirect

    log_for_df = ResourcePublishLog.last(:conditions => ["resource_type=? AND resource_id=?", "DataFile", df.id])
    assert_equal ResourcePublishLog::PUBLISHED, log_for_df.publish_state
    log_for_request_publishing_df = ResourcePublishLog.last(:conditions => ["resource_type=? AND resource_id=?", "DataFile", request_publishing_df.id])
    assert_equal ResourcePublishLog::WAITING_FOR_APPROVAL, log_for_request_publishing_df.publish_state
  end

  private

  def valid_sop
    {:title => "Test", :data => fixture_file_upload('files/file_picture.png'), :project_ids => [projects(:sysmo_project).id]}
  end

  def public_sharing
    {:sharing_scope => Policy::EVERYONE, "access_type_#{Policy::EVERYONE}" => Policy::ACCESSIBLE}
  end
end

