require 'test_helper'

class GatekeeperPublishTest < ActionController::TestCase
  tests PeopleController

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(FactoryBot.create(:user))
    @current_person = User.current_user.person
    @gatekeeper = FactoryBot.create(:asset_gatekeeper)
  end

  test 'only gatekeeper can see -Waiting approval assets- button on their profile' do
    get :show, params: { id: @current_person }
    assert_response :success
    assert_select 'a', text: /Assets you are Gatekeeping/, count: 0

    get :show, params: { id: @gatekeeper }
    assert_response :success
    assert_select 'a', text: /Assets you are Gatekeeping/, count: 0

    logout
    login_as(@gatekeeper.user)
    get :show, params: { id: @gatekeeper }
    assert_response :success

    assert_select 'a[href=?]', requested_approval_assets_person_path(@gatekeeper), text: /Assets you are Gatekeeping/, count: 1
  end

  test 'gatekeeper authorization for requested_approval_assets' do
    get :requested_approval_assets, params: { id: @current_person }
    assert_redirected_to :root
    assert_not_nil flash[:error]

    clear_flash(:error)
    logout
    login_as(@gatekeeper.user)
    get :requested_approval_assets, params: { id: @gatekeeper }
    assert_response :success
    assert_nil flash[:error]
  end

  test 'gatekeeper authorization for gatekeeper_decide' do
    post :gatekeeper_decide, params: { id: @current_person }
    assert_redirected_to :root
    assert_not_nil flash[:error]

    clear_flash(:error)
    logout
    login_as(@gatekeeper.user)
    post :gatekeeper_decide, params: { id: @gatekeeper }
    assert_response :success
    assert_nil flash[:error]
  end

  test 'requested_approval_assets' do
    login_as(@gatekeeper.user)

    assert ResourcePublishLog.requested_approval_assets_for_gatekeeper(@gatekeeper).empty?
    get :requested_approval_assets, params: { id: @gatekeeper }
    assert_select 'span[class=?]', 'none_text', text: 'There are no items waiting for your approval'

    user = FactoryBot.create(:user)
    df = FactoryBot.create(:data_file, projects: @gatekeeper.projects)
    model = FactoryBot.create(:model, projects: @gatekeeper.projects)
    sop = FactoryBot.create(:sop, projects: @gatekeeper.projects)
    dfr = FactoryBot.create(:data_file, projects: @gatekeeper.projects)
    ResourcePublishLog.add_log(ResourcePublishLog::WAITING_FOR_APPROVAL, df, nil, user)
    ResourcePublishLog.add_log(ResourcePublishLog::WAITING_FOR_APPROVAL, model, nil, user)
    ResourcePublishLog.add_log(ResourcePublishLog::WAITING_FOR_APPROVAL, sop, nil, user)
    ResourcePublishLog.add_log(ResourcePublishLog::WAITING_FOR_APPROVAL, dfr, nil, user)
    ResourcePublishLog.add_log(ResourcePublishLog::REJECTED, dfr, "Because I say so", @gatekeeper.user)

    requested_approval_assets = ResourcePublishLog.requested_approval_assets_for_gatekeeper(@gatekeeper)
    assert_equal 4, requested_approval_assets.count

    get :requested_approval_assets, params: { id: @gatekeeper }

    #- Assets waiting for approval
    assert_select 'div.waiting_approval_items', count: 1 do
      assert_select '.type_and_title', count: 3 do
        assert_select 'a[href=?]', data_file_path(df)
        assert_select 'a[href=?]', model_path(model)
        assert_select 'a[href=?]', sop_path(sop)
      end
      assert_select '.request_info', count: 3 do
        assert_select 'a[href=?]', person_path(user.person), count: 3
      end
    end

    assert_select '.radio-inline', count: 9 do
      [df, model, sop].each do |asset|
        assert_select 'input[type=radio][name=?][value=?]', "gatekeeper_decide[#{asset.class.name}][#{asset.id}][decision]", '1'
        assert_select 'input[type=radio][name=?][value=?]', "gatekeeper_decide[#{asset.class.name}][#{asset.id}][decision]", '0'
        assert_select 'input[type=radio][name=?][value=?][checked=?]', "gatekeeper_decide[#{asset.class.name}][#{asset.id}][decision]", '-1', 'checked'
      end
    end

    [df, model, sop].each do |asset|
      assert_select 'textarea[name=?]', "gatekeeper_decide[#{asset.class.name}][#{asset.id}][comment]"
    end

    # Rejected assets
    assert_select 'a.rejected_items[style=?]', "display:block;", count: 1
    assert_select 'a.rejected_items[style=?]', "display:none;", count: 1
    assert_select 'div.rejected_items[style=?]', "display:none;", count: 1 do
      assert_select '.type_and_title', count: 1 do
        assert_select 'a[href=?]', data_file_path(dfr)
      end
      assert_select '.request_info', { count: 1, text: /Rejected on:.*Comments: Because I say so/m} do
        assert_select 'a[href=?]', person_path(user.person), count: 1
      end
    end
  end

  test 'gatekeeper decide' do
    df, model, sop = requested_approval_assets_for @gatekeeper

    assert df.is_waiting_approval?
    assert df.is_waiting_approval?(df.contributor.user)
    assert model.is_waiting_approval?
    assert model.is_waiting_approval?(model.contributor.user)
    assert sop.is_waiting_approval?
    assert sop.is_waiting_approval?(sop.contributor.user)

    params = params_for df, model, sop
    login_as(@gatekeeper.user)

    # the gatekeeper approved the data file to publish, rejected the model and decided sop later
    assert_difference('ResourcePublishLog.count', 2) do
      assert_enqueued_emails 2 do
        post :gatekeeper_decide, params: params.merge(id: @gatekeeper.id)
      end
    end

    assert_response :success

    df.reload
    assert df.can_download?(nil)
    assert df.is_published?
    refute df.is_rejected?
    refute df.is_waiting_approval?(df.contributor.user)
    refute df.is_waiting_approval?
    refute df.can_publish?

    model.reload
    assert !model.can_download?(nil)
    refute model.is_published?
    assert model.is_rejected?
    refute model.is_waiting_approval?(model.contributor.user)
    refute model.is_waiting_approval?
    refute model.can_publish?

    sop.reload
    assert !sop.can_download?(nil)
    refute sop.is_published?
    refute sop.is_rejected?
    assert sop.is_waiting_approval?
    assert sop.is_waiting_approval?(sop.contributor.user)
    assert sop.can_publish?

    approved_log = ResourcePublishLog.where(['publish_state=?', ResourcePublishLog::PUBLISHED]).last
    assert_equal 'ready', approved_log.comment

    rejected_log = ResourcePublishLog.where(['publish_state=?', ResourcePublishLog::REJECTED]).last
    assert_equal 'not ready', rejected_log.comment

    # the user updated the model after it was rejected by the gatekeeper
    login_as(model.contributor.user)

    model.title = 'new title'
    model.save

    assert model.is_rejected?
    assert model.is_updated_since_be_rejected?
    assert model.can_publish?

    model.resource_publish_logs.create(publish_state: ResourcePublishLog::WAITING_FOR_APPROVAL, user: model.contributor.user)
    assert model.is_waiting_approval?
    assert model.is_waiting_approval?(model.contributor.user)

    # the gatekeeper approve the model to publish
    params = { gatekeeper_decide: {} }
    params[:gatekeeper_decide][model.class.name] ||= {}
    params[:gatekeeper_decide][model.class.name][model.id.to_s] ||= {}
    params[:gatekeeper_decide][model.class.name][model.id.to_s]['decision'] = 1
    params[:gatekeeper_decide][model.class.name][model.id.to_s]['comment'] = 'ready'

    login_as(@gatekeeper.user)

    assert_difference('ResourcePublishLog.count', 1) do
      assert_enqueued_emails 1 do
        post :gatekeeper_decide, params: params.merge(id: @gatekeeper.id)
      end
    end

    assert_response :success

    model.reload
    assert model.can_download?(nil)
    assert model.is_published?
    refute model.is_rejected?
    refute model.is_waiting_approval?(model.contributor.user)
    refute model.is_waiting_approval?
    refute model.can_publish?

  end

  test 'only allow gatekeeper_decide the authorized items' do
    params = { gatekeeper_decide: {} }
    unauthorized_df = FactoryBot.create(:data_file)
    unauthorized_model = FactoryBot.create(:model)
    params[:gatekeeper_decide][unauthorized_df.class.name] ||= {}
    params[:gatekeeper_decide][unauthorized_df.class.name][unauthorized_df.id.to_s] ||= {}
    params[:gatekeeper_decide][unauthorized_df.class.name][unauthorized_df.id.to_s]['decision'] = 1
    params[:gatekeeper_decide][unauthorized_model.class.name] ||= {}
    params[:gatekeeper_decide][unauthorized_model.class.name][unauthorized_model.id.to_s] ||= {}
    params[:gatekeeper_decide][unauthorized_model.class.name][unauthorized_model.id.to_s]['decision'] = 0

    login_as(@gatekeeper.user)

    assert_no_difference('ResourcePublishLog.count') do
      assert_no_enqueued_emails do
        post :gatekeeper_decide, params: params.merge(id: @gatekeeper.id)
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

    post :gatekeeper_decide, params: params.merge(id: @gatekeeper.id)

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
    df = FactoryBot.create(:data_file, project_ids: gatekeeper.projects.collect(&:id))
    df.resource_publish_logs.create(publish_state: ResourcePublishLog::WAITING_FOR_APPROVAL, user: df.contributor.user)
    model = FactoryBot.create(:model, project_ids: gatekeeper.projects.collect(&:id))
    model.resource_publish_logs.create(publish_state: ResourcePublishLog::WAITING_FOR_APPROVAL, user: model.contributor.user)
    sop = FactoryBot.create(:sop, project_ids: gatekeeper.projects.collect(&:id))
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
