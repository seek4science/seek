require 'test_helper'

class SinglePublishingTest < ActionController::TestCase

  tests ModelsController

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:aaron)
  end

  test "do single_publish" do
    model=Factory(:model, :contributor => User.current_user)
    assert !model.is_published?,"The model must not be already published for this test to succeed"
    assert model.publish_authorized?,"The model must be publishable for this test to succeed"

    get :show,:id=>model
    assert_response :success
    assert_select "a[href=?]",single_publish_model_path, :text => /Publish Model/

    post :single_publish,:id=>model
    assert_redirected_to model
    assert_nil flash[:error]
    assert_not_nil flash[:notice]

    model.reload
    assert model.is_published?,"The model should be published after doing single_publish"
  end

  test "sending publishing request when doing single_publish for can_not_publish item" do
    model=Factory(:model, :contributor => User.current_user, :projects => Factory(:gatekeeper).projects)
    assert !model.can_publish?,"The model can not be published immediately for this test to succeed"
    assert model.can_manage?,"The model must be manageable for this test to succeed"
    assert ResourcePublishLog.last_waiting_approval_log(model).nil?,"The publishing request for this model must not be sent for this test to succeed"

    post :single_publish,:id=>model
    assert_redirected_to model
    assert_nil flash[:error]
    assert_not_nil flash[:notice]

    model.reload
    assert !model.is_published?,"The model should not be published after sending publishing request"
    assert !ResourcePublishLog.last_waiting_approval_log(model).nil?,"The publishing request for this model should be sent after requesting"
  end

  test "do not single_publish if the item is already published" do
    model=Factory(:model, :contributor => User.current_user, :policy => Factory(:public_policy))
    assert model.publish_authorized?,"The model must be publishable for this test to succeed"
    assert model.is_published?,"The model must be already published for this test to succeed"

    get :show,:id=>model
    assert_response :success
    assert_select "a", :text => /Publish Model/, :count => 0

    post :single_publish,:id=>model
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test "do not single_publish if can not manage" do
    model=Factory(:model, :policy => Factory(:all_sysmo_viewable_policy))
    assert !model.can_manage?,"The model must not be manageable for this test to succeed"

    get :show,:id=>model
    assert_response :success
    assert_select "a", :text => /Publish Model/, :count => 0

    post :single_publish,:id=>model
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test "do not single_publish if the publishing request was sent" do
    model=Factory(:model, :contributor => User.current_user, :projects => Factory(:gatekeeper).projects)
    ResourcePublishLog.add_publish_log(ResourcePublishLog::WAITING_FOR_APPROVAL, model)
    assert model.can_manage?,"The model must be manageable for this test to succeed"
    assert !ResourcePublishLog.last_waiting_approval_log(model).nil?,"The publishing request for this model must be already sent for this test to succeed"

    get :show,:id=>model
    assert_response :success
    assert_select "a", :text => /Publish Model/, :count => 0

    post :single_publish,:id=>model
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end
end