require 'test_helper'

class SinglePublishingTest < ActionController::TestCase
  tests DataFilesController

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:datafile_owner)
  end

  test 'should be able to do publish when publishable' do
    df = data_with_isa
    gatekeeper = Factory(:asset_gatekeeper)
    df.projects << gatekeeper.projects.first
    assert df.can_publish?, 'The data file must be manageable for this test to succeed'

    get :show, id: df
    assert_response :success
    assert_select 'a', text: /Publish #{I18n.t('data_file')}/

    get :check_related_items, id: df
    assert_response :success
    assert_nil flash[:error]

    get :publish_related_items, id: df
    assert_response :success
    assert_nil flash[:error]

    get :check_gatekeeper_required, id: df
    assert_response :success
    assert_nil flash[:error]

    post :publish, id: df
    assert_response :redirect
    assert_nil flash[:error]
  end

  test 'should not be able to do publish when not publishable' do
    df = Factory(:data_file, policy: Factory(:all_sysmo_viewable_policy))
    assert df.can_view?, 'The datafile must be viewable for this test to be meaningful'
    assert !df.can_publish?, 'The datafile must not be manageable for this test to succeed'

    get :show, id: df
    assert_response :success
    assert_select 'a', text: /Publish #{I18n.t('data_file')}/, count: 0

    get :check_related_items, id: df
    assert_redirected_to :root
    assert flash[:error]

    get :publish_related_items, id: df
    assert_redirected_to :root
    assert flash[:error]

    get :check_gatekeeper_required, id: df
    assert_redirected_to :root
    assert flash[:error]

    post :publish, id: df
    assert_redirected_to :root
    assert flash[:error]
  end

  test 'get check_related_items' do
    df = data_with_isa
    assert df.can_publish?, 'The datafile must be publishable for this test to succeed'

    get :check_related_items, id: df.id
    assert_response :success

    assert_select 'a[href=?]', data_file_path(df), text: /#{df.title}/
    assert_select 'div[style="display:none"]' do
      assert_select "input[type='checkbox'][checked='checked'][id=?]", "publish_DataFile_#{df.id}"
    end
  end

  test 'get publish_related_items' do
    df = data_with_isa
    assay = df.assays.first
    study = assay.study
    investigation = study.investigation

    notifying_df = assay.data_files.reject { |d| d == df }.first
    request_publishing_df = Factory(:data_file,
                                    project_ids: Factory(:asset_gatekeeper).projects.collect(&:id),
                                    contributor: users(:datafile_owner),
                                    assays: [assay])
    publishing_df = Factory(:data_file,
                            contributor: users(:datafile_owner),
                            assays: [assay])

    assert_not_nil assay, 'There should be an assay associated'
    assert df.can_publish?, 'The datafile must be publishable for this test to succeed'
    assert request_publishing_df.can_publish?, 'The datafile must not be publishable for this test to succeed'
    assert !notifying_df.can_publish?, 'The datafile must not be publishable for this test to succeed'

    get :publish_related_items, id: df.id
    assert_response :success

    assert_select '.type_and_title', text: /Investigation/, count: 1 do
      assert_select 'a[href=?]', investigation_path(investigation), text: /#{investigation.title}/
    end
    assert_select '.checkbox', text: /Publish/ do
      assert_select "input[type='checkbox'][id=?]", "publish_Investigation_#{investigation.id}"
    end

    assert_select '.type_and_title', text: /Study/, count: 1 do
      assert_select 'a[href=?]', study_path(study), text: /#{study.title}/
    end
    assert_select '.checkbox', text: /Publish/ do
      assert_select "input[type='checkbox'][id=?]", "publish_Study_#{study.id}"
    end

    assert_select '.type_and_title', text: /Assay/, count: 1 do
      assert_select 'a[href=?]', assay_path(assay), text: /#{assay.title}/
    end
    assert_select '.checkbox', text: /Publish/ do
      assert_select "input[type='checkbox'][id=?]", "publish_Assay_#{assay.id}"
    end

    assert_select '.type_and_title', text: /#{I18n.t('data_file')}/, count: 4 do
      assert_select 'a[href=?]', data_file_path(df), text: /#{df.title}/
      assert_select 'a[href=?]', data_file_path(publishing_df), text: /#{publishing_df.title}/
      assert_select 'a[href=?]', data_file_path(request_publishing_df), text: /#{request_publishing_df.title}/
      assert_select 'a[href=?]', data_file_path(notifying_df), text: /#{notifying_df.title}/
    end
    assert_select '.checkbox', text: /Publish/ do
      assert_select "input[type='checkbox'][id=?]", "publish_DataFile_#{publishing_df.id}"
      assert_select "input[type='checkbox'][id=?]", "publish_DataFile_#{request_publishing_df.id}"
    end
    assert_select 'span.label-warning', text: "Can't publish", count: 1
  end

  test 'get check_gatekeeper_required' do
    gatekeeper = Factory(:asset_gatekeeper)
    df = Factory(:data_file, project_ids: gatekeeper.projects.collect(&:id), contributor: User.current_user)
    model = Factory(:model, project_ids: gatekeeper.projects.collect(&:id), contributor: User.current_user)
    sop = Factory(:sop, contributor: User.current_user)
    assert df.gatekeeper_required?, "This datafile must require gatekeeper's approval for the test to succeed"
    assert model.gatekeeper_required?, "This model must require gatekeeper's approval for the test to succeed"
    assert !sop.gatekeeper_required?, "This sop must not require gatekeeper's approval for the test to succeed"

    params = { publish: {} }
    [df, model, sop].each do |asset|
      params[:publish][asset.class.name] ||= {}
      params[:publish][asset.class.name][asset.id.to_s] = '1'
    end

    get :check_gatekeeper_required, params.merge(id: df.id)
    assert_response :success

    assert_select 'ul#waiting_approval' do
      assert_select 'a[href=?]', data_file_path(df), text: /#{df.title}/, count: 1
      assert_select 'a[href=?]', model_path(model), text: /#{model.title}/, count: 1
      assert_select 'a[href=?]', sop_path(sop), text: /#{sop.title}/, count: 0
      assert_select 'a[href=?]', person_path(gatekeeper), text: /#{gatekeeper.name}/, count: 2
    end

    assert_select 'div[style="display:none;"]' do
      assert_select "input[type='hidden'][value='1'][id=?]", "publish_DataFile_#{df.id}"
      assert_select "input[type='hidden'][value='1'][id=?]", "publish_Model_#{model.id}"
      assert_select "input[type='hidden'][value='1'][id=?]", "publish_Sop_#{sop.id}"
    end
  end

  test 'if the asset has no related items, proceed directly to check_gatekeeper_required' do
    df = data_file_for_publishing
    gatekeeper = Factory(:asset_gatekeeper)
    df.projects << gatekeeper.projects.first
    assert df.can_publish?, 'The data file must be manageable for this test to succeed'

    get :check_related_items, id: df
    assert_response :success
    assert_select 'ul#waiting_approval', count: 1
    assert_nil flash[:error]

    df.reload
    assert !df.is_published?
  end

  test 'if the asset requires no gatekeeper, proceed to confirmation step' do
    df = data_file_for_publishing
    assert df.can_publish?, 'The data file must be manageable for this test to succeed'
    assert !df.is_published?, 'The data file must not be published for this test to be meaningful'
    assert !df.gatekeeper_required?, 'The data file must need require a gatekeeper for this test to proceed'

    get :check_gatekeeper_required, id: df
    assert_response :success
    assert_select 'h1', text: /Confirm publishing/
    assert_nil flash[:error]
  end

  test 'do publish' do
    df = data_file_for_publishing
    assert !df.is_published?, 'The data file must not be already published for this test to succeed'
    assert df.can_publish?, 'The data file must be publishable for this test to succeed'

    params = { publish: {} }
    params[:publish][df.class.name] ||= {}
    params[:publish][df.class.name][df.id.to_s] = '1'

    assert_difference('ResourcePublishLog.count', 1) do
      post :publish, params.merge(id: df.id)
    end

    assert_response :redirect
    assert_nil flash[:error]
    assert_not_nil flash[:notice]

    df.reload
    assert df.is_published?, 'The data file should be published after doing single_publish'
  end

  test "sending publishing request when doing publish for asset that need gatekeeper's approval" do
    df = Factory(:data_file, contributor: User.current_user, project_ids: Factory(:asset_gatekeeper).projects.collect(&:id))
    assert df.can_publish?, 'The data file must be publishable for this test to succeed'
    assert df.gatekeeper_required?, "This datafile must need gatekeeper's approval for the test to succeed'"
    assert !df.is_waiting_approval?(User.current_user), 'The publishing request for this data file must not be sent for this test to succeed'

    params = { publish: {} }
    params[:publish][df.class.name] ||= {}
    params[:publish][df.class.name][df.id.to_s] = '1'

    assert_difference('ResourcePublishLog.count', 1) do
      assert_emails 1 do
        post :publish, params.merge(id: df.id)
      end
    end

    assert_response :redirect
    assert_nil flash[:error]
    assert_not_nil flash[:notice]

    df.reload
    assert !df.is_published?, 'The data file should not be published after sending publishing request'
    assert df.is_waiting_approval?(User.current_user), 'The publishing request for this data file should be sent after requesting'
  end

  test 'do publish together with ISA' do
    df = data_with_isa
    assays = df.assays
    params = { publish: {} }
    non_owned_assets = []
    assays.each do |a|
      assert !a.is_published?, 'This assay should not be public for the test to work'
      assert !a.study.is_published?, 'This assays study should not be public for the test to work'
      assert !a.study.investigation.is_published?, 'This assays investigation should not be public for the test to work'

      params[:publish]['Assay'] ||= {}
      params[:publish]['Assay'][a.id.to_s] = '1'
      params[:publish]['Study'] ||= {}
      params[:publish]['Study'][a.study.id.to_s] = '1'
      params[:publish]['Investigation'] ||= {}
      params[:publish]['Investigation'][a.study.investigation.id.to_s] = '1'

      a.assets.each do |asset|
        assert !asset.is_published?, 'This assays assets should not be public for the test to work'
        params[:publish][asset.class.name] ||= {}
        params[:publish][asset.class.name][asset.id.to_s] = '1'
        non_owned_assets << asset unless asset.can_manage?
      end
    end

    assert !non_owned_assets.empty?, 'There should be non manageable assets included in this test'

    assert_emails 0 do
      post :publish, params.merge(id: df)
    end

    assert_response :redirect

    df.reload

    assert df.is_published?, 'Datafile should now be published'
    df.assays.each do |assay|
      assert assay.is_published?
      assert assay.study.is_published?
      assert assay.study.investigation.is_published?
    end
    non_owned_assets.each { |a| assert !a.is_published?, 'Non manageable assets should not have been published' }
  end

  test 'do publish some' do
    x = group_memberships(:one)
    assert_equal people(:quentin_person), x.person
    refute_nil x.work_group

    person = people(:quentin_person)
    refute person.projects.empty?

    df = data_with_isa

    assays = df.assays

    params = { publish: {} }
    non_publishable_assets = []
    assays.each do |a|
      assert !a.is_published?, 'This assay should not be public for the test to work'
      assert !a.study.is_published?, 'This assays study should not be public for the test to work'
      assert !a.study.investigation.is_published?, 'This assays investigation should not be public for the test to work'

      params[:publish]['Assay'] ||= {}
      params[:publish]['Study'] ||= {}
      params[:publish]['Study'][a.study.id.to_s] = '1'
      params[:publish]['Investigation'] ||= {}

      a.assets.each do |asset|
        assert !asset.is_published?, 'This assays assets should not be public for the test to work'
        params[:publish][asset.class.name] ||= {}
        params[:publish][asset.class.name][asset.id.to_s] = '1' if asset.can_manage?
        non_publishable_assets << asset unless asset.can_publish?
      end
    end

    assert !non_publishable_assets.empty?, 'There should be non publishable assets included in this test'

    assert_emails 0 do
      post :publish, params.merge(id: df)
    end

    assert_response :redirect

    df.reload

    assert df.is_published?, 'Datafile should now be published'
    df.assays.each do |assay|
      assert !assay.is_published?, 'The assay was not requested to be published'
      assert assay.study.is_published?, 'The study should now be published'
      assert !assay.study.investigation.is_published?, 'The investigation was not requested to be published'
    end
    non_publishable_assets.each { |a| assert !a.is_published?, 'Non publishable assets should be filtered out of publish process' }
  end

  test 'get published' do
    df = data_file_for_publishing
    published_items = ["#{df.class.name},#{df.id}"]
    df1 = Factory(:data_file)
    published_items << "#{df1.class.name},#{df1.id}"

    df2 = Factory(:data_file, contributor: User.current_user)
    waiting_for_publish_items = ["#{df2.class.name},#{df2.id}"]

    assert df.can_view?, 'This datafile must be viewable for the test to succeed'
    assert !df1.can_view?, 'This datafile must not be viewable for the test to succeed'
    assert df2.can_view?, 'This datafile must be viewable for the test to succeed'

    get :published, id: df.id, published_items: published_items, waiting_for_publish_items: waiting_for_publish_items
    assert_response :success

    assert_select 'ul#published' do
      assert_select 'li', text: /#{I18n.t('data_file')}: #{df.title}/, count: 1
      assert_select 'li', text: /#{I18n.t('data_file')}: #{df1.title}/, count: 0
    end

    assert_select 'ul#publish_requested' do
      assert_select 'li', text: /#{I18n.t('data_file')}: #{df2.title}/, count: 1
    end

    assert_select 'ul#notified', count: 0
  end

  private

  def data_file_for_publishing(owner = users(:datafile_owner))
    Factory :data_file, contributor: owner, project_ids: [projects(:moses_project).id]
  end

  def data_with_isa
    df = data_file_for_publishing
    other_user = users(:quentin)
    assay = Factory :experimental_assay, contributor: df.contributor.person,
                                         study: Factory(:study, contributor: df.contributor.person,
                                                                investigation: Factory(:investigation, contributor: df.contributor.person))
    other_persons_data_file = Factory :data_file, contributor: other_user, project_ids: other_user.person.projects.collect(&:id), policy: Factory(:policy, access_type: Policy::VISIBLE)
    assay.associate(df)
    assay.associate(other_persons_data_file)
    assert !other_persons_data_file.can_manage?
    df
  end
end
