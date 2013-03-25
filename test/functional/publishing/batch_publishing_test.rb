require 'test_helper'

class BatchPublishingTest < ActionController::TestCase

  tests PeopleController

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:aaron)
  end

  test "should have the -Publish all your assets- only one your own profile" do
    get :show, :id => User.current_user.person
    assert_response :success
    assert_select "a[href=?]", batch_publishing_preview_person_path, :text => /Publish all your assets/

    get :batch_publishing_preview, :id => User.current_user.person.id
    assert_response :success
    assert_nil flash[:error]

    #not yourself
    a_person = Factory(:person)
    get :show, :id => a_person
    assert_response :success
    assert_select "a", :text => /Publish all your assets/, :count => 0

    get :batch_publishing_preview, :id => a_person.id
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test "get batch_publishing_preview" do
    #bundle of assets that can publish immediately
    publish_immediately_assets = can_publish_immediately_assets
    publish_immediately_assets.each do |a|
      assert a.can_publish?,"The asset must be publishable immediately for this test to succeed"
    end
    #bundle of assets that can not publish immediately but can send the publish request
    send_request_assets = can_send_request_assets
    send_request_assets.each do |a|
      assert !a.can_publish?,"The asset must not be publishable immediately for this test to succeed"
      assert a.can_send_publishing_request?,"The publish request for this asset must be able to be sent for this test to succeed"
    end
    total_asset_count = (publish_immediately_assets + send_request_assets).count

    get :batch_publishing_preview, :id => User.current_user.person.id
    assert_response :success

    assert_select "li.type_and_title", :count=>total_asset_count do
      publish_immediately_assets.each do |a|
        assert_select "a[href=?]",eval("#{a.class.name.underscore}_path(#{a.id})"),:text=>/#{a.title}/

      end
      send_request_assets.each do |a|
        assert_select "a[href=?]",eval("#{a.class.name.underscore}_path(#{a.id})"),:text=>/#{a.title}/
      end
      assert_select "li.type_and_title img[src*=?][title=?]",/lock.png/, /Private/, :count => total_asset_count
    end

    assert_select "li.secondary", :text => /Publish/, :count => publish_immediately_assets.count
    publish_immediately_assets.each do |a|
      assert_select "input[checked='checked'][type='checkbox'][id=?]", "publish_#{a.class.name}_#{a.id}"
    end

    assert_select "li.secondary", :text => /Submit publishing request/, :count => send_request_assets.count
    send_request_assets.each do |a|
      assert_select "input[checked='checked'][type='checkbox'][id=?]", "publish_#{a.class.name}_#{a.id}"
    end
  end

  test "do not have published items in batch_publishing_preview" do
    published_item = Factory(:data_file,
                             :contributor=> User.current_user,
                             :policy => Factory(:public_policy))
    assert published_item.is_published?, "This data file must be published for the test to succeed"
    assert published_item.can_publish?, "This data file must be publishable for the test to be meaningful"

    get :batch_publishing_preview, :id => User.current_user.person.id
    assert_response :success

    assert_select "input[checked='checked'][type='checkbox'][id=?]", "publish_#{published_item.class.name}_#{published_item.id}",
                  :count => 0
  end

  test "do not have not_publish_authorized items in batch_publishing_preview" do
    item = Factory(:data_file, :policy => Factory(:all_sysmo_viewable_policy))
    assert !item.can_publish?, "This data file must not be publishable for the test to succeed"
    assert !item.can_send_publishing_request?, "The publishing request must not be able to send for the test to succeed"
    assert !item.is_published?, "This data file must not be published for the test to be meaningful"

    get :batch_publishing_preview, :id => User.current_user.person.id
    assert_response :success

    assert_select "input[checked='checked'][type='checkbox'][id=?]", "publish_#{item.class.name}_#{item.id}",
                  :count => 0
  end

  test "do not have not_publishable_type item in batch_publishing_preview" do
    item = Factory(:sample, :contributor => User.current_user)
    assert item.can_publish?, "This data file must be publishable for the test to be meaningful"
    assert !item.is_published?, "This data file must not be published for the test to be meaningful"

    get :batch_publishing_preview, :id => User.current_user.person.id
    assert_response :success

    assert_select "input[checked='checked'][type='checkbox'][id=?]", "publish_#{item.class.name}_#{item.id}",
                  :count => 0
  end

  test "do publish" do
    #bundle of assets that can publish immediately
    publish_immediately_assets = can_publish_immediately_assets
    publish_immediately_assets.each do |a|
      assert !a.is_published?,"The asset must not be published for this test to succeed"
      assert a.can_publish?,"The asset must be publishable immediately for this test to succeed"
    end
    #bundle of assets that can not publish immediately but can send the publish request
    send_request_assets = can_send_request_assets
    send_request_assets.each do |a|
      assert !a.can_publish?,"The asset must not be publishable immediately for this test to succeed"
      assert a.can_send_publishing_request?,"The publish request for this asset must be able to be sent for this test to succeed"
    end

    total_assets = publish_immediately_assets + send_request_assets

    params={:publish=>{}}

    total_assets.each do |asset|
      params[:publish][asset.class.name]||={}
      params[:publish][asset.class.name][asset.id.to_s]="1"
    end

    assert_difference("ResourcePublishLog.count", total_assets.count) do
      assert_emails send_request_assets.count do
        post :publish, params.merge(:id=> User.current_user.person.id)
      end
    end
    assert_response :success
    assert_nil flash[:error]
    assert_not_nil flash[:notice]

    publish_immediately_assets.each do |a|
      a.reload
      assert a.is_published?
    end
    send_request_assets.each do |a|
      a.reload
      assert !a.is_published?
    end
  end

  test "do not publish for already published items" do
    published_item = Factory(:data_file,
                             :contributor=> User.current_user,
                             :policy => Factory(:public_policy))
    assert published_item.is_published?, "This data file must be published for the test to succeed"
    assert published_item.can_publish?, "This data file must be publishable for the test to be meaningful"

    params={:publish=>{}}
    params[:publish][published_item.class.name]||={}
    params[:publish][published_item.class.name][published_item.id.to_s]="1"


    assert_no_difference("ResourcePublishLog.count") do
      assert_emails 0 do
        post :publish, params.merge(:id=> User.current_user.person.id)
      end
    end
    assert_response :success
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
  end

  test "get publish redirected" do
    #This is useful because if you logout it redirects to root.
    #If you just published something, that will do a get request to *Controller#publish
    get :publish, :id=> User.current_user.person.id
    assert_response :redirect
  end

  private

  def can_publish_immediately_assets
    publishable_types = Seek::Util.authorized_types.select {|c| c.first.try(:is_in_isa_publishable?)}
    publishable_types.collect do |klass|
      Factory(klass.name.underscore.to_sym, :contributor => User.current_user)
    end
  end

  def can_send_request_assets
    publishable_types = Seek::Util.authorized_types.select {|c| c.first.try(:is_in_isa_publishable?)}
    publishable_types.collect do |klass|
      Factory(klass.name.underscore.to_sym, :contributor => User.current_user, :projects => Factory(:gatekeeper).projects)
    end
  end
end

