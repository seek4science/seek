require 'test_helper'

class GatekeeperPublishTest < ActionController::TestCase
  tests PeopleController

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(Factory(:user))
    @current_person = User.current_user.person
    @gatekeeper = Factory(:asset_gatekeeper)
  end

  test 'only gatekeeper can see -Waiting approval assets- button on their profile' do
    get :show, id: @current_person
    assert_response :success
    assert_select 'a', text: /Assets you are Gatekeeping/, count: 0

    get :show, id: @gatekeeper
    assert_response :success
    assert_select 'a', text: /Assets you are Gatekeeping/, count: 0

    logout
    login_as(@gatekeeper.user)
    get :show, id: @gatekeeper
    assert_response :success

    assert_select 'a[href=?]', requested_approval_assets_person_path(@gatekeeper), text: /Assets you are Gatekeeping/, count: 1
  end

  test 'gatekeeper authorization for requested_approval_assets' do
    get :requested_approval_assets, id: @current_person
    assert_redirected_to :root
    assert_not_nil flash[:error]

    flash[:error] = nil
    logout
    login_as(@gatekeeper.user)
    get :requested_approval_assets, id: @gatekeeper
    assert_response :success
    assert_nil flash[:error]
  end

  test 'gatekeeper authorization for gatekeeper_decide' do
    post :gatekeeper_decide, id: @current_person
    assert_redirected_to :root
    assert_not_nil flash[:error]

    flash[:error] = nil
    logout
    login_as(@gatekeeper.user)
    post :gatekeeper_decide, id: @gatekeeper
    assert_response :success
    assert_nil flash[:error]
  end

  test 'requested_approval_assets' do
    login_as(@gatekeeper.user)

    assert ResourcePublishLog.requested_approval_assets_for(@gatekeeper).empty?
    get :requested_approval_assets, id: @gatekeeper
    assert_select 'span[class=?]', 'none_text', text: 'There are no items waiting for your approval'

    user = Factory(:user)
    df = Factory(:data_file, projects: @gatekeeper.projects)
    model = Factory(:model, projects: @gatekeeper.projects)
    sop = Factory(:sop, projects: @gatekeeper.projects)
    ResourcePublishLog.add_log(ResourcePublishLog::WAITING_FOR_APPROVAL, df, nil, user)
    ResourcePublishLog.add_log(ResourcePublishLog::WAITING_FOR_APPROVAL, model, nil, user)
    ResourcePublishLog.add_log(ResourcePublishLog::WAITING_FOR_APPROVAL, sop, nil, user)

    requested_approval_assets = ResourcePublishLog.requested_approval_assets_for(@gatekeeper)
    assert_equal 3, requested_approval_assets.count

    get :requested_approval_assets, id: @gatekeeper

    assert_select '.type_and_title', count: 3 do
      assert_select 'a[href=?]', data_file_path(df)
      assert_select 'a[href=?]', model_path(model)
      assert_select 'a[href=?]', sop_path(sop)
    end

    assert_select '.request_info', count: 3 do
      assert_select 'a[href=?]', person_path(user.person), count: 3
    end

    assert_select '.btn-group', count: 3 do
      [df, model, sop].each do |asset|
        assert_select 'input[type=radio][name=?][value=?]', "gatekeeper_decide[#{asset.class.name}][#{asset.id}][decision]", '1'
        assert_select 'input[type=radio][name=?][value=?]', "gatekeeper_decide[#{asset.class.name}][#{asset.id}][decision]", '0'
        assert_select 'input[type=radio][name=?][value=?][checked=?]', "gatekeeper_decide[#{asset.class.name}][#{asset.id}][decision]", '-1', 'checked'
      end
    end

    [df, model, sop].each do |asset|
      assert_select 'textarea[name=?]', "gatekeeper_decide[#{asset.class.name}][#{asset.id}][comment]"
    end
  end

  test 'gatekeeper decide' do
    df, model, sop = requested_approval_assets_for @gatekeeper
    params = params_for df, model, sop
    login_as(@gatekeeper.user)

    assert_difference('ResourcePublishLog.count', 2) do
      assert_emails 2 do
        post :gatekeeper_decide, params.merge(id: @gatekeeper.id)
      end
    end

    assert_response :success

    df.reload
    assert df.can_download?(nil)
    model.reload
    assert !model.can_download?(nil)
    sop.reload
    assert !sop.can_download?(nil)

    approved_log = ResourcePublishLog.where(['publish_state=?', ResourcePublishLog::PUBLISHED]).last
    assert_equal 'ready', approved_log.comment

    rejected_log = ResourcePublishLog.where(['publish_state=?', ResourcePublishLog::REJECTED]).last
    assert_equal 'not ready', rejected_log.comment
  end

  test 'only allow gatekeeper_decide the authorized items' do
    params = { gatekeeper_decide: {} }
    unauthorized_df = Factory(:data_file)
    unauthorized_model = Factory(:model)
    params[:gatekeeper_decide][unauthorized_df.class.name] ||= {}
    params[:gatekeeper_decide][unauthorized_df.class.name][unauthorized_df.id.to_s] ||= {}
    params[:gatekeeper_decide][unauthorized_df.class.name][unauthorized_df.id.to_s]['decision'] = 1
    params[:gatekeeper_decide][unauthorized_model.class.name] ||= {}
    params[:gatekeeper_decide][unauthorized_model.class.name][unauthorized_model.id.to_s] ||= {}
    params[:gatekeeper_decide][unauthorized_model.class.name][unauthorized_model.id.to_s]['decision'] = 0

    login_as(@gatekeeper.user)

    assert_no_difference('ResourcePublishLog.count') do
      assert_emails 0 do
        post :gatekeeper_decide, params.merge(id: @gatekeeper.id)
      end
    end

    assert_response :success
    unauthorized_df.reload
    assert !unauthorized_df.can_download?(nil)

    unauthorized_model.reload
    assert !unauthorized_model.can_download?(nil)
    logs = ResourcePublishLog.where(['publish_state=? AND resource_type=? AND resource_id=?',
                                     ResourcePublishLog::REJECTED, 'Model', unauthorized_model.id])
    assert logs.empty?
  end

  test 'gatekeeper_decision_result' do
    df, model, sop = requested_approval_assets_for @gatekeeper
    params = params_for df, model, sop

    login_as(@gatekeeper.user)

    post :gatekeeper_decide, params.merge(id: @gatekeeper.id)

    assert_response :success
    assert_select 'ul#published' do
      assert_select 'li', text: /#{I18n.t('data_file')}: #{df.title}/, count: 1
    end
    assert_select 'ul#rejected' do
      assert_select 'li', text: /#{I18n.t('model')}: #{model.title}/, count: 1
    end
    assert_select 'ul#decide_later' do
      assert_select 'li', text: /#{I18n.t('sop')}: #{sop.title}/, count: 1
    end
    assert_select 'ul#problematic', count: 0
  end

  private

  def requested_approval_assets_for(gatekeeper)
    df = Factory(:data_file, project_ids: gatekeeper.projects.collect(&:id))
    df.resource_publish_logs.create(publish_state: ResourcePublishLog::WAITING_FOR_APPROVAL, user: df.contributor.user)
    model = Factory(:model, project_ids: gatekeeper.projects.collect(&:id))
    model.resource_publish_logs.create(publish_state: ResourcePublishLog::WAITING_FOR_APPROVAL, user: model.contributor.user)
    sop = Factory(:sop, project_ids: gatekeeper.projects.collect(&:id))
    sop.resource_publish_logs.create(publish_state: ResourcePublishLog::WAITING_FOR_APPROVAL, user: sop.contributor.user)
    assert !df.can_download?(nil)
    assert !model.can_download?(nil)
    assert !sop.can_download?(nil)
    [df, model, sop]
  end

  def params_for(df, model, sop)
    params = { gatekeeper_decide: {} }
    params[:gatekeeper_decide][df.class.name] ||= {}
    params[:gatekeeper_decide][df.class.name][df.id.to_s] ||= {}
    params[:gatekeeper_decide][df.class.name][df.id.to_s]['decision'] = 1
    params[:gatekeeper_decide][df.class.name][df.id.to_s]['comment'] = 'ready'
    params[:gatekeeper_decide][model.class.name] ||= {}
    params[:gatekeeper_decide][model.class.name][model.id.to_s] ||= {}
    params[:gatekeeper_decide][model.class.name][model.id.to_s]['decision'] = 0
    params[:gatekeeper_decide][model.class.name][model.id.to_s]['comment'] = 'not ready'
    params[:gatekeeper_decide][sop.class.name] ||= {}
    params[:gatekeeper_decide][sop.class.name][sop.id.to_s] ||= {}
    params[:gatekeeper_decide][sop.class.name][sop.id.to_s]['decision'] = -1
    params
  end
end
