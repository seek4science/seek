require 'test_helper'

class GatekeeperPublishTest < ActionController::TestCase

  tests PeopleController

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(Factory(:user))
    @current_person = User.current_user.person
    @gatekeeper = Factory(:gatekeeper)
  end

  test 'only gatekeeper can see -Waiting approval assets- button on their profile' do
    get :show, :id => @current_person
    assert_response :success
    assert_select "a", :text => /Waiting approval assets/, :count => 0

    get :show, :id => @gatekeeper
    assert_response :success
    assert_select "a", :text => /Waiting approval assets/, :count => 0

    logout
    login_as(@gatekeeper.user)
    get :show, :id => @gatekeeper
    assert_response :success
    assert_select "a[href=?]", requested_approval_assets_person_path(@gatekeeper), :text => /Waiting approval assets/, :count => 1
  end

  test 'gatekeeper authorization for requested_approval_assets' do
    get :requested_approval_assets, :id => @current_person
    assert_redirected_to :root
    assert_not_nil flash[:error]

    flash[:error] = nil
    logout
    login_as(@gatekeeper.user)
    get :requested_approval_assets, :id => @gatekeeper
    assert_response :success
    assert_nil flash[:error]
  end

  test 'gatekeeper authorization for gatekeeper_decide' do
    post :gatekeeper_decide, :id => @current_person
    assert_redirected_to :root
    assert_not_nil flash[:error]

    flash[:error] = nil
    logout
    login_as(@gatekeeper.user)
    post :gatekeeper_decide, :id => @gatekeeper
    assert_response :success
    assert_nil flash[:error]
  end

  test 'requested_approval_assets' do
    login_as(@gatekeeper.user)

    assert ResourcePublishLog.requested_approval_assets_for(@gatekeeper).empty?
    get :requested_approval_assets, :id => @gatekeeper
    assert_select "span", :text => "You have no assets waiting for your approval"

    df = Factory(:data_file, :projects => @gatekeeper.projects)
    model = Factory(:model, :projects => @gatekeeper.projects)
    sop = Factory(:sop, :projects => @gatekeeper.projects)
    ResourcePublishLog.add_log(ResourcePublishLog::WAITING_FOR_APPROVAL, df)
    ResourcePublishLog.add_log(ResourcePublishLog::WAITING_FOR_APPROVAL, model)
    ResourcePublishLog.add_log(ResourcePublishLog::WAITING_FOR_APPROVAL, sop)

    requested_approval_assets = ResourcePublishLog.requested_approval_assets_for(@gatekeeper)
    assert_equal 3, requested_approval_assets.count

    get :requested_approval_assets, :id => @gatekeeper

    assert_select "div.list_item_title", :count => 3 do
      assert_select "a[href=?]", data_file_path(df)
      assert_select "a[href=?]", model_path(model)
      assert_select "a[href=?]", sop_path(sop)
    end
    assert_select "div.radio_buttons", :count => 3 do
      [df, model, sop].each do |asset|
        assert_select "input[type=radio][name=?][value=?]", "gatekeeper_decide[#{asset.class.name}][#{asset.id}][decision]", 1
        assert_select "input[type=radio][name=?][value=?]", "gatekeeper_decide[#{asset.class.name}][#{asset.id}][decision]", 0
        assert_select "input[type=radio][name=?][value=?]", "gatekeeper_decide[#{asset.class.name}][#{asset.id}][decision]", -1
      end
    end

    [df, model, sop].each do |asset|
      assert_select "div#comment_#{asset.class.name}_#{asset.id}" do
        assert_select "textarea[name=?]", "gatekeeper_decide[#{asset.class.name}][#{asset.id}][comment]"
      end
    end
  end

  test 'gatekeeper decide' do
    df,model,sop = requested_approval_assets_for @gatekeeper
    params = params_for df, model, sop
    login_as(@gatekeeper.user)

    assert_difference("ResourcePublishLog.count",2) do
      #FIXME:fix email
      #assert_emails 2 do
        post :gatekeeper_decide, params.merge(:id=> @gatekeeper.id)
      #end
    end

    assert_response :success

    df.reload
    assert df.can_download?(nil)
    model.reload
    assert !model.can_download?(nil)
    sop.reload
    assert !sop.can_download?(nil)

    log= ResourcePublishLog.last
    assert_equal ResourcePublishLog::REJECTED, log.publish_state
    assert_equal 'not ready', log.comment
  end

  test "gatekeeper_decision_result" do
    df,model,sop = requested_approval_assets_for @gatekeeper
    params = params_for df, model, sop

    login_as(@gatekeeper.user)

    post :gatekeeper_decide, params.merge(:id=> @gatekeeper.id)

    assert_response :success
    assert_select "ul#published" do
      assert_select "li",:text=>/#{I18n.t('data_file')}: #{df.title}/,:count=>1
    end
    assert_select "ul#rejected" do
      assert_select "li",:text=>/#{I18n.t('model')}: #{model.title}/,:count=>1
    end
    assert_select "ul#decide_later" do
      assert_select "li",:text=>/#{I18n.t('sop')}: #{sop.title}/,:count=>1
    end
    assert_select "ul#problematic", :count => 0
  end

  private

  def requested_approval_assets_for gatekeeper
    df = Factory(:data_file, :project_ids => gatekeeper.projects.collect(&:id))
    df.resource_publish_logs.create(:publish_state=>ResourcePublishLog::WAITING_FOR_APPROVAL,:culprit=>df.contributor)
    model = Factory(:model, :project_ids => gatekeeper.projects.collect(&:id))
    model.resource_publish_logs.create(:publish_state=>ResourcePublishLog::WAITING_FOR_APPROVAL,:culprit=>model.contributor)
    sop = Factory(:sop, :project_ids => gatekeeper.projects.collect(&:id))
    sop.resource_publish_logs.create(:publish_state=>ResourcePublishLog::WAITING_FOR_APPROVAL,:culprit=>sop.contributor)
    assert !df.can_download?(nil)
    assert !model.can_download?(nil)
    assert !sop.can_download?(nil)
    [df,model,sop]
  end

  def params_for df,model,sop
    params = {:gatekeeper_decide=>{}}
    params[:gatekeeper_decide][df.class.name]||={}
    params[:gatekeeper_decide][df.class.name][df.id.to_s]||={}
    params[:gatekeeper_decide][df.class.name][df.id.to_s]['decision']=1
    params[:gatekeeper_decide][model.class.name]||={}
    params[:gatekeeper_decide][model.class.name][model.id.to_s]||={}
    params[:gatekeeper_decide][model.class.name][model.id.to_s]['decision']=0
    params[:gatekeeper_decide][model.class.name][model.id.to_s]['comment']="not ready"
    params[:gatekeeper_decide][sop.class.name]||={}
    params[:gatekeeper_decide][sop.class.name][sop.id.to_s]||={}
    params[:gatekeeper_decide][sop.class.name][sop.id.to_s]['decision']=-1
    params
  end
end